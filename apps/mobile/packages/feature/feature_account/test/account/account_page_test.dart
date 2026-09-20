import 'package:feature_account/feature_account.dart';
import 'package:feedback_link/feedback_link.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/testing.dart';

import '../fake_account_navigator.dart';

/// Drives the account screen on its own route, composed the way the app
/// composes it: the utilities and this feature registered over a scripted
/// Supabase, a fake navigator for what the app would do, and the consent
/// bloc handed in from the route below, as the journal hands it.
class _AccountRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
}) {
  final analytics = AnalyticsSpy();
  final navigator = FakeAccountNavigator();

  static const openKey = Key('launcher.open');

  Finder get launcher => find.byKey(openKey);
  Finder get account => find.byType(AccountPage);
  Finder get deleteAccount => find.byKey(AccountView.deleteKey);
  Finder get confirmation => find.byType(AlertDialog);
  Finder get confirm => find.byKey(AccountView.confirmKey);
  Finder get cancel => find.byKey(AccountView.cancelKey);
  Finder get retry => find.byKey(AccountView.retryKey);
  Finder get signOut => find.byKey(AccountView.signOutKey);
  Finder get failure => find.text(AccountView.failureMessage);
  Finder get busy => find.byType(CircularProgressIndicator);
  Finder get withdraw => find.byKey(AccountView.withdrawConsentKey);
  Finder get restore => find.byKey(AccountView.restoreConsentKey);
  Finder get consentRetry => find.byKey(AccountView.consentRetryKey);
  Finder get notice => find.byKey(AccountView.privacyNoticeKey);
  Finder get imprint => find.byKey(AccountView.imprintKey);
  Finder get feedback => find.byKey(AccountView.feedbackKey);

  /// A launcher route that pushes the account screen with the consent bloc
  /// it owns, as the journal does. Reading this composes the container.
  Widget get app {
    registerUtilitiesUnderTest(
      GetIt.I,
      agent: AgentStub(),
      supabase: supabase,
      analytics: analytics,
    );
    registerAccount(GetIt.I);
    GetIt.I.registerSingleton<AccountNavigator>(navigator);
    return pageUnderTest(
      BlocProvider(
        create: (_) => GetIt.I<ConsentBloc>()..add(const ConsentEvent.loaded()),
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: openKey,
                onPressed: () {
                  final consent = context.read<ConsentBloc>();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: consent,
                        child: const AccountPage(),
                      ),
                    ),
                  );
                },
                child: const Text('Account'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Signed in, on the account screen.
  Future<void> launch() async {
    await supabase.signedIn();
    await tester.pumpWidget(app);
    await settle();
    await tap(launcher);
  }

  Future<void> askToDelete() => tap(deleteAccount);

  Future<void> settle() => tester.pumpAndSettle();

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settle();
  }

  Future<void> back() async {
    await tester.pageBack();
    await settle();
  }
}

void main() {
  group(AccountPage, () {
    const deletion = 'POST /rest/v1/rpc/delete_account';
    const logout = 'POST /auth/v1/logout';

    /// The user is gone by the time the SDK tells Supabase about the
    /// sign-out; Supabase refuses, and the SDK treats that as signed out.
    final userGone = authRefused(
      statusCode: 403,
      errorCode: 'user_not_found',
      message: 'User not found',
    );

    _AccountRobot robotWith(
      WidgetTester tester, {
      List<AuthRound> deletions = const [],
      AuthRound? logoutAnswer,
      bool granted = true,
      List<AuthRound> reads = const [],
      List<AuthRound> withdrawals = const [],
    }) {
      final supabase = SupabaseStub()
        ..rest(deletion, deletions)
        ..script(logout: [logoutAnswer ?? userGone])
        ..rest(consentRead, reads)
        ..always(consentRead, consentStands(granted: granted))
        ..rest(consentWithdraw, withdrawals);
      return _AccountRobot(tester, supabase: supabase);
    }

    testWidgets('deletes the account once the loss is confirmed', (
      tester,
    ) async {
      final robot = robotWith(tester, deletions: [rpcReturned(null)]);
      await robot.launch();

      expect(robot.account, findsOneWidget);
      expect(find.text(AccountView.consequenceMessage), findsOneWidget);
      expect(robot.confirmation, findsNothing);

      await robot.askToDelete();

      expect(robot.confirmation, findsOneWidget);
      expect(find.text(AccountView.confirmationMessage), findsOneWidget);
      expect(robot.supabase.to(deletion), isEmpty);

      await robot.tap(robot.confirm);

      expect(robot.supabase.to(deletion), hasLength(1));
      expect(robot.supabase.to(logout), hasLength(1));
      // The route left on its own; the app's root has swapped underneath.
      expect(robot.account, findsNothing);
      expect(robot.launcher, findsOneWidget);
      expect(robot.analytics.events, [event('account_deleted')]);
      expect(robot.analytics.resets, 1);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      final robot = robotWith(tester);
      await robot.launch();
      await robot.askToDelete();

      await robot.tap(robot.cancel);

      expect(robot.confirmation, findsNothing);
      expect(robot.account, findsOneWidget);

      await robot.back();

      expect(robot.launcher, findsOneWidget);
      expect(robot.supabase.to(deletion), isEmpty);
      expect(robot.supabase.to(logout), isEmpty);
      expect(robot.analytics.events, isEmpty);
    });

    testWidgets('shows progress while the account is deleted', (tester) async {
      final robot = robotWith(
        tester,
        deletions: [delayedAuth(rpcReturned(null))],
      );
      await robot.launch();
      await robot.askToDelete();

      await tester.tap(robot.confirm);
      await tester.pump();

      expect(robot.busy, findsOneWidget);
      expect(robot.deleteAccount, findsNothing);

      await robot.settle();

      expect(robot.account, findsNothing);
    });

    testWidgets('cannot be left while the account is being deleted', (
      tester,
    ) async {
      final robot = robotWith(
        tester,
        deletions: [delayedAuth(rpcReturned(null))],
      );
      await robot.launch();
      await robot.askToDelete();

      await tester.tap(robot.confirm);
      await tester.pump();
      // The server is deleting the account whatever happens on this side;
      // leaving now would keep a session for a user who no longer exists.
      await robot.back();

      expect(robot.supabase.to(logout), hasLength(1));
      expect(robot.account, findsNothing);
      expect(robot.analytics.events, [event('account_deleted')]);
      expect(robot.analytics.resets, 1);
    });

    testWidgets('explains when the account cannot be deleted, and retries', (
      tester,
    ) async {
      final robot = robotWith(
        tester,
        deletions: [restRefused(), rpcReturned(null)],
      );
      await robot.launch();
      await robot.askToDelete();

      await robot.tap(robot.confirm);

      expect(robot.account, findsOneWidget);
      expect(robot.failure, findsOneWidget);
      expect(robot.supabase.to(logout), isEmpty);
      // Reported while PostHog still knows who this is: the user is only
      // forgotten once the deletion went through.
      expect(robot.analytics.exceptions, [
        captured(
          withheld(PostgrestApiException, code: 'XX000', statusCode: 409),
          {'step': 'account_deletion'},
        ),
      ]);
      expect(robot.analytics.resets, 0);

      await robot.tap(robot.retry);

      expect(robot.supabase.to(deletion), hasLength(2));
      expect(robot.account, findsNothing);
      expect(robot.analytics.events.last, event('account_deleted'));
      expect(robot.analytics.resets, 1);
    });

    testWidgets('asks the app to sign out when the account cannot be deleted', (
      tester,
    ) async {
      // A deletion that failed on this side may have succeeded on the
      // server; signing out is the way to stop holding a token for a user
      // who may no longer exist — and signing out is the app's to do.
      final robot = robotWith(tester, deletions: [restRefused()]);
      await robot.launch();
      await robot.askToDelete();
      await robot.tap(robot.confirm);

      expect(robot.failure, findsOneWidget);

      await robot.tap(robot.signOut);

      expect(robot.navigator.signOuts, 1);
      expect(robot.account, findsNothing);
      expect(robot.launcher, findsOneWidget);
    });

    testWidgets('leaves even when the sign-out cannot reach the server', (
      tester,
    ) async {
      final robot = robotWith(
        tester,
        deletions: [rpcReturned(null)],
        logoutAnswer: authUnreachable(),
      );
      await robot.launch();
      await robot.askToDelete();

      await robot.tap(robot.confirm);

      expect(robot.account, findsNothing);
      expect(robot.analytics.events.last, event('account_deleted'));
      expect(robot.analytics.resets, 1);
    });

    testWidgets('the rows that leave the app span the whole width', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();

      // Each row is a button the width of the screen, so its highlight runs
      // edge to edge and the label sits 16 in — not a strip inside the page
      // margin that lights up narrower than the finger expects.
      final screen = tester.getRect(
        find.descendant(of: robot.account, matching: find.byType(Scaffold)),
      );
      for (final row in [robot.notice, robot.imprint, robot.feedback]) {
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
        // which the app shows. Once it closes, the account asks the server
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
        // neither button is offered — but never an empty section either.
        expect(robot.withdraw, findsNothing);
        expect(robot.restore, findsNothing);
        expect(find.text(consentUnknownMessage), findsOneWidget);
        expect(robot.deleteAccount, findsOneWidget);

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

    testWidgets('opens a prefilled feedback mail beside the legal links', (
      tester,
    ) async {
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

    testWidgets('meets accessibility guidelines in every state', (
      tester,
    ) async {
      final robot = robotWith(tester, deletions: [restRefused()]);
      await robot.supabase.signedIn();
      // Each pass is a fresh composition, so the container is emptied first.
      Future<Widget> freshApp() async {
        await GetIt.I.reset();
        return KeyedSubtree(key: UniqueKey(), child: robot.app);
      }

      await tester.expectMeetsAccessibilityGuidelines(
        await freshApp(),
        prepare: (tester) => robot.tap(robot.launcher),
      );
      await tester.expectMeetsAccessibilityGuidelines(
        await freshApp(),
        prepare: (tester) async {
          await robot.tap(robot.launcher);
          await robot.askToDelete();
        },
      );
      await tester.expectMeetsAccessibilityGuidelines(
        await freshApp(),
        prepare: (tester) async {
          await robot.tap(robot.launcher);
          await robot.askToDelete();
          await robot.tap(robot.confirm);
        },
      );
    });
  });
}
