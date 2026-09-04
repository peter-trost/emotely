import 'package:emotely/contract/answer_type.dart';
import 'package:meta/meta.dart';

/// An `ask_question` tool call: the agent wants one answer of [answerType].
@immutable
class AskQuestion {
  /// Creates an ask_question payload.
  const AskQuestion({
    required this.questionId,
    required this.question,
    required this.answerType,
  });

  /// Decodes the tool-call input as the agent emits it.
  factory AskQuestion.fromJson(Map<String, dynamic> json) => AskQuestion(
    questionId: json['question_id'] as String,
    question: json['question'] as String,
    answerType: AnswerType.fromWire(json['answer_type'] as String),
  );

  /// Stable id of the question within its question set.
  final String questionId;

  /// The question text to show the user.
  final String question;

  /// Which widget to render.
  final AnswerType answerType;

  /// Encodes to the tool-call input shape.
  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question': question,
    'answer_type': answerType.wireName,
  };

  /// Copies with the given fields replaced.
  AskQuestion copyWith({
    String? questionId,
    String? question,
    AnswerType? answerType,
  }) => AskQuestion(
    questionId: questionId ?? this.questionId,
    question: question ?? this.question,
    answerType: answerType ?? this.answerType,
  );

  @override
  bool operator ==(Object other) =>
      other is AskQuestion &&
      other.questionId == questionId &&
      other.question == question &&
      other.answerType == answerType;

  @override
  int get hashCode => Object.hash(questionId, question, answerType);

  @override
  String toString() =>
      'AskQuestion($questionId, ${answerType.wireName}: $question)';
}
