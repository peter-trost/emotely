import 'package:emotely/contract/contract.dart';
import 'package:emotely/journal/journal_models.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The app's side of ADR 0010: journal rows written and read straight from
/// Supabase under the signed-in user's own rights. Nothing here goes through
/// the agent, and nothing here can reach another user's rows.
class const JournalStore({required final SupabaseClient supabase}) {
  /// The set the agent walks today; it is not on the wire yet, so the app
  /// names it. Mirrors `defaultQuestionSet.id` in `apps/agent`.
  static const questionSetId = 'legacy-reflections';

  static const _sessions = 'sessions';
  static const _entries = 'entries';
  static const _inProgress = 'in_progress';

  /// The session still in progress, if any: what the journal offers to
  /// continue.
  Future<OpenSession?> openSession() async {
    final row = await supabase
        .from(_sessions)
        .select()
        .eq('status', _inProgress)
        .maybeSingle();
    return row == null ? null : OpenSession.fromJson(row);
  }

  /// Every filed entry, newest first.
  Future<List<EntryRecord>> entries() async {
    final rows = await supabase
        .from(_entries)
        .select()
        .order('created_at', ascending: false);
    return [for (final row in rows) EntryRecord.fromJson(row)];
  }

  /// Drops the unfinished session [sessionId]; the next one starts fresh.
  Future<void> discardSession(String sessionId) =>
      supabase.from(_sessions).delete().eq('id', sessionId);

  /// Records a round: the signed transcript the agent handed back, the
  /// question now pending (none once the session is over) and every
  /// question asked so far. The first call creates the row, replacing any
  /// session still in progress, and every call returns the row's id.
  Future<String> saveRound({
    required String? sessionId,
    required List<Object?> transcript,
    required String signature,
    required PendingQuestion? pending,
    required Iterable<AskQuestion> questions,
    required String appVersion,
  }) async {
    final row = {
      'transcript': transcript,
      'signature': signature,
      'pending': pending?.toJson(),
      'questions': [for (final question in questions) question.toJson()],
      'app_version': appVersion,
    };
    if (sessionId != null) {
      await supabase.from(_sessions).update(row).eq('id', sessionId);
      return sessionId;
    }
    await supabase.from(_sessions).delete().eq('status', _inProgress);
    final created = await supabase
        .from(_sessions)
        .insert({...row, 'question_set_id': questionSetId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  /// Files the [entry] and closes the session in one transaction on the
  /// server, so a journal never holds one without the other.
  Future<void> completeSession({
    required String sessionId,
    required JournalEntry entry,
    required Iterable<AskQuestion> questions,
  }) => supabase.rpc<Object?>(
    'complete_session',
    params: {
      'session_id': sessionId,
      'summary': entry.summary,
      'answers': entry.toJson()['answers'],
      'questions': [for (final question in questions) question.toJson()],
    },
  );
}
