import 'package:contract/contract.dart';

/// Canned questions every package's tests script the agent with — one per
/// answer type the widgets render, plus a second text one for a longer
/// session.

/// A rating question.
const rateQuestion = AskQuestion(
  questionId: 'q-rate',
  question: 'How would you rate your day?',
  answerType: AnswerType.rating,
);

/// A text-list question.
const gratefulQuestion = AskQuestion(
  questionId: 'q-grateful',
  question: 'What are you grateful for?',
  answerType: AnswerType.textList,
);

/// A color question.
const colorsQuestion = AskQuestion(
  questionId: 'q-colors',
  question: 'Which colors were your day?',
  answerType: AnswerType.color,
);

/// A long-text question.
const bestQuestion = AskQuestion(
  questionId: 'q-best',
  question: 'What was the best thing today?',
  answerType: AnswerType.longtext,
);
