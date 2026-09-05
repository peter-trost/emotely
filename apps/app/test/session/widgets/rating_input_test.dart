import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/rating_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

void main() {
  group(RatingInput, () {
    Future<Submitted> pumpTestWidget(WidgetTester tester) async {
      final submitted = Submitted();
      await tester.pumpApp(RatingInput(onSubmit: submitted.call));
      return submitted;
    }

    Future<void> pick(WidgetTester tester, int value) async {
      await tester.tap(find.byKey(RatingInput.chipKey(value)));
      await tester.pump();
    }

    testWidgets('offers exactly the values 1 to 10', (tester) async {
      await pumpTestWidget(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(10));
      expect(find.byKey(RatingInput.chipKey(1)), findsOneWidget);
      expect(find.byKey(RatingInput.chipKey(10)), findsOneWidget);
    });

    testWidgets('submit is disabled until a value is picked', (tester) async {
      await pumpTestWidget(tester);

      expect(isSubmitEnabled(tester, RatingInput.submitKey), isFalse);

      await pick(tester, 7);

      expect(isSubmitEnabled(tester, RatingInput.submitKey), isTrue);
    });

    testWidgets('submits the last picked value', (tester) async {
      final submitted = await pumpTestWidget(tester);
      await pick(tester, 7);
      await pick(tester, 3);

      await tapSubmit(tester, RatingInput.submitKey);

      expect(submitted.single, const Answer.rating(3));
      expect(
        tester.widget<ChoiceChip>(find.byKey(RatingInput.chipKey(3))).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(RatingInput.chipKey(7))).selected,
        isFalse,
      );
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.expectMeetsAccessibilityGuidelines(
        appWrapper(const RatingInput(onSubmit: ignoreAnswer)),
        prepare: (tester) => pick(tester, 8),
      );
    });
  });
}
