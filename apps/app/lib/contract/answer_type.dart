import 'package:json_annotation/json_annotation.dart';

/// The widget the agent asks the client to render for a question.
///
/// Mirrors `answerTypes` in `packages/contract`; the snake_case wire names
/// are pinned against the generated JSON Schema in
/// `test/contract/contract_schema_test`.
@JsonEnum(fieldRename: FieldRename.snake)
enum AnswerType() {
  /// One or more `#RRGGBB` colors.
  color,

  /// One or more emoji.
  emoji,

  /// A single free-text paragraph.
  longtext,

  /// An integer from 1 to 10.
  rating,

  /// One or more short text items.
  textList;

  /// Values carry no state; the constructor exists for the primary
  /// constructor lint.
  this;
}
