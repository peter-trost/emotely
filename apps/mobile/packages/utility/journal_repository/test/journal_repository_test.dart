import 'package:agent_client/agent_client.dart';
import 'package:contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_repository/journal_repository.dart';
import 'package:testing/testing.dart';

void main() {
  const question = AskQuestion(
    questionId: 'q1',
    question: 'How was today?',
    answerType: AnswerType.longtext,
  );
  const pending = PendingQuestion(toolCallId: 'c1', question: question);
  const answers = {'q1': Answer.longtext('Quiet.')};

  late SupabaseStub supabase;
  late JournalRepository repository;

  setUp(() {
    supabase = SupabaseStub();
    repository = JournalRepository(supabase: supabase.supabase);
  });

  group(JournalRepository, () {
    test('reads the session in progress with its pending question', () async {
      supabase.rest('GET /rest/v1/sessions', [
        rows([
          sessionRow(pending: pending, questions: const [question]),
        ]),
      ]);

      final open = await repository.openSession();

      expect(
        open,
        const OpenSession(
          id: SupabaseStub.sessionId,
          transcript: ['stored'],
          signature: 'stored-sig',
          questions: [question],
          pending: pending,
        ),
      );
      final request = supabase.to('GET /rest/v1/sessions').single;
      expect(request.query['status'], 'eq.in_progress');
    });

    test('has no session in progress when the journal holds none', () async {
      supabase.rest('GET /rest/v1/sessions', [rows(const [])]);

      expect(await repository.openSession(), isNull);
    });

    test('lists the filed entries as the server orders them', () async {
      final older = DateTime.utc(2026, 9, 1, 8);
      final newer = DateTime.utc(2026, 9, 2, 8);
      supabase.rest('GET /rest/v1/entries', [
        rows([
          entryRow(
            id: 'e2',
            summary: 'Newer',
            createdAt: newer,
            answers: answers,
            questions: const [question],
          ),
          entryRow(id: 'e1', summary: 'Older', createdAt: older),
        ]),
      ]);

      final entries = await repository.entries();

      expect(entries, [
        EntryRecord(
          id: 'e2',
          summary: 'Newer',
          answers: answers,
          questions: const [question],
          createdAt: newer,
        ),
        EntryRecord(
          id: 'e1',
          summary: 'Older',
          answers: const {},
          questions: const [],
          createdAt: older,
        ),
      ]);
      final request = supabase.to('GET /rest/v1/entries').single;
      expect(request.query['order'], 'created_at.desc.nullslast');
    });

    test('reads one entry by its id', () async {
      final written = DateTime.utc(2026, 9, 2, 8);
      supabase.rest('GET /rest/v1/entries', [
        rows([
          entryRow(
            id: 'e2',
            summary: 'Newer',
            createdAt: written,
            answers: answers,
            questions: const [question],
          ),
        ]),
      ]);

      final entry = await repository.entry('e2');

      expect(
        entry,
        EntryRecord(
          id: 'e2',
          summary: 'Newer',
          answers: answers,
          questions: const [question],
          createdAt: written,
        ),
      );
      final request = supabase.to('GET /rest/v1/entries').single;
      expect(request.query['id'], 'eq.e2');
    });

    test('has no entry for an id the journal does not hold', () async {
      supabase.rest('GET /rest/v1/entries', [rows(const [])]);

      expect(await repository.entry('gone'), isNull);
    });

    test('counts the entries without fetching any', () async {
      supabase.rest('HEAD /rest/v1/entries', [rowsCounted(3)]);

      expect(await repository.countEntries(), 3);

      // A count-only request: the server counts, no row travels.
      final request = supabase.to('HEAD /rest/v1/entries').single;
      expect(request.body, isNull);
    });

    test('discards a session by id', () async {
      supabase.rest('DELETE /rest/v1/sessions', [rowsChanged()]);

      await repository.discardSession('s9');

      final request = supabase.to('DELETE /rest/v1/sessions').single;
      expect(request.query['id'], 'eq.s9');
    });

    test('the first round replaces any session in progress', () async {
      supabase
        ..rest('DELETE /rest/v1/sessions', [rowsChanged()])
        ..rest('POST /rest/v1/sessions', [rowCreated('s1')]);

      final id = await repository.saveRound(
        sessionId: null,
        transcript: const ['t1'],
        signature: 'sig1',
        pending: pending,
        questions: const [question],
        appVersion: '2.0.0',
      );

      expect(id, 's1');
      final methods = [for (final r in supabase.requests) r.method];
      expect(methods, ['DELETE', 'POST']);
      expect(
        supabase.to('DELETE /rest/v1/sessions').single.query['status'],
        'eq.in_progress',
      );
      expect(supabase.bodies('/rest/v1/sessions').single, {
        'transcript': ['t1'],
        'signature': 'sig1',
        'pending': pending.toJson(),
        'questions': [question.toJson()],
        'app_version': '2.0.0',
        'question_set_id': JournalRepository.questionSetId,
      });
    });

    test('later rounds update the row and keep its id', () async {
      supabase.rest('PATCH /rest/v1/sessions', [rowsChanged()]);

      final id = await repository.saveRound(
        sessionId: 's1',
        transcript: const ['t1', 't2'],
        signature: 'sig2',
        pending: null,
        questions: const [question],
        appVersion: '2.0.0',
      );

      expect(id, 's1');
      final request = supabase.to('PATCH /rest/v1/sessions').single;
      expect(request.query['id'], 'eq.s1');
      expect(request.body, {
        'transcript': ['t1', 't2'],
        'signature': 'sig2',
        'pending': null,
        'questions': [question.toJson()],
        'app_version': '2.0.0',
      });
    });

    test('files the entry and closes the session in one call', () async {
      supabase.rest('POST /rest/v1/rpc/complete_session', [
        rpcReturned(SupabaseStub.entryId),
      ]);

      await repository.completeSession(
        sessionId: 's1',
        entry: const JournalEntry(summary: 'A quiet day.', answers: answers),
        questions: const [question],
      );

      expect(supabase.bodies('/rest/v1/rpc/complete_session').single, {
        'session_id': 's1',
        'summary': 'A quiet day.',
        'answers': {'q1': answers['q1']!.toJson()},
        'questions': [question.toJson()],
      });
    });
  });

  group(EntryRecord, () {
    final record = EntryRecord(
      id: 'e1',
      summary: 'A quiet day.',
      answers: answers,
      questions: const [question],
      createdAt: DateTime.utc(2026, 9, 2),
    );

    test('is the entry the session produced', () {
      expect(
        record.entry,
        const JournalEntry(summary: 'A quiet day.', answers: answers),
      );
    });

    test('keys its questions by id', () {
      expect(record.questionsById, {'q1': question});
    });
  });
}
