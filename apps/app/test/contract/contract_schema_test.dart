import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the Dart contract to the JSON Schema the agent emits from its zod
/// source (`packages/contract/contract.schema.json`, regenerated and diffed
/// in CI). A schema change that the Dart side does not mirror fails here, so
/// producer and consumer drift breaks one CI run, not a session on a device.
///
/// Wire names are taken from the real serialization path (`toJson`), never
/// restated by hand, so the pin cannot drift from the code it protects.
void main() {
  final schema = jsonDecode(
    File('../../packages/contract/contract.schema.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  /// One encoded sample per Dart variant, keyed by its wire name.
  final samples = <String, Answer>{
    for (final answer in const <Answer>[
      Answer.color([Color(0xFFFF8800)]),
      Answer.emoji(['😊']),
      Answer.longtext('text'),
      Answer.rating(5),
      Answer.textList(['one']),
    ])
      answer.toJson()['answer_type']! as String: answer,
  };

  group('contract.schema.json', () {
    test('ask_question answer_type enum equals the Dart AnswerType values', () {
      final askQuestion = schema['ask_question'] as Map<String, dynamic>;
      final properties = askQuestion['properties'] as Map<String, dynamic>;
      final answerType = properties['answer_type'] as Map<String, dynamic>;

      expect(
        answerType['enum'],
        unorderedEquals(AnswerType.values.map(_wireNameOf)),
      );
    });

    test('ask_question required keys are all emitted by AskQuestion', () {
      final askQuestion = schema['ask_question'] as Map<String, dynamic>;
      final encoded = const AskQuestion(
        questionId: 'q',
        question: 'Q?',
        answerType: AnswerType.rating,
      ).toJson();

      expect(encoded.keys, containsAll(askQuestion['required'] as List));
    });

    test('record_answer has exactly one variant per Dart Answer variant', () {
      final variants = _answerVariants(schema);

      expect(variants.map((v) => v.wireName), unorderedEquals(samples.keys));
    });

    test('each record_answer variant matches its Dart encoding', () {
      for (final variant in _answerVariants(schema)) {
        final encoded = samples[variant.wireName]!.toJson();

        expect(
          encoded.keys,
          containsAll(variant.required),
          reason: variant.wireName,
        );
        expect(
          encoded['value'],
          _matchesJsonType(variant.valueType),
          reason: '${variant.wireName} value should be ${variant.valueType}',
        );
      }
    });
  });
}

/// The wire name of [type] as `ask_question` actually serializes it.
String _wireNameOf(AnswerType type) =>
    AskQuestion(
          questionId: 'q',
          question: 'Q?',
          answerType: type,
        ).toJson()['answer_type']!
        as String;

typedef _Variant = ({
  String wireName,
  String valueType,
  List<Object?> required,
});

List<_Variant> _answerVariants(Map<String, dynamic> schema) {
  final recordAnswer = schema['record_answer'] as Map<String, dynamic>;
  final properties = recordAnswer['properties'] as Map<String, dynamic>;
  final answer = properties['answer'] as Map<String, dynamic>;
  final oneOf = answer['oneOf'] as List<dynamic>;

  return [
    for (final raw in oneOf.cast<Map<String, dynamic>>())
      () {
        final props = raw['properties'] as Map<String, dynamic>;
        final answerType = props['answer_type'] as Map<String, dynamic>;
        final value = props['value'] as Map<String, dynamic>;
        return (
          wireName: answerType['const'] as String,
          valueType: value['type'] as String,
          required: raw['required'] as List<Object?>,
        );
      }(),
  ];
}

Matcher _matchesJsonType(String jsonType) => switch (jsonType) {
  'array' => isA<List<Object?>>(),
  'string' => isA<String>(),
  'integer' => isA<int>(),
  _ => throw UnsupportedError('unhandled JSON Schema type "$jsonType"'),
};
