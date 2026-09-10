import 'package:emotely/contract/contract.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';
import '../session_robot.dart';

/// The session writes itself to the journal as it goes (ADR 0010): every
/// round updates the user's session row, completion files the entry.
void main() {
  group(JournalStore, () {
    const sessions = 'POST /rest/v1/sessions';
    const updates = 'PATCH /rest/v1/sessions';
    const complete = 'POST /rest/v1/rpc/complete_session';

    testWidgets('saves the session after every round', (tester) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          awaiting(
            toolCallId: 'c2',
            question: SessionRobot.best,
            transcript: const ['round', 'round'],
            signature: 'sig-2',
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      final supabase = robot.supabaseStub;
      // Until resume lands, a new session replaces an unfinished one.
      final cleared = supabase.to('DELETE /rest/v1/sessions').single;
      expect(cleared.query['status'], 'eq.in_progress');
      final created = supabase.to(sessions).single;
      expect(created.query['select'], 'id');
      expect(created.body, {
        'question_set_id': JournalStore.questionSetId,
        'transcript': AgentStub.transcript,
        'signature': AgentStub.signature,
        'pending': {
          'tool_call_id': 'c1',
          'question': SessionRobot.rate.toJson(),
        },
        'questions': [SessionRobot.rate.toJson()],
        'app_version': AgentStub.appVersion,
      });

      await robot.answerRating(7);

      final updated = supabase.to(updates).single;
      expect(updated.query['id'], 'eq.${SupabaseStub.sessionId}');
      expect(updated.body, {
        'transcript': ['round', 'round'],
        'signature': 'sig-2',
        'pending': {
          'tool_call_id': 'c2',
          'question': SessionRobot.best.toJson(),
        },
        'questions': [SessionRobot.rate.toJson(), SessionRobot.best.toJson()],
        'app_version': AgentStub.appVersion,
      });
      expect(supabase.to(sessions), hasLength(1));
    });

    testWidgets('files the entry and closes the session in one call', (
      tester,
    ) async {
      const answers = {'q-rate': Answer.rating(7)};
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          completed(summary: 'A seven.', answers: answers),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(7);

      expect(robot.summary, findsOneWidget);
      final filed = robot.supabaseStub.to(complete).single;
      expect(filed.body, {
        'session_id': SupabaseStub.sessionId,
        'summary': 'A seven.',
        'answers': {'q-rate': const Answer.rating(7).toJson()},
        'questions': [SessionRobot.rate.toJson()],
      });
      expect(robot.supabaseStub.to(updates), isEmpty);
      expect(
        robot.analytics.events.last,
        event('session_completed', {'answers': 1}),
      );
    });

    testWidgets('keeps going when a round cannot be saved', (tester) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          completed(summary: 'Saved late.', answers: const {}),
        ]);
      final supabase = SupabaseStub()..rest(sessions, [restRefused()]);
      final robot = SessionRobot(tester, agent, supabase: supabase);
      await robot.launch();
      await robot.settle();

      expect(robot.question, findsOneWidget);
      expect(robot.analytics.events.last, event('session_save_failed'));

      await robot.answerRating(3);

      // The row is created on completion instead, then the entry is filed.
      expect(supabase.to(sessions), hasLength(2));
      expect(
        supabase.to(complete).single.body,
        containsPair('session_id', SupabaseStub.sessionId),
      );
      expect(robot.summary, findsOneWidget);
    });

    testWidgets('an entry that cannot be filed is retried without the agent', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          completed(summary: 'Kept.', answers: const {}),
        ]);
      final supabase = SupabaseStub()..rest(complete, [restRefused()]);
      final robot = SessionRobot(tester, agent, supabase: supabase);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(9);

      expect(find.text(SessionRobot.entrySaveFailedMessage), findsOneWidget);
      expect(robot.summary, findsNothing);
      expect(robot.analytics.events.last, event('entry_save_failed'));

      await robot.tapRetry();

      expect(robot.summary, findsOneWidget);
      expect(agent.requests, hasLength(2));
      expect(supabase.to(complete), hasLength(2));
    });
  });
}
