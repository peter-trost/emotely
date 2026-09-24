import 'dart:ui';

import 'package:contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group(Answer, () {
    const samples = <(Answer, Map<String, dynamic>)>[
      (
        Answer.color([Color(0xFFFF8800), Color(0xFF00AAFF)]),
        {
          'answer_type': 'color',
          'value': ['#FF8800', '#00AAFF'],
        },
      ),
      (
        Answer.emoji(['😊']),
        {
          'answer_type': 'emoji',
          'value': ['😊'],
        },
      ),
      (
        Answer.longtext('A quiet, focused day.'),
        {'answer_type': 'longtext', 'value': 'A quiet, focused day.'},
      ),
      (Answer.rating(7), {'answer_type': 'rating', 'value': 7}),
      (
        Answer.textList(['my wife', 'Flutter']),
        {
          'answer_type': 'text_list',
          'value': ['my wife', 'Flutter'],
        },
      ),
    ];

    test('every variant encodes to the agent wire shape', () {
      for (final (answer, json) in samples) {
        expect(answer.toJson(), json);
      }
    });

    test('every variant decodes from the agent wire shape', () {
      for (final (answer, json) in samples) {
        expect(Answer.fromJson(json), answer);
      }
    });

    test('the samples cover every answer type', () {
      expect(
        samples.map((sample) => sample.$1.answerType),
        unorderedEquals(AnswerType.values),
      );
    });

    test('an unknown answer_type fails to decode', () {
      expect(
        () => Answer.fromJson({'answer_type': 'multiple_choice', 'value': 1}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('wireValue is what the agent receives', () {
      expect(const Answer.rating(7).wireValue, 7);
      expect(const Answer.color([Color(0xFF00AAFF)]).wireValue, ['#00AAFF']);
    });

    test("wireLength counts what the agent's JSON.stringify counts", () {
      // Expected values are Node's `JSON.stringify(value).length`: UTF-16
      // code units of the encoded value, escapes and quotes included.
      expect(const Answer.longtext('a').wireLength, 3);
      expect(const Answer.longtext('é').wireLength, 3);
      expect(const Answer.longtext('😊').wireLength, 4);
      expect(const Answer.longtext('a\nb').wireLength, 6);
      expect(const Answer.longtext('"').wireLength, 4);
      expect(const Answer.textList(['a', 'b']).wireLength, 9);
      expect(const Answer.rating(10).wireLength, 2);
    });

    test('an answer fits up to maxAnswerLength and not a unit beyond', () {
      // Two quotes around the text: 4094 letters encode to exactly 4096.
      expect(Answer.longtext('a' * 4094).fits, isTrue);
      expect(Answer.longtext('a' * 4095).fits, isFalse);
      expect(maxAnswerLength, 4096);
    });

    test('value is the typed widget output', () {
      expect(const Answer.rating(7).value, 7);
      expect(const Answer.color([Color(0xFF00AAFF)]).value, [
        const Color(0xFF00AAFF),
      ]);
    });
  });
}
