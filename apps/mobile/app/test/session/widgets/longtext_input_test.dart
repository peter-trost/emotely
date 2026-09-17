import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

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

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const LongtextInput(onSubmit: ignoreAnswer)),
      );
    });
  });
}
