import 'package:contract/contract.dart';
import 'package:feature_session/src/widgets/answer_length.dart';
import 'package:feature_session/src/widgets/longtext_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testing/testing.dart';

void main() {
  group(LongtextInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(LongtextInput(onSubmit: submitted.call));
      return submitted;
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(LongtextInput.fieldKey), text);
      await tester.pump();
    }

    testWidgets('submit is disabled until there is text', (tester) async {
      await pumpTestWidget(tester);

      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isFalse);

      await type(tester, 'A quiet day.');

      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isTrue);
    });

    testWidgets('whitespace alone does not count as text', (tester) async {
      await pumpTestWidget(tester);

      await type(tester, '   \n');

      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isFalse);
    });

    testWidgets('submits the trimmed text', (tester) async {
      final submitted = await pumpTestWidget(tester);
      await type(tester, '  A quiet, focused day.\n');

      await tapSubmit(tester, LongtextInput.submitKey);

      expect(submitted.single, const Answer.longtext('A quiet, focused day.'));
    });

    testWidgets('an answer too long for the agent cannot be submitted, and '
        'says by how much', (tester) async {
      await pumpTestWidget(tester);

      // 4095 letters and their two quotes: one past the limit.
      await type(tester, 'a' * 4095);

      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isFalse);
      expect(find.text(AnswerLength.over(1)), findsOneWidget);

      await type(tester, 'a' * 4094);

      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isTrue);
      expect(find.text(AnswerLength.left(0)), findsOneWidget);
    });

    testWidgets('counts down only once the answer nears the limit', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      await type(tester, 'A quiet day.');

      expect(find.byKey(AnswerLength.noteKey), findsNothing);

      // 3900 letters and their two quotes: 194 short of the limit.
      await type(tester, 'a' * 3900);

      expect(find.text(AnswerLength.left(194)), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const LongtextInput(onSubmit: ignoreAnswer)),
      );
    });

    testWidgets('meets accessibility guidelines over the limit', (
      tester,
    ) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const LongtextInput(onSubmit: ignoreAnswer)),
        prepare: (tester) => type(tester, 'a' * 4095),
      );
    });
  });
}
