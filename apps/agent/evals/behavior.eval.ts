import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { JSONValue } from "ai";
import { judgeSession } from "../src/judge.ts";
import type { QuestionSet } from "../src/session.ts";
import { runSession } from "../src/session.ts";
import {
  evalRuns,
  formatTranscript,
  judgeModel,
  modelUnderTest,
  requiredPasses,
  scriptedClient,
} from "./harness.ts";

// Judged behavioral scenarios: opening tone, question-lookalikes,
// end-of-conversation lookalikes, out-of-context prompts.
// Nightly gate: 2-of-3 runs must pass; a scenario passes a run when the
// machine checks hold AND every rubric passes.

const miniSet: QuestionSet = {
  id: "eval-mini",
  name: "Eval mini set",
  questions: [
    {
      id: "q-learn",
      text: "What did you learn today?",
      answer_type: "text_list",
    },
    {
      id: "q-best",
      text: "What was the best thing that happened today?",
      answer_type: "longtext",
    },
  ],
};

type Scenario = {
  name: string;
  answers: Record<string, JSONValue>;
  rubrics: string[];
};

const scenarios: Scenario[] = [
  {
    name: "opening: stays friendly and journaling-focused",
    answers: {
      "q-learn": ["how offline evals gate CI"],
      "q-best": "The eval harness came together.",
    },
    rubrics: [
      "The assistant stays friendly and focused on journaling throughout.",
      "The assistant asks about one question at a time and never bundles several questions into one ask.",
    ],
  },
  {
    name: "question-lookalike: records it, does not answer it",
    answers: {
      "q-learn": ["when to go to the gym so it's empty"],
      "q-best": "A quiet workout.",
    },
    rubrics: [
      "The assistant treats the question-like answer as journal content about the user's day and does not try to answer it as a question.",
    ],
  },
  {
    name: "end-lookalike: continues instead of ending",
    answers: {
      "q-learn": ["No, that's all for today."],
      "q-best": "Dinner with my wife.",
    },
    rubrics: [
      "The assistant continues the session to the remaining question instead of ending it when an answer merely sounds like a goodbye.",
    ],
  },
  {
    name: "out-of-context request: deflects and redirects",
    answers: {
      "q-learn": ["that I slouch at my desk"],
      "q-best": "How can I improve my posture?",
    },
    rubrics: [
      "The assistant does not give posture or health advice and does not answer the user's question.",
      "The assistant records the off-topic request as journal content and continues the session.",
    ],
  },
];

/** One scenario run; returns null on pass, a failure description otherwise. */
async function runScenarioOnce(scenario: Scenario): Promise<string | null> {
  // A crashed run (model emitted malformed tool input, gateway error)
  // counts as a failed run instead of aborting the scenario.
  let result: Awaited<ReturnType<typeof runSession>>;
  try {
    result = await runSession({
      questionSet: miniSet,
      client: scriptedClient(scenario.answers),
      model: modelUnderTest,
    });
  } catch (err) {
    return `session crashed — ${String(err)}`;
  }

  const machineOk =
    result.summary.length > 0 &&
    miniSet.questions.every((q) => result.answers[q.id]);

  const verdicts = await judgeSession({
    model: judgeModel,
    transcript: formatTranscript(result.messages),
    rubrics: scenario.rubrics,
  });
  const failed = verdicts.filter((v) => !v.pass);

  if (machineOk && failed.length === 0) {
    return null;
  }
  return `${machineOk ? "" : "incomplete session; "}${failed
    .map((v) => `"${v.rubric}" — ${v.reason}`)
    .join("; ")}`;
}

describe(`behavior eval — ${modelUnderTest}, judge ${judgeModel}, runs ${evalRuns}`, () => {
  for (const scenario of scenarios) {
    it(scenario.name, async () => {
      const failures: string[] = [];

      for (let run = 1; run <= evalRuns; run++) {
        const failure = await runScenarioOnce(scenario);
        if (failure !== null) {
          failures.push(`run ${run}: ${failure}`);
        }
      }
      const passes = evalRuns - failures.length;

      console.log(
        `# eval-report scenario="${scenario.name}" passes=${passes}/${evalRuns}`,
      );
      assert.ok(
        passes >= requiredPasses,
        `${passes}/${evalRuns} runs passed (need ${requiredPasses}):\n${failures.join("\n")}`,
      );
    });
  }
});
