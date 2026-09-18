import 'package:design_system/design_system.dart';
import 'package:feature_session/feature_session.dart';
import 'package:feature_session/src/bloc/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:journal_repository/journal_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testing/testing.dart';

/// Drives a journaling session on the feature's own page, composed the way
/// the app composes it, against a scripted agent, a signed-in Supabase and
/// a spied PostHog. Finders are getters, actions settle, tests read as
/// prose.
class SessionRobot(
  final WidgetTester tester,
  final AgentStub agent, {
  final AnalyticsSpy? spy,
  final SupabaseStub? supabase,
  final OpenSession? resume,
}) {
  /// Set up by [launch]; the spy every test can inspect.
  late final AnalyticsSpy analytics = spy ?? AnalyticsSpy();

  /// Signed in before launch unless a test hands in its own.
  late final SupabaseStub supabaseStub = supabase ?? SupabaseStub();

  Finder get thinking => find.byType(CircularProgressIndicator);
  Finder get question => find.byKey(SessionView.questionKey);
  Finder get answerInput => find.byType(AnswerInput);
  Finder get summary => find.byKey(EntryView.summaryKey);
  Finder get retry => find.byKey(SessionView.retryKey);

  String get questionText => tester.widget<Text>(question).data!;

  /// The session page as the app would show it: every utility and this
  /// feature registered over the scripted leaves, then the page under the
  /// app's themes. Reading this composes the container, so read it once
  /// per test.
  Widget get app {
    registerUtilitiesUnderTest(
      GetIt.I,
      agent: agent,
      supabase: supabaseStub,
      analytics: analytics,
    );
    registerSession(GetIt.I);
    return pageUnderTest(SessionPage(resume: resume));
  }

  /// Opens the session signed in; the first round is in flight until
  /// [settle].
  Future<void> launch() async {
    await supabaseStub.signedIn();
    await tester.pumpWidget(app);
    // One frame builds the page, the next fires the first round.
    await tester.pump();
    await tester.pump();
  }

  Future<void> settle() => tester.pumpAndSettle();

  Future<void> answerRating(int value) async {
    await tester.tap(find.byKey(RatingInput.chipKey(value)));
    await tester.pump();
    await tapSubmit(tester, RatingInput.submitKey);
    await settle();
  }

  Future<void> answerLongtext(String text) async {
    await tester.enterText(find.byKey(LongtextInput.fieldKey), text);
    await tester.pump();
    await tapSubmit(tester, LongtextInput.submitKey);
    await settle();
  }

  Future<void> answerTextList(List<String> items) async {
    for (final item in items) {
      await tester.enterText(find.byKey(TextListInput.fieldKey), item);
      await tester.pump();
      await tester.tap(find.byKey(TextListInput.addKey));
      await tester.pump();
    }
    await tapSubmit(tester, TextListInput.submitKey);
    await settle();
  }

  Future<void> answerColor(String paletteName) async {
    await tester.tap(find.byKey(ColorInput.paletteKey(paletteName)));
    await tester.pump();
    await tapSubmit(tester, ColorInput.submitKey);
    await settle();
  }

  Future<void> tapRetry() async {
    await tester.tap(retry);
    await settle();
  }

  /// The answer value the app posted in its most recent round.
  Object? get lastPostedValue =>
      (agent.lastRequest['answer'] as Map<String, dynamic>)['value'];

  /// The tool call the app answered in its most recent round.
  String get lastAnsweredToolCall =>
      (agent.lastRequest['answer'] as Map<String, dynamic>)['tool_call_id']
          as String;

  /// The failure copy for anything that is not a server-refused round.
  static const unreachableMessage = 'Could not reach the journaling assistant.';

  /// The failure copy when the server refused the round because the model
  /// could not be reached.
  static const unavailableMessage = SessionBloc.modelUnavailableMessage;

  /// The failure copy when the finished entry could not be filed.
  static const entrySaveFailedMessage = SessionBloc.entrySaveFailedMessage;

  // The canned questions, shared with every package through `testing`.
  static const rate = rateQuestion;
  static const grateful = gratefulQuestion;
  static const colors = colorsQuestion;
  static const best = bestQuestion;
}
