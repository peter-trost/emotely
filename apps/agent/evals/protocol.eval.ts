import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MODEL_RATES, sessionCostUsd } from "../src/cost.ts";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { runSession } from "../src/session.ts";
import { modelUnderTest, scriptedClient } from "./harness.ts";
import { fullSessionAnswers } from "./scenarios.ts";

// Deterministic PR gate: a benign full session against the live model must
// uphold the protocol. Judged (fuzzy) behavior lives in behavior.eval.ts.
describe(`protocol eval — ${modelUnderTest}`, () => {
  it("completes a full 10-question session within the cost ceiling", async () => {
    // temperature 0 for stability; one retry absorbs residual variance.
    const attempt = () => {
      const scripted = scriptedClient(fullSessionAnswers);
      return runSession({
        questionSet: defaultQuestionSet,
        client: scripted,
        model: modelUnderTest,
        temperature: 0,
      }).then((session) => ({ result: session, client: scripted }));
    };
    const complete = (candidate: Awaited<ReturnType<typeof attempt>>) =>
      defaultQuestionSet.questions.every(
        (q) =>
          candidate.client.asked.has(q.id) && candidate.result.answers[q.id],
      );
    let run = await attempt();
    if (!complete(run)) {
      console.log("# eval-report protocol retry after incomplete first run");
      run = await attempt();
    }
    const { result, client } = run;

    // Every question asked (no fabricated answers) and answered with the
    // type its question declares.
    for (const q of defaultQuestionSet.questions) {
      assert.ok(client.asked.has(q.id), `question ${q.id} was never asked`);
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
        `tokens=${result.usage.inputTokens}/${result.usage.outputTokens} ` +
        `cached=${result.usage.cacheReadTokens} cost=$${cost.toFixed(5)}`,
    );
    // ponytail: order-of-magnitude ceiling, catches pathology not price drift;
    // tightened in #4 once the benchmark sets a baseline.
    assert.ok(cost < 0.01, `session cost $${cost} exceeded the 1¢ ceiling`);
  });
});
