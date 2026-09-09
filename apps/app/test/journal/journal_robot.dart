import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/journal/view/entry_page.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/helpers.dart';

/// Drives the journal home through the real app against a scripted
/// Supabase and agent.
class JournalRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
  required final AgentStub agent,
}) {
  final analytics = AnalyticsSpy();

  Finder get home => find.byType(JournalPage);
  Finder get session => find.byType(SessionPage);
  Finder get entryPage => find.byType(EntryPage);
  Finder get signIn => find.byType(SignInPage);
  Finder get start => find.byKey(JournalView.startKey);
  Finder get continueSession => find.byKey(JournalView.continueKey);
  Finder get discard => find.byKey(JournalView.discardKey);
  Finder get signOut => find.byKey(JournalView.signOutKey);
  Finder get retry => find.byKey(JournalView.retryKey);
  Finder get empty => find.byKey(JournalView.emptyKey);
  Finder get entries => find.byType(ListTile);
  Finder get summary => find.byKey(EntryView.summaryKey);
  Finder get question => find.byKey(SessionView.questionKey);

  Finder entry(String id) => find.byKey(JournalView.entryKey(id));

  Widget get app =>
      appUnderTest(agent: agent, supabase: supabase, analytics: analytics);

  /// Launches the app signed in and lets the journal load.
  Future<void> launch() async {
    await supabase.signedIn();
    await tester.pumpWidget(app);
    await settle();
  }

  Future<void> settle() => tester.pumpAndSettle();

  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await settle();
  }

  Future<void> back() async {
    await tester.pageBack();
    await settle();
  }
}
