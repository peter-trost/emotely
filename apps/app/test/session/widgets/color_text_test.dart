import 'package:emotely/session/widgets/color_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

void main() {
  group(ColorText, () {
    testWidgets('renders text without color codes as is', (tester) async {
      const text = 'This is a sample text without color codes.';
      await tester.pumpApp(const ColorText(text));

      expect(find.text(text, findRichText: true), findsOneWidget);
      expect(find.byType(ColorBox), findsNothing);
    });

    testWidgets('replaces each valid color code with a box', (tester) async {
      await tester.pumpApp(
        const ColorText('Text #FF5733 with #GGHHII and #00AAFF.'),
      );

      expect(find.byType(ColorBox), findsNWidgets(2));
      expect(
        tester.widgetList<ColorBox>(find.byType(ColorBox)).map((b) => b.color),
        [const Color(0xFFFF5733), const Color(0xFF00AAFF)],
      );
    });

    testWidgets('announces the full text including codes', (tester) async {
      const text = 'Text #FF5733 with #GGHHII and plain text.';
      await tester.pumpApp(const ColorText(text));

      expect(find.bySemanticsLabel(text), findsOneWidget);
    });

    testWidgets('applies the given text style', (tester) async {
      const style = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      await tester.pumpApp(const ColorText('A #FF5733 day.', style: style));

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.style?.fontSize, 20);
      expect(richText.text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const ColorText('A #FF5733 and #00AAFF day.')),
      );
    });
  });
}
