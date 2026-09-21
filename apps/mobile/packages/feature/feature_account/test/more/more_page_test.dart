import 'package:feature_account/feature_account.dart';
import 'package:feedback_link/feedback_link.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testing/testing.dart';

import '../fake_account_navigator.dart';

/// Drives the More tab on its own, composed the way the app composes it:
/// the utilities and this feature registered over a scripted Supabase, the
/// consent bloc handed in from the route as the app hands it, and a fake
/// navigator for what the app would do.
class _MoreRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
}) {
  final analytics = AnalyticsSpy();
  final navigator = FakeAccountNavigator();

  Finder get more => find.byType(MorePage);
  Finder get account => find.byKey(MoreView.accountKey);
  Finder get withdraw => find.byKey(MoreView.withdrawConsentKey);
  Finder get restore => find.byKey(MoreView.restoreConsentKey);
  Finder get consentRetry => find.byKey(MoreView.consentRetryKey);
  Finder get notice => find.byKey(MoreView.privacyNoticeKey);
  Finder get imprint => find.byKey(MoreView.imprintKey);
  Finder get feedback => find.byKey(MoreView.feedbackKey);
  Finder get signOut => find.byKey(MoreView.signOutKey);
  Finder get busy => find.byType(CircularProgressIndicator);

  Finder heading(String title) => find.text(title);

  /// Reading this composes the container, so read it once per test.
  Widget get app {
    registerUtilitiesUnderTest(
      GetIt.I,
      agent: AgentStub(),
      supabase: supabase,
      analytics: analytics,
    );
    registerAccount(GetIt.I);
    GetIt.I.registerSingleton<AccountNavigator>(navigator);
    return featureUnderTest(
      routes: [$moreRoute],
      initialLocation: const MoreRoute().location,
    );
  }

  Future<void> launch() async {
    await supabase.signedIn();
    await tester.pumpWidget(app);
    await settle();
  }

  /// A viewport tall enough for the whole list, for the tests that measure
  /// where its rows sit: a scrolled list has no single answer to that.
  void showEverything() {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> settle() => tester.pumpAndSettle();

  /// Taps [finder], scrolling it into view first: the list is longer than
  /// a test viewport.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await settle();
    await tester.tap(finder);
    await settle();
  }
}

void main() {
  group(MorePage, () {
    _MoreRobot robotWith(
      WidgetTester tester, {
      bool granted = true,
      List<AuthRound> reads = const [],
      List<AuthRound> withdrawals = const [],
    }) {
      final supabase = SupabaseStub()
        ..rest(consentRead, reads)
        ..always(consentRead, consentStands(granted: granted))
        ..rest(consentWithdraw, withdrawals);
      return _MoreRobot(tester, supabase: supabase);
    }

    testWidgets('lists its sections in order, and sign out last', (
      tester,
    ) async {
      final robot = robotWith(tester)..showEverything();
      await robot.launch();

      final headings = [
        MoreView.accountSection,
        MoreView.consentSection,
        MoreView.legalSection,
        MoreView.feedbackSection,
      ];
      for (final title in headings) {
        expect(robot.heading(title), findsOneWidget);
      }
      final rows = [
        robot.heading(MoreView.accountSection),
        robot.account,
        robot.heading(MoreView.consentSection),
        robot.withdraw,
        robot.heading(MoreView.legalSection),
        robot.notice,
        robot.imprint,
        robot.heading(MoreView.feedbackSection),
        robot.feedback,
        robot.signOut,
      ];
      for (var i = 0; i + 1 < rows.length; i++) {
        expect(
          tester.getTopLeft(rows[i]).dy,
          lessThan(tester.getTopLeft(rows[i + 1]).dy),
          reason: 'row $i sits above row ${i + 1}',
        );
      }
    });

    testWidgets('sets the sections apart by more than a row', (tester) async {
      final robot = robotWith(tester)..showEverything();
      await robot.launch();

      // The gap from the last row of one section to the next heading is
      // what tells the sections apart at a glance; a row-to-row gap is
      // none at all.
      final gap =
          tester.getTopLeft(robot.heading(MoreView.consentSection)).dy -
          tester.getBottomLeft(robot.account).dy;
      expect(gap, greaterThanOrEqualTo(MoreView.sectionGap));
      final beforeSignOut =
          tester.getTopLeft(robot.signOut).dy -
          tester.getBottomLeft(robot.feedback).dy;
      expect(beforeSignOut, greaterThanOrEqualTo(MoreView.sectionGap));
      expect(
        tester.getTopLeft(robot.imprint).dy,
        tester.getBottomLeft(robot.notice).dy,
      );
    });

    testWidgets('opens the account screen on its own route, and comes back', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.account);

      expect(find.byType(AccountPage), findsOneWidget);
      expect(robot.more, findsNothing);

      await tester.pageBack();
      await robot.settle();

      expect(robot.more, findsOneWidget);
      expect(find.byType(AccountPage), findsNothing);
    });

    testWidgets('signs out through the app', (tester) async {
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.signOut);

      expect(robot.navigator.signOuts, 1);
    });

    testWidgets('the rows span the whole width', (tester) async {
      final robot = robotWith(tester);
      await robot.launch();

      // Each row is a button the width of the screen, so its highlight runs
      // edge to edge and the label sits 16 in — not a strip inside the page
      // margin that lights up narrower than the finger expects.
      final screen = tester.getRect(
        find.descendant(of: robot.more, matching: find.byType(Scaffold)),
      );
      for (final row in [robot.account, robot.notice, robot.feedback]) {
        final rect = tester.getRect(row);
        expect(rect.left, screen.left);
        expect(rect.width, screen.width);
      }
      expect(
        tester.getRect(find.text(privacyNoticeLabel)).left,
        screen.left + 16,
      );
    });

    group('consent', () {
      const version = {'version': testConsentVersion};

      testWidgets('is withdrawn in one tap, and can be given again', (
        tester,
      ) async {
        final robot = robotWith(tester, withdrawals: [rpcReturned(null)]);
        await robot.launch();

        expect(find.text(withdrawConsentExplanation), findsOneWidget);

        await robot.tap(robot.withdraw);

        expect(robot.supabase.bodies('/rest/v1/rpc/withdraw_consent'), [
          version,
        ]);
        expect(find.text(consentMissingExplanation), findsOneWidget);
        expect(robot.analytics.events, [event('consent_withdrawn', version)]);

        // Not a one-tap re-grant: the way back is the consent screen itself,
        // which the app shows. Once it closes, the row asks the server
        // again rather than trusting what it showed before — and the server
        // here says consent stands.
        await robot.tap(robot.restore);

        expect(robot.navigator.consentRequests, 1);
        expect(find.text(withdrawConsentExplanation), findsOneWidget);
      });

      testWidgets('shows progress while a withdrawal is written', (
        tester,
      ) async {
        final robot = robotWith(
          tester,
          withdrawals: [delayedAuth(rpcReturned(null))],
        );
        await robot.launch();

        await tester.tap(robot.withdraw);
        await tester.pump();

        expect(robot.busy, findsOneWidget);
        expect(find.text(MoreView.consentBusyLabel), findsOneWidget);

        await robot.settle();

        expect(find.text(consentMissingExplanation), findsOneWidget);
      });

      testWidgets(
        'a withdrawal that fails leaves consent standing, and says so',
        (tester) async {
          final robot = robotWith(
            tester,
            withdrawals: [restRefused(), rpcReturned(null)],
          );
          await robot.launch();

          await robot.tap(robot.withdraw);

          expect(find.text(withdrawFailureMessage), findsOneWidget);
          expect(robot.analytics.events, isEmpty);

          await robot.tap(robot.withdraw);

          expect(robot.supabase.to(consentWithdraw), hasLength(2));
          expect(find.text(consentMissingExplanation), findsOneWidget);
        },
      );

      testWidgets('says so, and retries, when the answer cannot be read', (
        tester,
      ) async {
        final robot = robotWith(tester, reads: [restRefused()]);
        await robot.launch();

        // A read that failed says nothing about whether consent stands, so
        // neither row is offered — but never an empty section either.
        expect(robot.withdraw, findsNothing);
        expect(robot.restore, findsNothing);
        expect(find.text(consentUnknownMessage), findsOneWidget);
        expect(robot.account, findsOneWidget);

        await robot.tap(robot.consentRetry);

        expect(robot.withdraw, findsOneWidget);
        expect(find.text(consentUnknownMessage), findsNothing);
      });
    });

    testWidgets('links the privacy notice and the imprint', (tester) async {
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.notice);
      await robot.tap(robot.imprint);

      expect(launcher.launched, [privacyNoticeUrl, imprintUrl]);
    });

    testWidgets('opens a prefilled feedback mail', (tester) async {
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.feedback);

      final mail = Uri.parse(launcher.launched.single);
      expect(mail.scheme, 'mailto');
      expect(mail.path, feedbackAddress);
      expect(
        mail.queryParameters['subject'],
        allOf(
          contains(testBuildInfo.versionAndBuild),
          contains(testBuildInfo.platform),
        ),
      );
    });

    testWidgets('reports a device with no mail app, and says nothing', (
      tester,
    ) async {
      UrlLauncherSpy.setup().fails = true;
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.feedback);

      // The screen is unchanged: there is nothing useful to say, and the
      // beta's one feedback channel dead-ending is ours to notice, not the
      // user's to work around.
      expect(robot.feedback, findsOneWidget);
      expect(robot.analytics.exceptions, [
        captured(withheld(PlatformException), {'step': 'feedback_mail'}),
      ]);
    });

    testWidgets('tells the mail nothing about the user or their journal', (
      tester,
    ) async {
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.feedback);

      // The signed-in user's id and address are what this screen holds and
      // the mail must not carry; the mail itself already says who sent it.
      final user = robot.supabase.supabase.auth.currentUser!;
      expect(launcher.launched.single, isNot(contains(user.id)));
      expect(launcher.launched.single, isNot(contains(user.email)));
    });

    testWidgets('meets accessibility guidelines with consent standing and '
        'gone', (tester) async {
      final standing = robotWith(tester);
      await standing.supabase.signedIn();
      await tester.expectMeetsAccessibilityGuidelines(standing.app);

      await GetIt.I.reset();
      final gone = robotWith(tester, granted: false);
      await gone.supabase.signedIn();
      await tester.expectMeetsAccessibilityGuidelines(
        KeyedSubtree(key: UniqueKey(), child: gone.app),
      );
    });
  });
}
