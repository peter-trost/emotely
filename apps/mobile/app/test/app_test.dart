import 'package:emotely/app/app.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_journal/feature_journal.dart';
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
      // The startup gate reads the config before anything renders (#49).
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(JournalPage), findsNothing);
    });

    testWidgets('opens straight into the journal for a restored sign-in', (
      tester,
    ) async {
      final supabase = SupabaseStub();
      await supabase.signedIn();
      final analytics = AnalyticsSpy();

      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub(),
          supabase: supabase,
          analytics: analytics,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JournalPage), findsOneWidget);
      expect(find.text('Your journal'), findsOneWidget);
      // The restored user is known to PostHog before anything else happens.
      expect(analytics.identified, [SupabaseStub.userId]);
    });
    testWidgets('signs out from the journal and returns to sign-in', (
      tester,
    ) async {
      // The journal asks the app to sign out; the app tells the auth bloc,
      // and the root swaps the screen underneath.
      final supabase = SupabaseStub()..script(logout: [signedOut()]);
      await supabase.signedIn();
      final analytics = AnalyticsSpy();

      await tester.pumpWidget(
        appUnderTest(
          agent: AgentStub(),
          supabase: supabase,
          analytics: analytics,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(JournalView.signOutKey));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(JournalPage), findsNothing);
      expect(analytics.events.last, event('signed_out'));
    });
  });
}
