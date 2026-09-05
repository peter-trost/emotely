import 'package:emotely/contract/answer_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ask_question.freezed.dart';
part 'ask_question.g.dart';

/// An `ask_question` tool call: the agent wants one answer of the given type.
@freezed
abstract class AskQuestion with _$AskQuestion {
  /// Creates an ask_question payload.
  const factory({
    /// Stable id of the question within its question set.
    required String questionId,

    /// The question text to show the user.
    required String question,

    /// Which widget to render.
    required AnswerType answerType,
  }) = _AskQuestion;

  /// Decodes the tool-call input as the agent emits it.
  factory fromJson(Map<String, dynamic> json) => _$AskQuestionFromJson(json);
}
