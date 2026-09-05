import 'package:emotely/contract/contract.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Product analytics for the session, content-free by construction
/// (ADR 0005): only question ids, answer types, counts and status codes
/// leave the device — never a question text or an answer value. A test
/// drives a whole session with needle strings and proves none escapes.
class const SessionAnalytics({required final Posthog posthog}) {
  /// The user began a session.
  Future<void> sessionStarted() =>
      posthog.capture(eventName: 'session_started');

  /// The agent asked [question] as the [index]th question (0-based).
  Future<void> questionAsked({
    required AskQuestion question,
    required int index,
  }) => posthog.capture(
    eventName: 'question_asked',
    properties: {..._describe(question), 'index': index},
  );

  /// The user submitted the widget for [question].
  Future<void> answerSubmitted({required AskQuestion question}) => posthog
      .capture(eventName: 'answer_submitted', properties: _describe(question));

  /// The agent completed the session with [answers] recorded answers.
  Future<void> sessionCompleted({required int answers}) => posthog.capture(
    eventName: 'session_completed',
    properties: {'answers': answers},
  );

  /// A round failed; [statusCode] is absent when the server was unreachable.
  Future<void> sessionFailed({int? statusCode}) => posthog.capture(
    eventName: 'session_failed',
    properties: {'status_code': ?statusCode},
  );

  /// The user retried the failed round.
  Future<void> sessionRetried() =>
      posthog.capture(eventName: 'session_retried');

  static Map<String, Object> _describe(AskQuestion question) => {
    'question_id': question.questionId,
    'answer_type': question.answerType.name,
  };
}
