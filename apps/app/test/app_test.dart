import 'package:emotely/app/app.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  group(EmotelyApp, () {
    testWidgets('opens on sign-in when nobody is signed in', (tester) async {
      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub(),
          supabase: SupabaseStub(),
          analytics: AnalyticsSpy(),
        ),
      );

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(SessionPage), findsNothing);
    });

    testWidgets('opens straight into a session for a restored sign-in', (
      tester,
    ) async {
      final supabase = SupabaseStub();
      await supabase.signedIn();
      final analytics = AnalyticsSpy();

      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub()..script([unreachable()]),
          supabase: supabase,
          analytics: analytics,
        ),
      );

      expect(find.byType(SessionPage), findsOneWidget);
      expect(find.text('Journaling session'), findsOneWidget);
      // The restored user is known to PostHog before anything else happens.
      expect(analytics.identified, [SupabaseStub.userId]);
    });
  });
}
