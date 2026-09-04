import 'package:emotely/contract/answer_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer.freezed.dart';
part 'answer.g.dart';

/// A validated answer, typed per [AnswerType] — the `answer` object of the
/// agent's `record_answer` tool call, and what each answer widget produces.
///
/// The client posts only the value back as the `ask_question` tool result; the
/// full object comes back in the completed entry.
@Freezed(unionKey: 'answer_type')
sealed class Answer with _$Answer {
  /// One or more `#RRGGBB` colors.
  const factory Answer.color(List<String> value) = ColorAnswer;

  /// One or more emoji.
  const factory Answer.emoji(List<String> value) = EmojiAnswer;

  /// A single free-text paragraph.
  const factory Answer.longtext(String value) = LongtextAnswer;

  /// An integer from 1 to 10.
  const factory Answer.rating(int value) = RatingAnswer;

  /// One or more short text items.
  @FreezedUnionValue('text_list')
  const factory Answer.textList(List<String> value) = TextListAnswer;

  const Answer._();

  /// Decodes a `record_answer` answer object.
  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);

  /// The answer type this variant carries.
  AnswerType get answerType => switch (this) {
    ColorAnswer() => AnswerType.color,
    EmojiAnswer() => AnswerType.emoji,
    LongtextAnswer() => AnswerType.longtext,
    RatingAnswer() => AnswerType.rating,
    TextListAnswer() => AnswerType.textList,
  };
}
