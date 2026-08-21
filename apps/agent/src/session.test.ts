import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { AskQuestionInput } from "@emotely/contract";
import { MockLanguageModelV4 } from "ai/test";
import type { QuestionSet, SessionClient } from "./session.ts";
import { runSession } from "./session.ts";
import { PROMPT_ID } from "./session-prompt.ts";

const set: QuestionSet = {
  id: "test-set",
  name: "Test set",
  questions: [
    {
      id: "q-rate",
      text: "How would you rate your day?",
      answer_type: "rating",
    },
    {
      id: "q-grateful",
      text: "What are you grateful for?",
      answer_type: "text_list",
      min_answers: 3,
    },
  ],
};

type MockContent =
  | { type: "text"; text: string }
  | { type: "tool-call"; toolCallId: string; toolName: string; input: string };

// Scripted model: each doGenerate call shifts the next response off the queue.
function scriptedModel(script: MockContent[][]) {
  const queue = [...script];
  return new MockLanguageModelV4({
    doGenerate: async () => {
      const content = queue.shift();
      if (!content) throw new Error("mock model script exhausted");
      const isToolCall = content.some((c) => c.type === "tool-call");
      return {
        content,
        finishReason: {
          unified: isToolCall ? ("tool-calls" as const) : ("stop" as const),
          raw: undefined,
        },
        usage: {
          inputTokens: {
            total: 1,
            noCache: 1,
            cacheRead: undefined,
            cacheWrite: undefined,
          },
          outputTokens: { total: 1, text: 1, reasoning: undefined },
        },
        warnings: [],
      };
    },
  });
}

const ask = (id: string, q: (typeof set.questions)[number]): MockContent => ({
  type: "tool-call",
  toolCallId: id,
  toolName: "ask_question",
  input: JSON.stringify({
    question_id: q.id,
    question: q.text,
    answer_type: q.answer_type,
  }),
});

const record = (
  id: string,
  questionId: string,
  answerType: string,
  value: unknown,
): MockContent => ({
  type: "tool-call",
  toolCallId: id,
  toolName: "record_answer",
  input: JSON.stringify({
    question_id: questionId,
    answer: { answer_type: answerType, value },
  }),
});

const complete = (id: string, summary: string): MockContent => ({
  type: "tool-call",
  toolCallId: id,
  toolName: "complete_session",
  input: JSON.stringify({ summary }),
});

describe("runSession", () => {
  it("rejects an answer below min_answers back to the model without storing it", async () => {
    const model = scriptedModel([
      [ask("c1", set.questions[1]!)],
      [record("c2", "q-grateful", "text_list", ["just one", "and two"])],
      [complete("c3", "Gave up after the rejection.")],
      [{ type: "text", text: "Done." }],
    ]);
    const client: SessionClient = {
      askQuestion: async () => ["just one", "and two"],
    };

    const result = await runSession({ questionSet: set, client, model });

    assert.equal(result.answers["q-grateful"], undefined);
  });

  it("halts with an error when the model never calls complete_session", async () => {
    // Model that asks the same question forever.
    const model = new MockLanguageModelV4({
      doGenerate: async () => ({
        content: [ask("loop", set.questions[0]!)],
        finishReason: { unified: "tool-calls" as const, raw: undefined },
        usage: {
          inputTokens: {
            total: 1,
            noCache: 1,
            cacheRead: undefined,
            cacheWrite: undefined,
          },
          outputTokens: { total: 1, text: 1, reasoning: undefined },
        },
        warnings: [],
      }),
    });
    const client: SessionClient = { askQuestion: async () => 5 };

    await assert.rejects(
      runSession({ questionSet: set, client, model }),
      /round limit/,
    );
  });

  it("a repeated record_answer for the same question overwrites (last write wins)", async () => {
    const model = scriptedModel([
      [ask("c1", set.questions[0]!)],
      [record("c2", "q-rate", "rating", 3)],
      [record("c3", "q-rate", "rating", 8)],
      [complete("c4", "Corrected the rating.")],
      [{ type: "text", text: "Done." }],
    ]);
    const client: SessionClient = { askQuestion: async () => 3 };

    const result = await runSession({ questionSet: set, client, model });

    assert.deepEqual(result.answers["q-rate"], {
      answer_type: "rating",
      value: 8,
    });
  });

  it("walks the set in order and completes with a summary and validated answers", async () => {
    const model = scriptedModel([
      [ask("c1", set.questions[0]!)],
      [record("c2", "q-rate", "rating", 7)],
      [ask("c3", set.questions[1]!)],
      [
        record("c4", "q-grateful", "text_list", [
          "my wife",
          "myself",
          "Flutter",
        ]),
      ],
      [complete("c5", "A good day: rated 7, grateful for three things.")],
    ]);

    const asked: AskQuestionInput[] = [];
    const client: SessionClient = {
      askQuestion: async (input) => {
        asked.push(input);
        return input.answer_type === "rating"
          ? 7
          : ["my wife", "myself", "Flutter"];
      },
    };

    const result = await runSession({ questionSet: set, client, model });

    assert.deepEqual(
      asked.map((a) => a.question_id),
      ["q-rate", "q-grateful"],
    );
    assert.equal(
      result.summary,
      "A good day: rated 7, grateful for three things.",
    );
    assert.deepEqual(result.answers, {
      "q-rate": { answer_type: "rating", value: 7 },
      "q-grateful": {
        answer_type: "text_list",
        value: ["my wife", "myself", "Flutter"],
      },
    });
    // 5 model rounds (ask, record, ask, record, complete) at 1+1 mock tokens
    assert.deepEqual(result.usage, { inputTokens: 5, outputTokens: 5 });
    // Full conversation is exposed for eval judging: initial user message,
    // model tool calls, and the client's tool results all present.
    assert.equal(result.messages[0]?.role, "user");
    const roles = result.messages.map((m) => m.role);
    assert.ok(roles.includes("assistant"));
    assert.ok(roles.includes("tool"));
    // Evals and PostHog events pin against the versioned prompt id.
    assert.equal(result.promptId, PROMPT_ID);
  });
});
