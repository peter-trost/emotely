import type { QuestionSet } from "./session.ts";

// The legacy app's built-in set ("Legacy Reflections"); question texts
// carried over, ids renamed to readable slugs (fresh backend, no migration).
export const defaultQuestionSet: QuestionSet = {
  id: "legacy-reflections",
  name: "Legacy Reflections",
  questions: [
    {
      id: "learned-today",
      text: "What did you learn today?",
      answer_type: "text_list",
    },
    {
      id: "best-thing",
      text: "What was the best thing that happened today?",
      answer_type: "longtext",
    },
    {
      id: "day-colors",
      text: "Which color(s) best describe your day?",
      answer_type: "color",
    },
    {
      id: "mood-emojis",
      text: "Which emojis describe your mood during different parts of your day?",
      answer_type: "emoji",
    },
    {
      id: "productivity",
      text: "How productive did you feel today?",
      answer_type: "rating",
    },
    {
      id: "satisfaction",
      text: "How satisfied are you with your day?",
      answer_type: "rating",
    },
    {
      id: "appreciation",
      text: "How much appreciation did you feel for the small victories or moments in your life today?",
      answer_type: "rating",
    },
    {
      id: "gratitude-list",
      text: "List down at least 3 things that you're grateful for today.",
      answer_type: "text_list",
      min_answers: 3,
    },
    {
      id: "goal-alignment",
      text: "How well did your actions today align with the goals you want to achieve?",
      answer_type: "rating",
    },
    {
      id: "gratitude-person",
      text: "Share about someone you're grateful for today and how they positively impact your life.",
      answer_type: "longtext",
    },
  ],
};
