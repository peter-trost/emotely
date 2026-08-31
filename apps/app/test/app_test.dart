import 'package:emotely/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  group(EmotelyApp, () {
    testWidgets('renders the placeholder shell', (tester) async {
      await tester.pumpWidget(const EmotelyApp());
      expect(find.text('emotely'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines in light theme', (
      tester,
    ) async {
      await tester.expectMeetsAccessibilityGuidelines(const EmotelyApp());
    });
  });
}
