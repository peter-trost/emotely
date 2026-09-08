import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The app's side of ADR 0010: journal rows written straight to Supabase
/// under the signed-in user's own rights. Nothing here goes through the
/// agent, and nothing here can reach another user's rows.
class const JournalStore({required final SupabaseClient supabase}) {
  /// The set the agent walks today; it is not on the wire yet, so the app
  /// names it. Mirrors `defaultQuestionSet.id` in `apps/agent`.
  static const questionSetId = 'legacy-reflections';

  static const _sessions = 'sessions';

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
    await supabase.from(_sessions).delete().eq('status', 'in_progress');
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
