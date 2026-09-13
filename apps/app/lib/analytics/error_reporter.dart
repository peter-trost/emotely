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
/// only travels when its type is known to carry the agent's own words or a
/// transport error — see [contentFree]. Uncaught errors take the SDK's own
/// path, where `contentFreeExceptions` (error_tracking.dart) applies the
/// same rule on the wire. The version is stamped by the SDK
/// (`$app_version`).
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

  /// Supabase refused the code the user typed.
  Future<void> codeVerifyFailed(Exception error, StackTrace stackTrace) =>
      _report(error, stackTrace, step: 'sign_in_code_verify');

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
  /// `toString()`, so only types whose text is the agent's own error
  /// message or a transport error naming a host go out as they are (the
  /// same set `forwardedTypes` lets through on the wire). Everything else
  /// may quote what it choked on — a Postgres error the failing row, a JSON
  /// error the body, GoTrue the address it validated or, for a 5xx, the
  /// whole response body — and goes out as a [WithheldException] instead.
  static Exception contentFree(Exception error) => switch (error) {
    AgentException() || http.ClientException() || TimeoutException() => error,
    PostgrestException(:final code) => WithheldException(
      error.runtimeType,
      code: code,
    ),
    AuthException(:final code, :final statusCode) => WithheldException(
      error.runtimeType,
      code: code,
      statusCode: statusCode,
    ),
    _ => WithheldException(error.runtimeType),
  };
}

/// An exception reported without its message: [type] says what failed,
/// [code] (a SQLSTATE, a GoTrue error code) and [statusCode] which way; the
/// text stays on the device because it may quote the journal or the user
/// (ADR 0005).
///
/// What a debugger gives up: for a `PostgrestException` the `message`,
/// `details` and `hint` — i.e. which constraint or policy objected, only
/// the SQLSTATE class survives; for an `AuthException` GoTrue's sentence.
/// The way back is to reproduce locally with the ids the report carries,
/// or to add a field to the allowlist in [ErrorReporter.contentFree] once
/// it is proven content-free for every value it can take.
@immutable
class const WithheldException(
  final Type type, {
  final String? code,
  final String? statusCode,
}) implements Exception {
  @override
  String toString() =>
      '${[type, ?statusCode, ?code].join(' ')} (message withheld, ADR 0005)';

  @override
  bool operator ==(Object other) =>
      other is WithheldException &&
      other.type == type &&
      other.code == code &&
      other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(type, code, statusCode);
}
