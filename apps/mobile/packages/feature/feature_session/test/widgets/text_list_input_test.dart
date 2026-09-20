import 'package:contract/contract.dart';
import 'package:feature_session/src/widgets/text_list_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:testing/testing.dart';

void main() {
  group(TextListInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(TextListInput(onSubmit: submitted.call));
      return submitted;
    }

    Future<void> type(WidgetTester tester, int index, String text) async {
      await tester.enterText(find.byKey(TextListInput.fieldKey(index)), text);
      await tester.pump();
    }

    final fields = find.byType(TextField);

    testWidgets('starts with one empty field and submit disabled', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      expect(fields, findsOneWidget);
      expect(isSubmitEnabled(tester, TextListInput.submitKey), isFalse);
    });

    testWidgets('writing in the last field opens another one below it', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      await type(tester, 0, 'my wife');

      expect(fields, findsNWidgets(2));
      expect(isSubmitEnabled(tester, TextListInput.submitKey), isTrue);

      await type(tester, 1, 'Flutter');

      expect(fields, findsNWidgets(3));
    });

    testWidgets('submits every filled field, trimmed, in order', (
      tester,
    ) async {
      final submitted = await pumpTestWidget(tester);
      await type(tester, 0, ' my wife ');
      await type(tester, 1, 'Flutter');

      await tapSubmit(tester, TextListInput.submitKey);

      expect(submitted.single, const Answer.textList(['my wife', 'Flutter']));
    });

    testWidgets('a field emptied and left behind closes', (tester) async {
      await pumpTestWidget(tester);
      await type(tester, 0, 'my wife');
      await type(tester, 1, 'Flutter');

      await type(tester, 0, '');
      // Still open while the caret is in it: emptying is not yet leaving.
      expect(fields, findsNWidgets(3));

      await tester.tap(find.byKey(TextListInput.fieldKey(2)));
      await tester.pump();

      expect(fields, findsNWidgets(2));
      expect(
        tester
            .widget<TextField>(find.byKey(TextListInput.fieldKey(0)))
            .controller
            ?.text,
        'Flutter',
      );
    });

    testWidgets('the keyboard action moves on to the next field', (
      tester,
    ) async {
      await pumpTestWidget(tester);
      await type(tester, 0, 'my wife');

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byKey(TextListInput.fieldKey(1)))
            .focusNode
            ?.hasFocus,
        isTrue,
      );
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const TextListInput(onSubmit: ignoreAnswer)),
        prepare: (tester) => type(tester, 0, 'my wife'),
      );
    });
  });
}
