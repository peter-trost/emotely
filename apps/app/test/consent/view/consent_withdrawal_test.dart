import 'package:emotely/account/view/account_page.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';
import '../../session/session_robot.dart';
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
      List<Map<String, Object?>>? consents,
      List<AuthRound> withdrawals = const [],
      List<AuthRound> grants = const [],
      List<AuthRound> reads = const [],
    }) {
      final supabase = SupabaseStub()
        ..rest(
          consentRead,
          reads.isEmpty
              ? [
                  rows(consents ?? [consentRow()]),
                ]
              : reads,
        )
        ..rest(consentWithdraw, withdrawals)
        ..rest(consentGrant, grants);
      final agent = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: SessionRobot.rate)]);
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
      expect(find.text(consentWithdrawnExplanation), findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_withdrawn', version),
      ]);
    });

    testWidgets('stops the next session without deleting anything', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await openAccount(robot);
      await robot.tap(robot.withdraw);

      await robot.back();

      // Back on the journal, Start now asks again rather than sending.
      expect(robot.home, findsOneWidget);
      await robot.startSession();

      expect(robot.consent, findsOneWidget);
      expect(robot.session, findsNothing);
    });

    testWidgets('can be given again from the same screen', (tester) async {
      final robot = robotWith(tester);
      await openAccount(robot);
      await robot.tap(robot.withdraw);

      expect(robot.restore, findsOneWidget);

      await robot.tap(robot.restore);

      expect(robot.supabase.to(consentGrant), hasLength(1));
      expect(find.text(withdrawConsentExplanation), findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_withdrawn', version),
        event('consent_granted', version),
      ]);

      await robot.back();
      await robot.startSession();

      // Consent stands again, so the session runs without another question.
      expect(robot.consent, findsNothing);
      expect(robot.session, findsOneWidget);
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
        expect(find.text(consentWithdrawnExplanation), findsOneWidget);
      },
    );

    testWidgets('offers no consent control while the answer is unknown', (
      tester,
    ) async {
      final robot = robotWith(tester, reads: [restRefused()]);
      await openAccount(robot);

      // A read that failed says nothing about whether consent stands, so
      // the screen offers neither button rather than one that might do
      // nothing. Deleting the account is still available.
      expect(robot.withdraw, findsNothing);
      expect(robot.restore, findsNothing);
      expect(find.byKey(AccountView.deleteKey), findsOneWidget);
      expect(robot.accountNotice, findsOneWidget);
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
