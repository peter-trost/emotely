import 'package:emotely/account/view/account_page.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:emotely/consent/view/consent_page.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/helpers.dart';

/// Drives the consent gate through the real app against a scripted Supabase:
/// from the journal into the consent screen, through the box and the button,
/// and into (or away from) a session.
class ConsentRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
  required final AgentStub agent,
}) {
  final analytics = AnalyticsSpy();

  Finder get home => find.byType(JournalPage);
  Finder get signIn => find.byType(SignInPage);
  Finder get signInNotice => find.byKey(SignInPage.privacyNoticeKey);
  Finder get consent => find.byType(ConsentPage);
  Finder get session => find.byType(SessionPage);
  Finder get account => find.byType(AccountPage);

  Finder get start => find.byKey(JournalView.startKey);
  Finder get continueSession => find.byKey(JournalView.continueKey);
  Finder get openAccount => find.byKey(JournalView.accountKey);

  Finder get checkbox => find.byKey(ConsentView.checkboxKey);
  Finder get agree => find.byKey(ConsentView.agreeKey);
  Finder get decline => find.byKey(ConsentView.declineKey);
  Finder get notice => find.byKey(ConsentView.noticeKey);
  Finder get retry => find.byKey(ConsentView.retryKey);
  Finder get consentFailure => find.text(consentFailureMessage);
  Finder get declined => find.text(consentDeclinedMessage);

  Finder get withdraw => find.byKey(AccountView.withdrawConsentKey);
  Finder get restore => find.byKey(AccountView.restoreConsentKey);
  Finder get accountNotice => find.byKey(AccountView.privacyNoticeKey);
  Finder get accountImprint => find.byKey(AccountView.imprintKey);
  Finder get withdrawFailure => find.text(withdrawFailureMessage);

  Widget get app =>
      appUnderTest(agent: agent, supabase: supabase, analytics: analytics);

  /// Launches the app signed in and lets the journal load.
  Future<void> launch() async {
    await supabase.signedIn();
    await tester.pumpWidget(app);
    await settle();
  }

  /// Taps Start a session, which is what puts the gate in the way.
  Future<void> startSession() => tap(start);

  /// The affirmative act: tick the box, then press the button.
  Future<void> consentAndContinue() async {
    await tap(checkbox);
    await tap(agree);
  }

  Future<void> settle() => tester.pumpAndSettle();

  /// Taps [finder], scrolling it into view first. The consent screen says
  /// more than fits a test viewport — deliberately, since it has to be read
  /// — so every control on it needs scrolling to before it can be tapped.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await settle();
    await tester.tap(finder);
    await settle();
  }

  Future<void> back() async {
    await tester.pageBack();
    await settle();
  }
}

/// The endpoints the consent gate uses, named once. The state is derived on
/// the server from the append-only history, so the app asks one question
/// (`consent_stands`) and never walks the events itself.
const consentRead = 'POST /rest/v1/rpc/consent_stands';
const consentGrant = 'POST /rest/v1/rpc/record_consent';
const consentWithdraw = 'POST /rest/v1/rpc/withdraw_consent';

/// What the server answers when consent stands, or does not.
AuthRound consentStands({bool granted = true}) => rpcReturned(granted);
