import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/text_list_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

void main() {
  group(TextListInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(TextListInput(onSubmit: submitted.call));
      return submitted;
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(TextListInput.fieldKey), text);
      await tester.pump();
    }

    Future<void> tapAdd(WidgetTester tester) async {
      await tester.tap(find.byKey(TextListInput.addKey));
      await tester.pump();
    }

    testWidgets('submit is disabled until something is typed', (tester) async {
      await pumpTestWidget(tester);

      expect(isSubmitEnabled(tester, TextListInput.submitKey), isFalse);

      await type(tester, 'my wife');

      expect(isSubmitEnabled(tester, TextListInput.submitKey), isTrue);
    });

    testWidgets('add turns the typed text into a chip and clears the field', (
      tester,
    ) async {
      await pumpTestWidget(tester);
      await type(tester, ' my wife ');

      await tapAdd(tester);

      expect(find.byKey(TextListInput.itemKey(0)), findsOneWidget);
      expect(find.text('my wife'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(TextListInput.fieldKey))
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('the keyboard action adds the item too', (tester) async {
      await pumpTestWidget(tester);
      await type(tester, 'Flutter');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.byKey(TextListInput.itemKey(0)), findsOneWidget);
    });

    testWidgets('the keyboard action on an empty field adds nothing', (
      tester,
    ) async {
      await pumpTestWidget(tester);
      await type(tester, '  ');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('deleting a chip removes the item', (tester) async {
      await pumpTestWidget(tester);
      await type(tester, 'my wife');
      await tapAdd(tester);
      await type(tester, 'Flutter');
      await tapAdd(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(TextListInput.itemKey(0)),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('my wife'), findsNothing);
    });

    testWidgets('submits the added items plus the pending text', (
      tester,
    ) async {
      final submitted = await pumpTestWidget(tester);
      await type(tester, 'my wife');
      await tapAdd(tester);
      await type(tester, 'myself');
      await tapAdd(tester);
      await type(tester, 'Flutter');

      await tapSubmit(tester, TextListInput.submitKey);

      expect(
        submitted.single,
        const Answer.textList(['my wife', 'myself', 'Flutter']),
      );
    });

    testWidgets('meets accessibility guidelines with items present', (
      tester,
    ) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const TextListInput(onSubmit: ignoreAnswer)),
        prepare: (tester) async {
          await type(tester, 'my wife');
          await tapAdd(tester);
          await type(tester, 'Flutter');
        },
      );
    });
  });
}
