import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/emoji_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

void main() {
  group(EmojiInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(EmojiInput(onSubmit: submitted.call));
      return submitted;
    }

    Future<void> toggle(WidgetTester tester, String emoji) async {
      await tester.tap(find.byKey(EmojiInput.chipKey(emoji)));
      await tester.pump();
    }

    testWidgets('offers the whole palette, each announced by name', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      expect(find.byType(FilterChip), findsNWidgets(emojiPalette.length));
      expect(find.bySemanticsLabel('grateful'), findsOneWidget);
    });

    testWidgets('submit is disabled until an emoji is picked', (tester) async {
      await pumpTestWidget(tester);

      expect(isSubmitEnabled(tester, EmojiInput.submitKey), isFalse);

      await toggle(tester, '😊');

      expect(isSubmitEnabled(tester, EmojiInput.submitKey), isTrue);
    });

    testWidgets('picking again deselects', (tester) async {
      await pumpTestWidget(tester);
      await toggle(tester, '😊');

      await toggle(tester, '😊');

      expect(isSubmitEnabled(tester, EmojiInput.submitKey), isFalse);
    });

    testWidgets('submits the picked emoji in palette order', (tester) async {
      final submitted = await pumpTestWidget(tester);
      await toggle(tester, '😢');
      await toggle(tester, '😊');

      await tapSubmit(tester, EmojiInput.submitKey);

      expect(submitted.single, const Answer.emoji(['😊', '😢']));
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const EmojiInput(onSubmit: ignoreAnswer)),
        prepare: (tester) => toggle(tester, '🙏'),
      );
    });
  });
}
