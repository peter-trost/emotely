import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/color_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

void main() {
  group(ColorInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(ColorInput(onSubmit: submitted.call));
      return submitted;
    }

    String fieldText(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(ColorInput.fieldKey))
        .controller!
        .text;

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(ColorInput.fieldKey), text);
      await tester.pump();
    }

    testWidgets('offers the whole palette, each announced by name', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      expect(find.byType(IconButton), findsNWidgets(colorPalette.length));
      expect(find.byTooltip('teal'), findsOneWidget);
    });

    testWidgets('submit is disabled until the text holds a color', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      expect(isSubmitEnabled(tester, ColorInput.submitKey), isFalse);

      await type(tester, 'no color yet');

      expect(isSubmitEnabled(tester, ColorInput.submitKey), isFalse);

      await type(tester, 'a #ff8800 day');

      expect(isSubmitEnabled(tester, ColorInput.submitKey), isTrue);
    });

    testWidgets('a palette tap inserts its code at the caret', (tester) async {
      await pumpTestWidget(tester);
      await type(tester, 'today felt ');

      await tester.tap(find.byKey(ColorInput.paletteKey('red')));
      await tester.pump();

      expect(fieldText(tester), 'today felt #E53935 ');
      expect(isSubmitEnabled(tester, ColorInput.submitKey), isTrue);
    });

    testWidgets('submits every color in order of appearance', (tester) async {
      final submitted = await pumpTestWidget(tester);
      await type(tester, 'mostly #00ff00, then #ABCDEF and #12345');

      await tapSubmit(tester, ColorInput.submitKey);

      expect(
        submitted.single,
        const Answer.color([Color(0xFF00FF00), Color(0xFFABCDEF)]),
      );
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const ColorInput(onSubmit: ignoreAnswer)),
        prepare: (tester) => type(tester, 'a #FF8800 day'),
      );
    });
  });
}
