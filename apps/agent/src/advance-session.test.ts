import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { QuestionSet } from "./session.ts";
import { advanceSession } from "./session-core.ts";
import { scriptedSessionModel } from "./test-helpers.ts";

const set: QuestionSet = {
  id: "s",
  name: "s",
  questions: [
    { id: "q-rate", text: "Rate your day?", answer_type: "rating" },
    { id: "q-best", text: "Best thing?", answer_type: "longtext" },
  ],
};

describe("advanceSession", () => {
  it("starts a session: runs to the first question and pauses", async () => {
    const model = scriptedSessionModel([
      {
        ask: {
          questionId: "q-rate",
          question: "Rate your day?",
          answerType: "rating",
        },
      },
    ]);
    const result = await advanceSession({
      questionSet: set,
      model,
      messages: [],
    });

    assert.equal(result.status, "awaiting_answer");
    if (result.status !== "awaiting_answer") {
      return;
    }
    assert.equal(result.pending.input.question_id, "q-rate");
    assert.ok(result.messages.length > 0);
  });

  it("consumes the answer, records, and pauses at the next question", async () => {
    const start = await advanceSession({
      questionSet: set,
      model: scriptedSessionModel([
        {
          ask: {
            questionId: "q-rate",
            question: "Rate your day?",
            answerType: "rating",
          },
        },
      ]),
      messages: [],
    });
    assert.equal(start.status, "awaiting_answer");
    if (start.status !== "awaiting_answer") {
      return;
    }

    const next = await advanceSession({
      questionSet: set,
      model: scriptedSessionModel([
        { record: { questionId: "q-rate", answerType: "rating", value: 7 } },
        {
          ask: {
            questionId: "q-best",
            question: "Best thing?",
            answerType: "longtext",
          },
        },
      ]),
      messages: start.messages,
      answer: { toolCallId: start.pending.toolCallId, value: 7 },
    });

    assert.equal(next.status, "awaiting_answer");
    if (next.status !== "awaiting_answer") {
      return;
    }
    assert.equal(next.pending.input.question_id, "q-best");
  });

  it("returns the journal entry when the model completes", async () => {
    const start = await advanceSession({
      questionSet: set,
      model: scriptedSessionModel([
        {
          ask: {
            questionId: "q-rate",
            question: "Rate your day?",
            answerType: "rating",
          },
        },
      ]),
      messages: [],
    });
    if (start.status !== "awaiting_answer") {
      assert.fail("expected pending question");
    }

    const done = await advanceSession({
      questionSet: set,
      model: scriptedSessionModel([
        { record: { questionId: "q-rate", answerType: "rating", value: 7 } },
        {
          record: {
            questionId: "q-best",
            answerType: "longtext",
            value: "n/a",
          },
        },
        { complete: "Rated 7." },
      ]),
      messages: start.messages,
      answer: { toolCallId: start.pending.toolCallId, value: 7 },
    });

    assert.equal(done.status, "completed");
    if (done.status !== "completed") {
      return;
    }
    assert.equal(done.entry.summary, "Rated 7.");
    assert.deepEqual(done.entry.answers["q-rate"], {
      answer_type: "rating",
      value: 7,
    });
  });
});
