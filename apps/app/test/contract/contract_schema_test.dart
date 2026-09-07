import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

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

  group('advance_session envelope', () {
    Map<String, dynamic> object(Map<String, dynamic> schema) =>
        schema['properties'] as Map<String, dynamic>;
    List<Object?> required(Map<String, dynamic> schema) =>
        schema['required'] as List<Object?>;

    test(
      'request: what AgentClient posts is what the schema describes',
      () async {
        final request =
            schema['advance_session_request'] as Map<String, dynamic>;
        final stub = AgentStub()
          ..script([
            completed(summary: 's', answers: const {'q': Answer.rating(5)}),
          ]);
        await stub.agentClient.advance(
          transcript: AgentStub.transcript,
          signature: AgentStub.signature,
          answer: (toolCallId: 'c1', answer: const Answer.rating(5)),
        );
        final posted = stub.lastRequest;
        final answer = posted['answer']! as Map<String, dynamic>;

        expect(object(request).keys, containsAll(posted.keys));
        final answerSchema = object(request)['answer'] as Map<String, dynamic>;
        expect(object(answerSchema).keys, containsAll(answer.keys));
        expect(answer.keys, containsAll(required(answerSchema)));
      },
    );

    const question = AskQuestion(
      questionId: 'q',
      question: 'Q?',
      answerType: AnswerType.rating,
    );
    const responses = <AdvanceResponse>[
      AdvanceResponse.awaitingAnswer(
        transcript: [],
        signature: 'sig',
        promptId: 'session/v1',
        pending: PendingQuestion(toolCallId: 'c1', question: question),
      ),
      AdvanceResponse.completed(
        transcript: [],
        signature: 'sig',
        promptId: 'session/v1',
        entry: JournalEntry(summary: 's', answers: {'q': Answer.rating(5)}),
      ),
    ];
    final encodedByStatus = <String, Map<String, dynamic>>{
      for (final response in responses)
        response.toJson()['status']! as String: response.toJson(),
    };
    List<Map<String, dynamic>> variants() =>
        ((schema['advance_session_response'] as Map<String, dynamic>)['oneOf']
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    String statusOf(Map<String, dynamic> variant) =>
        (object(variant)['status'] as Map<String, dynamic>)['const'] as String;

    test('response: one variant per Dart AdvanceResponse status', () {
      expect(variants().map(statusOf), unorderedEquals(encodedByStatus.keys));
    });

    test('response: every key the Dart decoder needs is guaranteed', () {
      for (final variant in variants()) {
        final encoded = encodedByStatus[statusOf(variant)]!;
        expect(
          required(variant),
          containsAll(_needed(encoded)),
          reason: statusOf(variant),
        );

        for (final nested in ['pending', 'entry']) {
          final nestedSchema = object(variant)[nested];
          if (nestedSchema == null) {
            continue;
          }
          final nestedEncoded = encoded[nested]! as Map<String, dynamic>;
          expect(
            required(nestedSchema as Map<String, dynamic>),
            containsAll(_needed(nestedEncoded)),
            reason: '${statusOf(variant)}.$nested',
          );
        }
      }
    });
  });
}

/// The keys a freezed `fromJson` cannot do without: everything the Dart side
/// serializes with a value. Nullable fields (encoded as null) are optional.
Iterable<String> _needed(Map<String, dynamic> encoded) =>
    encoded.entries.where((e) => e.value != null).map((e) => e.key);

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
