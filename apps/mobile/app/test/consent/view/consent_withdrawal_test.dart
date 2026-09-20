import 'package:feature_account/feature_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';
import '../consent_robot.dart';

/// Taking consent back, and giving it again, from the account screen.
/// Art. 7 (3): withdrawal must be as easy as giving, and it must never
/// require deleting the account.
void main() {
  group('withdrawing consent', () {
    const journalViewed = {'entries': 0, 'open_session': false};
    const version = {'version': consentVersion};
    const deletion = 'POST /rest/v1/rpc/delete_account';

    ConsentRobot robotWith(
      WidgetTester tester, {
      bool granted = true,
      List<AuthRound> withdrawals = const [],
      List<AuthRound> grants = const [],
      List<AuthRound> reads = const [],
    }) {
      final supabase = SupabaseStub()
        ..rest(consentRead, reads)
        ..always(consentRead, consentStands(granted: granted))
        ..rest(consentWithdraw, withdrawals)
        ..rest(consentGrant, grants);
      final agent = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: rateQuestion)]);
      return ConsentRobot(tester, supabase: supabase, agent: agent);
    }

    /// From the journal into the account screen.
    Future<void> openAccount(ConsentRobot robot) async {
      await robot.launch();
      await robot.tap(robot.openAccount);
    }

    testWidgets('is one tap, and does not touch the account or the entries', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await openAccount(robot);

      expect(robot.withdraw, findsOneWidget);
      expect(find.text(withdrawConsentExplanation), findsOneWidget);

      await robot.tap(robot.withdraw);

      expect(robot.supabase.to(consentWithdraw), hasLength(1));
      expect(robot.supabase.bodies('/rest/v1/rpc/withdraw_consent'), [
        {'version': consentVersion},
      ]);
      // The account is untouched: withdrawing is not deleting.
      expect(robot.supabase.to(deletion), isEmpty);
      expect(robot.account, findsOneWidget);
      expect(find.text(consentMissingExplanation), findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_withdrawn', version),
      ]);
    });

    testWidgets('stops the next session without deleting anything', (
      tester,
    ) async {
      // The server answers "stands" at launch and "does not" from the
      // withdrawal on, which is what it would really do.
      final robot = robotWith(tester, granted: false, reads: [consentStands()]);
      await openAccount(robot);
      await robot.tap(robot.withdraw);

      await robot.back();

      // Back on the journal, Start now asks again rather than sending.
      expect(robot.home, findsOneWidget);
      await robot.startSession();

      expect(robot.consent, findsOneWidget);
      expect(robot.session, findsNothing);
    });

    testWidgets('can be given again, through the same question', (
      tester,
    ) async {
      final robot = robotWith(tester, granted: false, reads: [consentStands()]);
      await openAccount(robot);
      await robot.tap(robot.withdraw);

      expect(robot.restore, findsOneWidget);

      await robot.tap(robot.restore);

      // Not a one-tap re-grant: the second consent is the same four
      // paragraphs and the same unticked box as the first. Art. 7 (3) makes
      // withdrawal as easy as giving, not giving easier the second time.
      expect(robot.consent, findsOneWidget);
      expect(robot.supabase.to(consentGrant), isEmpty);
      expect(tester.widget<CheckboxListTile>(robot.checkbox).value, isFalse);

      await robot.consentAndContinue();

      expect(robot.supabase.to(consentGrant), hasLength(1));
      expect(find.text(withdrawConsentExplanation), findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_withdrawn', version),
        event('consent_granted', version),
      ]);
    });

    testWidgets(
      'a withdrawal that fails leaves consent standing, and says so',
      (tester) async {
        final robot = robotWith(tester, withdrawals: [restRefused()]);
        await openAccount(robot);

        await robot.tap(robot.withdraw);

        // The server still has the consent, so the screen must not pretend
        // otherwise; it offers the same act again.
        expect(robot.withdrawFailure, findsOneWidget);
        expect(
          robot.analytics.events,
          isNot(contains(event('consent_withdrawn', version))),
        );

        await robot.tap(robot.withdraw);

        expect(robot.supabase.to(consentWithdraw), hasLength(2));
        expect(find.text(consentMissingExplanation), findsOneWidget);
      },
    );

    testWidgets('says so, and retries, when the answer cannot be read', (
      tester,
    ) async {
      final robot = robotWith(tester, reads: [restRefused()]);
      await openAccount(robot);

      // A read that failed says nothing about whether consent stands, so
      // neither button is offered — but the section must not simply be
      // empty: someone who came here to withdraw would find nothing and no
      // reason why, which is the one thing Art. 7 (3) cannot tolerate.
      expect(robot.withdraw, findsNothing);
      expect(robot.restore, findsNothing);
      expect(find.text(consentUnknownMessage), findsOneWidget);
      // The rest of the screen still works.
      expect(find.byKey(AccountView.deleteKey), findsOneWidget);
      expect(robot.accountNotice, findsOneWidget);

      await robot.tap(find.byKey(AccountView.consentRetryKey));

      // Looking again brings the control back.
      expect(robot.withdraw, findsOneWidget);
      expect(find.text(consentUnknownMessage), findsNothing);
    });

    testWidgets('the notice is reachable before an account exists', (
      tester,
    ) async {
      // Play expects the policy to be findable without signing in; this is
      // the first screen anyone sees, so the link lives here too.
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await tester.pumpWidget(robot.app);
      await robot.settle();

      expect(robot.signIn, findsOneWidget);
      await robot.tap(robot.signInNotice);

      expect(launcher.launched, [privacyNoticeUrl]);
    });

    testWidgets('the account screen links the notice and the imprint', (
      tester,
    ) async {
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await openAccount(robot);

      await robot.tap(robot.accountNotice);
      await robot.tap(robot.accountImprint);

      expect(launcher.launched, [privacyNoticeUrl, imprintUrl]);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final robot = robotWith(tester);
      await robot.supabase.signedIn();

      await tester.expectMeetsAccessibilityGuidelines(
        robot.app,
        prepare: (tester) async {
          await robot.settle();
          await robot.tap(robot.openAccount);
          await tester.ensureVisible(find.byKey(AccountView.deleteKey));
          await robot.settle();
        },
      );
    });
  });
}
