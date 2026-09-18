import 'package:emotely/contract/contract.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';
import '../../session/session_robot.dart';
import '../journal_robot.dart';

void main() {
  group(JournalPage, () {
    const entriesEndpoint = 'GET /rest/v1/entries';
    const sessionsEndpoint = 'GET /rest/v1/sessions';
    final newer = DateTime.utc(2026, 9, 7, 20);
    final older = DateTime.utc(2026, 9, 6, 21);

    JournalRobot robotWith(
      WidgetTester tester, {
      List<Map<String, Object?>> entries = const [],
      Map<String, Object?>? openSession,
      AgentStub? agent,
    }) {
      final supabase = SupabaseStub()
        ..rest(entriesEndpoint, [rows(entries)])
        ..rest(sessionsEndpoint, [
          rows([?openSession]),
        ]);
      return JournalRobot(
        tester,
        supabase: supabase,
        agent: agent ?? AgentStub(),
      );
    }

    testWidgets('lists filed entries newest first with date and summary', (
      tester,
    ) async {
      final robot = robotWith(
        tester,
        entries: [
          entryRow(id: 'e-new', summary: 'A calm day.', createdAt: newer),
          entryRow(id: 'e-old', summary: 'A loud day.', createdAt: older),
        ],
      );
      await robot.launch();

      final read = robot.supabase.to(entriesEndpoint).single;
      expect(read.query['order'], 'created_at.desc.nullslast');
      expect(robot.entries, findsNWidgets(2));
      expect(
        tester.getTopLeft(robot.entry('e-new')).dy,
        lessThan(tester.getTopLeft(robot.entry('e-old')).dy),
      );
      expect(find.text('A calm day.'), findsOneWidget);
      expect(find.text('Sep 7, 2026'), findsOneWidget);
      expect(robot.empty, findsNothing);
      expect(robot.analytics.events, [
        event('journal_viewed', {'entries': 2, 'open_session': false}),
      ]);
    });

    testWidgets('an empty journal explains itself and starts a session', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: SessionRobot.rate)]);
      final robot = robotWith(tester, agent: agent);
      await robot.launch();

      expect(robot.empty, findsOneWidget);
      expect(robot.start, findsOneWidget);
      expect(robot.continueSession, findsNothing);

      await robot.tap(robot.start);

      expect(robot.session, findsOneWidget);
      expect(robot.question, findsOneWidget);
      expect(agent.requests, hasLength(1));

      await robot.back();

      // The journal reads itself again when the session comes back.
      expect(robot.home, findsOneWidget);
      expect(robot.supabase.to(entriesEndpoint), hasLength(2));
    });

    testWidgets('continues an unfinished session without a server round', (
      tester,
    ) async {
      const pending = PendingQuestion(
        toolCallId: 'c2',
        question: SessionRobot.grateful,
      );
      final agent = AgentStub()
        ..script([awaiting(toolCallId: 'c3', question: SessionRobot.best)]);
      final robot = robotWith(
        tester,
        openSession: sessionRow(
          transcript: const ['stored', 'stored'],
          pending: pending,
          questions: [SessionRobot.rate, SessionRobot.grateful],
        ),
        agent: agent,
      );
      await robot.launch();

      expect(robot.continueSession, findsOneWidget);
      expect(robot.start, findsNothing);
      expect(
        robot.analytics.events.single,
        event('journal_viewed', {'entries': 0, 'open_session': true}),
      );

      await robot.tap(robot.continueSession);

      expect(robot.session, findsOneWidget);
      expect(find.text('Question 2'), findsOneWidget);
      expect(find.text(SessionRobot.grateful.question), findsOneWidget);
      expect(agent.requests, isEmpty);
      expect(robot.analytics.events.last, event('session_resumed'));

      await tester.enterText(
        find.byType(TextField),
        'the journal that remembers',
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Submit'),
        ),
      );
      await robot.settle();

      // The stored transcript, not a fresh one, and the stored row updated.
      expect(agent.lastRequest['transcript'], ['stored', 'stored']);
      expect(agent.lastRequest['signature'], 'stored-sig');
      expect(
        (agent.lastRequest['answer'] as Map<String, dynamic>)['tool_call_id'],
        'c2',
      );
      final saved = robot.supabase.to('PATCH /rest/v1/sessions').single;
      expect(saved.query['id'], 'eq.${SupabaseStub.sessionId}');
      expect(find.text('Question 3'), findsOneWidget);
    });

    testWidgets(
      'finishes a session that was saved without a pending question',
      (tester) async {
        final agent = AgentStub()
          ..script([
            completed(summary: 'Finished after all.', answers: const {}),
          ]);
        final robot = robotWith(
          tester,
          openSession: sessionRow(questions: [SessionRobot.rate]),
          agent: agent,
        );
        await robot.launch();

        await robot.tap(robot.continueSession);

        expect(agent.lastRequest['transcript'], ['stored']);
        expect(agent.lastRequest['signature'], 'stored-sig');
        expect(agent.lastRequest.containsKey('answer'), isFalse);
        expect(robot.summary, findsOneWidget);
        expect(
          robot.supabase.to('POST /rest/v1/rpc/complete_session').single.body,
          containsPair('session_id', SupabaseStub.sessionId),
        );
      },
    );

    testWidgets('discards an unfinished session', (tester) async {
      final robot = robotWith(tester, openSession: sessionRow());
      robot.supabase.rest(sessionsEndpoint, [rows(const [])]);
      await robot.launch();

      await robot.tap(robot.discard);

      final dropped = robot.supabase.to('DELETE /rest/v1/sessions').single;
      expect(dropped.query['id'], 'eq.${SupabaseStub.sessionId}');
      expect(robot.start, findsOneWidget);
      expect(robot.continueSession, findsNothing);
      expect(robot.analytics.events, [
        event('journal_viewed', {'entries': 0, 'open_session': true}),
        event('session_discarded'),
        event('journal_viewed', {'entries': 0, 'open_session': false}),
      ]);
    });

    testWidgets('explains when the journal cannot be read, and retries', (
      tester,
    ) async {
      final supabase = SupabaseStub()
        ..rest(entriesEndpoint, [restRefused(), rows(const [])])
        ..rest(sessionsEndpoint, [rows(const [])]);
      final robot = JournalRobot(
        tester,
        supabase: supabase,
        agent: AgentStub(),
      );
      await robot.launch();

      expect(find.text(JournalView.failureMessage), findsOneWidget);
      expect(robot.retry, findsOneWidget);

      await robot.tap(robot.retry);

      expect(robot.start, findsOneWidget);
    });

    testWidgets('a discard that fails is a failure with a retry', (
      tester,
    ) async {
      final robot = robotWith(tester, openSession: sessionRow());
      robot.supabase
        ..rest('DELETE /rest/v1/sessions', [restRefused()])
        ..rest(sessionsEndpoint, [rows(const [])]);
      await robot.launch();

      await robot.tap(robot.discard);

      expect(find.text(JournalView.failureMessage), findsOneWidget);

      await robot.tap(robot.retry);

      expect(robot.start, findsOneWidget);
    });

    testWidgets('opens an entry and reads it back', (tester) async {
      final robot = robotWith(
        tester,
        entries: [
          entryRow(
            id: 'e-1',
            summary: 'A seven kind of day.',
            createdAt: newer,
            answers: {SessionRobot.rate.questionId: const Answer.rating(7)},
            questions: [SessionRobot.rate],
          ),
        ],
      );
      await robot.launch();

      await robot.tap(robot.entry('e-1'));

      expect(robot.entryPage, findsOneWidget);
      expect(find.text('A seven kind of day.'), findsOneWidget);
      expect(find.text(SessionRobot.rate.question), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
      expect(robot.analytics.events.last, event('entry_opened'));

      await robot.back();

      expect(robot.home, findsOneWidget);
    });

    testWidgets('signs out and forgets the user', (tester) async {
      final robot = robotWith(tester);
      robot.supabase.script(logout: [signedOut()]);
      await robot.launch();

      await robot.tap(robot.signOut);

      expect(robot.signIn, findsOneWidget);
      expect(robot.analytics.events.last, event('signed_out'));
      expect(robot.analytics.resets, 1);
    });

    testWidgets('signs out even when the server cannot be told', (
      tester,
    ) async {
      final robot = robotWith(tester);
      robot.supabase.script(logout: [authUnreachable()]);
      await robot.launch();

      await robot.tap(robot.signOut);

      expect(robot.signIn, findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final robot = robotWith(
        tester,
        entries: [
          entryRow(id: 'e-1', summary: 'A calm day.', createdAt: newer),
        ],
        openSession: sessionRow(),
      );
      await robot.supabase.signedIn();

      await tester.expectMeetsAccessibilityGuidelines(robot.app);
    });
  });
}
