import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AnswerType, () {
    test('wire names are the snake_case identifiers the agent emits', () {
      expect(AnswerType.textList.wireName, 'text_list');
      expect(AnswerType.longtext.wireName, 'longtext');
    });

    test('every value round-trips through its wire name', () {
      for (final type in AnswerType.values) {
        expect(AnswerType.fromWire(type.wireName), type);
      }
    });

    test('an unknown wire name is a FormatException, not a silent default', () {
      expect(
        () => AnswerType.fromWire('multiple_choice'),
        throwsFormatException,
      );
    });
  });
}
