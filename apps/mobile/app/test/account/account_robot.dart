import 'package:feature_account/feature_account.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_journal/feature_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/helpers.dart';

/// Drives the account screen through the real app against a scripted
/// Supabase: from the journal to the screen, through the confirmation, and
/// back out to sign-in once the account is gone.
class AccountRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
  required final AgentStub agent,
}) {
  final analytics = AnalyticsSpy();

  Finder get home => find.byType(JournalPage);
  Finder get account => find.byType(AccountPage);
  Finder get signIn => find.byType(SignInPage);
  Finder get openAccount => find.byKey(JournalView.accountKey);
  Finder get deleteAccount => find.byKey(AccountView.deleteKey);
  Finder get confirmation => find.byType(AlertDialog);
  Finder get confirm => find.byKey(AccountView.confirmKey);
  Finder get cancel => find.byKey(AccountView.cancelKey);
  Finder get retry => find.byKey(AccountView.retryKey);
  Finder get signOut => find.byKey(AccountView.signOutKey);
  Finder get failure => find.text(AccountView.failureMessage);
  Finder get busy => find.byType(CircularProgressIndicator);

  Widget get app =>
      appUnderTest(agent: agent, supabase: supabase, analytics: analytics);

  /// Launches the app signed in and opens the account screen.
  Future<void> launch() async {
    await supabase.signedIn();
    await tester.pumpWidget(app);
    await settle();
    await tap(openAccount);
  }

  /// Asks to delete the account; the confirmation is now open.
  Future<void> askToDelete() => tap(deleteAccount);

  Future<void> settle() => tester.pumpAndSettle();

  /// Scrolls to the target first: the account screen is a scroll view, and
  /// with the feedback row it is taller than the test viewport, so the
  /// delete button below it is off-screen until it is scrolled to.
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
