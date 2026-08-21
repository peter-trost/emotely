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
      "learned-today": ["how the eval harness works"],
      "best-thing": "Shipped the offline eval gate.",
      "day-colors": ["#00FF88"],
      "mood-emojis": ["🔥", "😌"],
      productivity: 8,
      satisfaction: 9,
      appreciation: 7,
      "gratitude-list": ["my wife", "green CI", "cheap models"],
      "goal-alignment": 8,
      "gratitude-person": "My wife supported the late debugging.",
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
