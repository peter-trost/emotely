/// The widget the agent asks the client to render for a question.
///
/// Mirrors `answerTypes` in `packages/contract`; the wire names are pinned
/// against the generated JSON Schema in `test/contract/contract_schema_test`.
enum AnswerType {
  /// One or more `#RRGGBB` colors.
  color('color'),

  /// One or more emoji.
  emoji('emoji'),

  /// A single free-text paragraph.
  longtext('longtext'),

  /// An integer from 1 to 10.
  rating('rating'),

  /// One or more short text items.
  textList('text_list');

  const AnswerType(this.wireName);

  /// The snake_case identifier the agent emits.
  final String wireName;

  /// Resolves a wire name; an unknown one is a [FormatException] so a new
  /// server-side answer type can never fall through to a wrong widget.
  static AnswerType fromWire(String wireName) => values.firstWhere(
    (type) => type.wireName == wireName,
    orElse: () => throw FormatException('unknown answer_type', wireName),
  );
}
