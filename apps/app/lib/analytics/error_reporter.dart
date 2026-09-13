import 'dart:async';

import 'package:emotely/session/agent/agent_client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handled failures, reported to PostHog error tracking (ADR 0004) with
/// their type, stack trace and the step that failed — the "why" behind the
/// counting events next to them (`session_failed`, `entry_save_failed`, …),
/// which only say how often.
///
/// Content-free by construction like the analytics (ADR 0005): the
/// properties are ids, status codes and the step, and an exception's message
/// only travels when its type is known to carry server or transport text —
/// see [contentFree]. The version is stamped by the SDK (`$app_version`).
class const ErrorReporter({required final Posthog posthog}) {
  /// A session round failed against the agent; [statusCode] is absent when
  /// the server was unreachable.
  Future<void> sessionFailed(
    Exception error,
    StackTrace stackTrace, {
    int? statusCode,
  }) => _report(
    error,
    stackTrace,
    step: 'session_round',
    properties: {'status_code': ?statusCode},
  );

  /// A round could not be written to the journal row [sessionId] (absent
  /// when the row itself could not be created).
  Future<void> sessionSaveFailed(
    Exception error,
    StackTrace stackTrace, {
    String? sessionId,
  }) => _report(
    error,
    stackTrace,
    step: 'session_save',
    properties: {'session_id': ?sessionId},
  );

  /// The finished entry could not be filed for the session row [sessionId].
  Future<void> entrySaveFailed(
    Exception error,
    StackTrace stackTrace, {
    String? sessionId,
  }) => _report(
    error,
    stackTrace,
    step: 'entry_save',
    properties: {'session_id': ?sessionId},
  );

  /// Supabase refused to send a sign-in code.
  Future<void> codeRequestFailed(Exception error, StackTrace stackTrace) =>
      _report(error, stackTrace, step: 'sign_in_code_request');

  /// The `delete_account` call failed.
  Future<void> accountDeletionFailed(Exception error, StackTrace stackTrace) =>
      _report(error, stackTrace, step: 'account_deletion');

  Future<void> _report(
    Exception error,
    StackTrace stackTrace, {
    required String step,
    Map<String, Object> properties = const {},
  }) => posthog.captureException(
    error: contentFree(error),
    stackTrace: stackTrace,
    properties: {'step': step, ...properties},
  );

  /// [error] as it may leave the device. PostHog records an exception's
  /// `toString()`, so only types whose text is known to be the server's own
  /// words or a transport error naming a host go out as they are; anything
  /// else may quote what it choked on — a Postgres error the failing row, a
  /// JSON error the body — and goes out as a [WithheldException] instead.
  static Exception contentFree(Exception error) => switch (error) {
    AgentException() ||
    AuthApiException() ||
    AuthRetryableFetchException() ||
    http.ClientException() ||
    TimeoutException() => error,
    PostgrestException(:final code) || AuthException(:final code) =>
      WithheldException(error.runtimeType, code: code),
    _ => WithheldException(error.runtimeType),
  };
}

/// An exception reported without its message: [type] says what failed and
/// [code] (a SQLSTATE, an auth error code) which way; the text stays on the
/// device because it may quote the journal (ADR 0005).
@immutable
class const WithheldException(final Type type, {final String? code})
    implements Exception {
  @override
  String toString() =>
      '$type${code == null ? '' : ' $code'} (message withheld, ADR 0005)';

  @override
  bool operator ==(Object other) =>
      other is WithheldException && other.type == type && other.code == code;

  @override
  int get hashCode => Object.hash(type, code);
}
