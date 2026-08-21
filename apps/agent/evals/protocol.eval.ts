import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MODEL_RATES, sessionCostUsd } from "../src/cost.ts";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { runSession } from "../src/session.ts";
import { modelUnderTest, scriptedClient } from "./harness.ts";

// Deterministic PR gate: a benign full session against the live model must
// uphold the protocol. Judged (fuzzy) behavior lives in behavior.eval.ts.
describe(`protocol eval — ${modelUnderTest}`, () => {
  it("completes a full 10-question session within the cost ceiling", async () => {
    const answers = {
      "15CjDQMbgiupVv4EGKWh": ["how the eval harness works"],
      CpUKaQcSH9u4La8Y2lBM: "Shipped the offline eval gate.",
      I3QkqSeXmGSX47IAlih4: ["#00FF88"],
      N5dhXuRDmJ6DRRGDxcuB: ["🔥", "😌"],
      NUy0Q6sAiHQjteaSyjz4: 8,
      O3ewi4LNh8RHoFo45Je3: 9,
      V7N4ipTxlaqxXlRHEAUE: 7,
      ZP1r3kAnMd9XZ1rU1sem: ["my wife", "green CI", "cheap models"],
      f3GVndW7IGrd8qb3icvf: 8,
      g3xpuKYjz9aljHZhHkOu: "My wife supported the late debugging.",
    };

    // temperature 0 for stability; one retry absorbs residual variance.
    let result = await runSession({
      questionSet: defaultQuestionSet,
      client: scriptedClient(answers),
      model: modelUnderTest,
      temperature: 0,
    });
    if (defaultQuestionSet.questions.some((q) => !result.answers[q.id])) {
      console.log("# eval-report protocol retry after incomplete first run");
      result = await runSession({
        questionSet: defaultQuestionSet,
        client: scriptedClient(answers),
        model: modelUnderTest,
        temperature: 0,
      });
    }

    // Every question answered with the type its question declares.
    for (const q of defaultQuestionSet.questions) {
      const recorded = result.answers[q.id];
      assert.ok(recorded, `question ${q.id} has no recorded answer`);
      assert.equal(recorded.answer_type, q.answer_type);
      if (q.min_answers) {
        assert.ok(
          Array.isArray(recorded.value) &&
            recorded.value.length >= q.min_answers,
          `question ${q.id} needs at least ${q.min_answers} answers`,
        );
      }
    }
    assert.ok(result.summary.length > 0);

    const rates = MODEL_RATES[modelUnderTest];
    assert.ok(rates, `no rates for ${modelUnderTest} — add to MODEL_RATES`);
    const cost = sessionCostUsd([result.usage], rates);
    console.log(
      `# eval-report model=${modelUnderTest} prompt=${result.promptId} ` +
        `tokens=${result.usage.inputTokens}/${result.usage.outputTokens} cost=$${cost.toFixed(5)}`,
    );
    // ponytail: order-of-magnitude ceiling, catches pathology not price drift;
    // tightened in #4 once the benchmark sets a baseline.
    assert.ok(cost < 0.01, `session cost $${cost} exceeded the 1¢ ceiling`);
  });
});
