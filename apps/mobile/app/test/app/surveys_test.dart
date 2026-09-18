import 'package:emotely/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../helpers/helpers.dart';

void main() {
  group(EmotelyApp, () {
    testWidgets('mounts the survey host above the app', (tester) async {
      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub(),
          supabase: SupabaseStub(),
          analytics: AnalyticsSpy(),
        ),
      );
      await tester.pumpAndSettle();

      // Without this wrapper the SDK has nowhere to draw a popover survey.
      expect(find.byType(PostHogWidget), findsOneWidget);
    });

    testWidgets('gives the SDK the navigator it needs to find a context', (
      tester,
    ) async {
      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub(),
          supabase: SupabaseStub(),
          analytics: AnalyticsSpy(),
        ),
      );
      await tester.pumpAndSettle();

      // The observer is what `PosthogObserver.currentContext` reads; without
      // it the SDK logs "Cannot show survey: No valid context found".
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.navigatorObservers?.whereType<PosthogObserver>(),
        hasLength(1),
      );
    });
  });
}
