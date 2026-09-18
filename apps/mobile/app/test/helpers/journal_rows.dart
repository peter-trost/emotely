import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';

import 'supabase_stub.dart';

/// A `sessions` row as Supabase returns it.
Map<String, Object?> sessionRow({
  String id = SupabaseStub.sessionId,
  List<Object?> transcript = const ['stored'],
  String signature = 'stored-sig',
  PendingQuestion? pending,
  List<AskQuestion> questions = const [],
}) => {
  'id': id,
  'user_id': SupabaseStub.userId,
  'question_set_id': 'legacy-reflections',
  'transcript': transcript,
  'signature': signature,
  'status': 'in_progress',
  'pending': pending?.toJson(),
  'questions': [for (final question in questions) question.toJson()],
  'app_version': '1.0.0',
  'created_at': '2026-09-07T20:00:00+00:00',
  'updated_at': '2026-09-07T20:05:00+00:00',
};

/// An `entries` row as Supabase returns it.
Map<String, Object?> entryRow({
  required String id,
  required String summary,
  required DateTime createdAt,
  Map<String, Answer> answers = const {},
  List<AskQuestion> questions = const [],
}) => {
  'id': id,
  'user_id': SupabaseStub.userId,
  'session_id': null,
  'summary': summary,
  'answers': answers.map(
    (questionId, answer) => MapEntry(questionId, answer.toJson()),
  ),
  'questions': [for (final question in questions) question.toJson()],
  'created_at': createdAt.toUtc().toIso8601String(),
};
