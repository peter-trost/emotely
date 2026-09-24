import type { AnswerType } from "@emotely/contract";
import { MockLanguageModelV4 } from "ai/test";

type ScriptStep =
  | { ask: { questionId: string; question: string; answerType: AnswerType } }
  | { record: { questionId: string; answerType: AnswerType; value: unknown } }
  | { complete: string };

function stepContent(step: ScriptStep | undefined, nextId: () => string) {
  if (step === undefined) {
    return [{ type: "text" as const, text: "Done." }];
  }
  if ("ask" in step) {
    return [
      {
        type: "tool-call" as const,
        toolCallId: nextId(),
        toolName: "ask_question",
        input: JSON.stringify({
          question_id: step.ask.questionId,
          question: step.ask.question,
          answer_type: step.ask.answerType,
        }),
      },
    ];
  }
  if ("record" in step) {
    return [
      {
        type: "tool-call" as const,
        toolCallId: nextId(),
        toolName: "record_answer",
        input: JSON.stringify({
          question_id: step.record.questionId,
          answer: {
            answer_type: step.record.answerType,
            value: step.record.value,
          },
        }),
      },
    ];
  }
  return [
    {
      type: "tool-call" as const,
      toolCallId: nextId(),
      toolName: "complete_session",
      input: JSON.stringify({ summary: step.complete }),
    },
  ];
}

/** Mock model that emits one scripted tool call per round, then final text. */
export function scriptedSessionModel(steps: ScriptStep[]): MockLanguageModelV4 {
  const queue: ScriptStep[] = [...steps];
  let callId = 0;
  return new MockLanguageModelV4({
    doGenerate: async () => {
      const step = queue.shift();
      const content = stepContent(step, () => `c${++callId}`);
      const isToolCall = content.some((c) => c.type === "tool-call");
      return {
        content,
        finishReason: {
          unified: isToolCall ? ("tool-calls" as const) : ("stop" as const),
          raw: undefined,
        },
        usage: {
          inputTokens: {
            total: 7,
            noCache: 7,
            cacheRead: undefined,
            cacheWrite: undefined,
          },
          outputTokens: { total: 3, text: 3, reasoning: undefined },
        },
        warnings: [],
      };
    },
  });
}

/**
 * [value] as it comes back out of a Postgres `jsonb` column, which is where
 * the app keeps an unfinished session (ADR 0010). `jsonb` "does not preserve
 * the order of object keys" (PostgreSQL docs, § 8.14 JSON Types): it stores
 * them shortest first, then bytewise. Every other value survives unchanged.
 */
export function storedAsJsonb(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(storedAsJsonb);
  }
  if (value === null || typeof value !== "object") {
    return value;
  }
  const keys = Object.keys(value).sort((a, b) =>
    a.length === b.length
      ? Buffer.compare(Buffer.from(a), Buffer.from(b))
      : a.length - b.length,
  );
  return Object.fromEntries(
    keys.map((key) => [
      key,
      storedAsJsonb((value as Record<string, unknown>)[key]),
    ]),
  );
}
