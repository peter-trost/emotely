import 'package:agent_client/agent_client.dart';
import 'package:feature_journal/feature_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

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
      bool consentGranted = true,
      List<AuthRound> consentReads = const [],
    }) {
      final supabase = SupabaseStub()
        ..rest(entriesEndpoint, [rows(entries)])
        ..rest(sessionsEndpoint, [
          rows([?openSession]),
        ])
        ..rest(consentRead, consentReads)
        ..always(consentRead, consentStands(granted: consentGranted));
      return JournalRobot(tester, supabase: supabase, agent: AgentStub());
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
      final robot = robotWith(tester);
      await robot.launch();

      expect(robot.empty, findsOneWidget);
      expect(robot.start, findsOneWidget);
      expect(robot.continueSession, findsNothing);

      await robot.tap(robot.start);

      // Consent stood, so the session ran; the journal read itself again
      // when the session came back.
      expect(robot.navigator.consentRequests, 0);
      expect(robot.navigator.sessions, [false]);
      expect(robot.supabase.to(entriesEndpoint), hasLength(2));
    });

    testWidgets('continues an unfinished session where it left off', (
      tester,
    ) async {
      const pending = PendingQuestion(
        toolCallId: 'c2',
        question: gratefulQuestion,
      );
      final robot = robotWith(
        tester,
        openSession: sessionRow(
          transcript: const ['stored', 'stored'],
          pending: pending,
          questions: [rateQuestion, gratefulQuestion],
        ),
      );
      await robot.launch();

      expect(robot.continueSession, findsOneWidget);
      expect(robot.start, findsNothing);
      expect(
        robot.analytics.events.single,
        event('journal_viewed', {'entries': 0, 'open_session': true}),
      );

      await robot.tap(robot.continueSession);

      // Only the wish to continue travels; the session reads the stored
      // round back itself.
      expect(robot.navigator.sessions, [true]);
    });

    group('the consent gate', () {
      testWidgets('asks the server before every session, never a local flag', (
        tester,
      ) async {
        // Stands the first time, withdrawn elsewhere by the second.
        final robot = robotWith(
          tester,
          consentGranted: false,
          consentReads: [consentStands()],
        );
        await robot.launch();

        expect(robot.supabase.to(consentRead), isEmpty);

        await robot.tap(robot.start);

        expect(robot.supabase.to(consentRead), hasLength(1));
        expect(robot.navigator.consentRequests, 0);
        expect(robot.navigator.sessions, [false]);

        await robot.tap(robot.start);

        expect(robot.supabase.to(consentRead), hasLength(2));
        expect(robot.navigator.consentRequests, 1);
        expect(robot.navigator.sessions, [false]);
      });

      testWidgets('starts the session once consent is given', (tester) async {
        final robot = robotWith(tester, consentGranted: false);
        robot.navigator.consentGiven = true;
        await robot.launch();

        await robot.tap(robot.start);

        expect(robot.navigator.consentRequests, 1);
        expect(robot.navigator.sessions, [false]);
      });

      testWidgets('starts nothing when consent is not given', (tester) async {
        final robot = robotWith(tester, consentGranted: false);
        await robot.launch();

        await robot.tap(robot.start);

        expect(robot.navigator.consentRequests, 1);
        expect(robot.navigator.sessions, isEmpty);
        expect(robot.home, findsOneWidget);
      });

      testWidgets('continuing an unfinished session is gated too', (
        tester,
      ) async {
        final robot = robotWith(
          tester,
          openSession: sessionRow(questions: [rateQuestion]),
          consentGranted: false,
        );
        await robot.launch();

        await robot.tap(robot.continueSession);

        expect(robot.navigator.consentRequests, 1);
        expect(robot.navigator.sessions, isEmpty);
      });

      testWidgets('a consent that cannot be read is asked for', (tester) async {
        // Not knowing is not knowing the user consented: the gate stays
        // shut, and the consent screen (which reads again) says why.
        final robot = robotWith(tester, consentReads: [restRefused()]);
        await robot.launch();

        await robot.tap(robot.start);

        expect(robot.navigator.consentRequests, 1);
        expect(robot.navigator.sessions, isEmpty);
      });
    });

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

    testWidgets('asks the app to open an entry by its id', (tester) async {
      final robot = robotWith(
        tester,
        entries: [
          entryRow(
            id: 'e-1',
            summary: 'A seven kind of day.',
            createdAt: newer,
          ),
        ],
      );
      await robot.launch();

      await robot.tap(robot.entry('e-1'));

      // Only the id travels: the entry screen reads the entry back itself.
      expect(robot.navigator.entryOpens, ['e-1']);
      expect(robot.analytics.events.last, event('entry_opened'));
    });

    testWidgets('opens the account screen and signs out through the app', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();

      await robot.tap(robot.account);
      await robot.tap(robot.signOut);

      expect(robot.navigator.accountOpens, 1);
      expect(robot.navigator.signOuts, 1);
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
