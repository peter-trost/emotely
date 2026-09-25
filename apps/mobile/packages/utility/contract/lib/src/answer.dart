import 'dart:convert';
import 'dart:ui';

import 'package:contract/src/answer_limit.dart';
import 'package:contract/src/answer_type.dart';
import 'package:contract/src/hex_color_converter.dart';
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
  /// One or more colors (`#RRGGBB` on the wire).
  const factory color(@HexColorConverter() List<Color> value) = ColorAnswer;

  /// One or more emoji.
  const factory emoji(List<String> value) = EmojiAnswer;

  /// A single free-text paragraph.
  const factory longtext(String value) = LongtextAnswer;

  /// An integer from 1 to 10.
  const factory rating(int value) = RatingAnswer;

  /// One or more short text items.
  const factory textList(List<String> value) = TextListAnswer;

  /// Decodes a `record_answer` answer object.
  factory fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
}

/// Behavior on [Answer] lives here so editing it never needs regeneration.
extension AnswerX on Answer {
  /// The value as the agent expects it on the wire — `#RRGGBB` strings for
  /// colors, not Dart objects. This, never [value], is what gets posted.
  Object? get wireValue => toJson()['value'];

  /// How long the agent measures this answer to be: [wireValue] encoded as
  /// JSON, in UTF-16 code units. Dart's `jsonEncode` escapes exactly what
  /// JavaScript's `JSON.stringify` does, so the two lengths agree.
  int get wireLength => jsonEncode(wireValue).length;

  /// Whether the agent accepts an answer this long ([maxAnswerLength]).
  bool get fits => wireLength <= maxAnswerLength;

  /// The answer type this variant carries.
  AnswerType get answerType => switch (this) {
    ColorAnswer() => AnswerType.color,
    EmojiAnswer() => AnswerType.emoji,
    LongtextAnswer() => AnswerType.longtext,
    RatingAnswer() => AnswerType.rating,
    TextListAnswer() => AnswerType.textList,
  };
}
