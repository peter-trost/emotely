import type { QuestionSet } from "./session.ts";

// The legacy app's built-in set ("Legacy Reflections"), English texts and ids
// carried over from emotely-legacy's legacyQuestionSet.
export const defaultQuestionSet: QuestionSet = {
  id: "KT9cr1mEoilCTNC6o3mK",
  name: "Legacy Reflections",
  questions: [
    {
      id: "15CjDQMbgiupVv4EGKWh",
      text: "What did you learn today?",
      answer_type: "text_list",
    },
    {
      id: "CpUKaQcSH9u4La8Y2lBM",
      text: "What was the best thing that happened today?",
      answer_type: "longtext",
    },
    {
      id: "I3QkqSeXmGSX47IAlih4",
      text: "Which color(s) best describe your day?",
      answer_type: "color",
    },
    {
      id: "N5dhXuRDmJ6DRRGDxcuB",
      text: "Which emojis describe your mood during different parts of your day?",
      answer_type: "emoji",
    },
    {
      id: "NUy0Q6sAiHQjteaSyjz4",
      text: "How productive did you feel today?",
      answer_type: "rating",
    },
    {
      id: "O3ewi4LNh8RHoFo45Je3",
      text: "How satisfied are you with your day?",
      answer_type: "rating",
    },
    {
      id: "V7N4ipTxlaqxXlRHEAUE",
      text: "How much appreciation did you feel for the small victories or moments in your life today?",
      answer_type: "rating",
    },
    {
      id: "ZP1r3kAnMd9XZ1rU1sem",
      text: "List down at least 3 things that you're grateful for today.",
      answer_type: "text_list",
      min_answers: 3,
    },
    {
      id: "f3GVndW7IGrd8qb3icvf",
      text: "How well did your actions today align with the goals you want to achieve?",
      answer_type: "rating",
    },
    {
      id: "g3xpuKYjz9aljHZhHkOu",
      text: "Share about someone you're grateful for today and how they positively impact your life.",
      answer_type: "longtext",
    },
  ],
};
