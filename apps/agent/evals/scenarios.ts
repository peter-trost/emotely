import type { JSONValue } from "ai";
import type { QuestionSet } from "../src/session.ts";

/** Benign answers for the default 10-question set (protocol eval + benchmark). */
export const fullSessionAnswers: Record<string, JSONValue> = {
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

// Judged behavioral scenarios: opening tone, question-lookalikes,
// end-of-conversation lookalikes, out-of-context prompts. Shared by the
// nightly behavior eval and the model benchmark.

export const miniSet: QuestionSet = {
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

export type Scenario = {
  name: string;
  answers: Record<string, JSONValue>;
  rubrics: string[];
};

export const scenarios: Scenario[] = [
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
      "After the goodbye-sounding answer to the first question, the assistant still asks the remaining question of the set before calling complete_session, instead of ending the session early.",
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
