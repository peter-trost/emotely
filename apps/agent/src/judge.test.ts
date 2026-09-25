import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MockLanguageModelV4 } from "ai/test";
import { judgeSession } from "./judge.ts";

const verdictJson = JSON.stringify({
  verdicts: [
    { rubric: "greets the user by name", pass: true, reason: "Greets Peter." },
    {
      rubric: "asks only about the current question",
      pass: false,
      reason: "Drifted into unrelated advice.",
    },
  ],
});

const replyingWith = (text: string) =>
  new MockLanguageModelV4({
    doGenerate: async () => ({
      content: [{ type: "text" as const, text }],
      finishReason: { unified: "stop" as const, raw: undefined },
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

const rubrics = [
  "greets the user by name",
  "asks only about the current question",
];

describe("judgeSession", () => {
  it("returns one validated verdict per rubric from a single model call", async () => {
    const verdicts = await judgeSession({
      model: replyingWith(verdictJson),
      transcript: "assistant: Hi Peter! ...",
      rubrics,
    });

    assert.equal(verdicts.length, 2);
    assert.deepEqual(
      verdicts.map((v) => v.pass),
      [true, false],
    );
    assert.equal(verdicts[1]?.reason, "Drifted into unrelated advice.");
  });

  it("rejects a reply that does not match the verdict schema", async () => {
    const malformed = JSON.stringify({
      verdicts: [{ rubric: "x", pass: "yes" }],
    });
    await assert.rejects(
      judgeSession({
        model: replyingWith(malformed),
        transcript: "assistant: Hi Peter! ...",
        rubrics,
      }),
    );
  });
});
