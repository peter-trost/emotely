import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/answer_input.dart';
import 'package:emotely/session/widgets/color_input.dart';
import 'package:emotely/session/widgets/emoji_input.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:emotely/session/widgets/rating_input.dart';
import 'package:emotely/session/widgets/text_list_input.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group(AnswerInput, () {
    const widgetFor = <AnswerType, Type>{
      AnswerType.color: ColorInput,
      AnswerType.emoji: EmojiInput,
      AnswerType.longtext: LongtextInput,
      AnswerType.rating: RatingInput,
      AnswerType.textList: TextListInput,
    };

    test('every answer type has a widget', () {
      expect(widgetFor.keys, unorderedEquals(AnswerType.values));
    });

    for (final MapEntry(key: type, value: widget) in widgetFor.entries) {
      testWidgets('renders $widget for ${type.name}', (tester) async {
        await tester.pumpApp(
          AnswerInput(
            question: AskQuestion(
              questionId: 'q',
              question: 'Q?',
              answerType: type,
            ),
            onSubmit: ignoreAnswer,
          ),
        );

        expect(find.byType(widget), findsOneWidget);
      });
    }
  });
}
