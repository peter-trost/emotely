import 'dart:async';

import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/analytics/error_tracking.dart';
import 'package:emotely/config/config_client.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/helpers.dart';

void main() {
  group(ErrorReporter, () {
    final trace = StackTrace.current;

    test('reports each failure with its step, the ids and the trace', () async {
      final spy = AnalyticsSpy();
      final reporter = spy.errorReporter;
      const refused = AgentException(429, 'rate limited');
      final unreachable = http.ClientException('Connection refused');
      const saveRefused = PostgrestException(message: 'refused', code: '42501');
      const noCode = AuthApiException(
        'email rate limit exceeded',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );
      const wrongCode = AuthApiException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      );
      const wrongPassword = AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );

      await reporter.sessionFailed(refused, trace, statusCode: 429);
      await reporter.sessionFailed(unreachable, trace);
      await reporter.sessionSaveFailed(saveRefused, trace, sessionId: 's-1');
      await reporter.sessionSaveFailed(saveRefused, trace);
      await reporter.entrySaveFailed(saveRefused, trace, sessionId: 's-1');
      await reporter.codeRequestFailed(noCode, trace);
      await reporter.codeVerifyFailed(wrongCode, trace);
      await reporter.passwordSignInFailed(wrongPassword, trace);
      await reporter.accountDeletionFailed(saveRefused, trace);

      expect(spy.exceptions, [
        captured(refused, {'step': 'session_round', 'status_code': 429}),
        captured(unreachable, {'step': 'session_round'}),
        captured(withheld(PostgrestException, code: '42501'), {
          'step': 'session_save',
          'session_id': 's-1',
        }),
        captured(withheld(PostgrestException, code: '42501'), {
          'step': 'session_save',
        }),
        captured(withheld(PostgrestException, code: '42501'), {
          'step': 'entry_save',
          'session_id': 's-1',
        }),
        captured(
          withheld(
            AuthApiException,
            code: 'over_email_send_rate_limit',
            statusCode: '429',
          ),
          {'step': 'sign_in_code_request'},
        ),
        captured(
          withheld(AuthApiException, code: 'otp_expired', statusCode: '403'),
          {'step': 'sign_in_code_verify'},
        ),
        captured(
          withheld(
            AuthApiException,
            code: 'invalid_credentials',
            statusCode: '400',
          ),
          {'step': 'sign_in_password'},
        ),
        captured(withheld(PostgrestException, code: '42501'), {
          'step': 'account_deletion',
        }),
      ]);
      for (final exception in spy.exceptions) {
        expect(exception.stackTrace, same(trace));
      }
    });

    test('forwards only messages that are known to be free of content', () {
      // The agent's own words, and transport errors that only ever name a
      // host: sent as they are — and the wire scrubber lets them through.
      const agent = AgentException(500, 'model unavailable');
      final client = http.ClientException('Connection refused');
      final timeout = TimeoutException('Future not completed');
      for (final error in [agent, client, timeout]) {
        expect(ErrorReporter.contentFree(error), same(error));
        expect(forwardedTypes, contains('${error.runtimeType}'));
      }

      // Anything else could quote what it choked on: a Postgres error the
      // failing row, a JSON error the body, GoTrue the email it validated
      // or — for a 5xx — the whole response body. Only the type and the
      // codes travel.
      const needle = 'needle.person@example.com';
      const jsonBody = '{"summary": "the day the sea turned violet"}';
      const json = FormatException('Unexpected character', jsonBody);
      const postgrest = PostgrestException(
        message: 'new row violates check constraint',
        code: '23514',
        details: 'Failing row contains (the day the sea turned violet)',
      );
      const api = AuthApiException(
        'Unable to validate email address: $needle',
        statusCode: '400',
        code: 'validation_failed',
      );
      final fetch = AuthRetryableFetchException(
        message: '{"message":"Error sending magic link email to $needle"}',
        statusCode: '500',
      );
      final unknown = AuthUnknownException(
        message: 'unexpected',
        originalError: jsonBody,
      );
      final other = Exception('the day the sea turned violet');
      expect(ErrorReporter.contentFree(json), withheld(FormatException));
      expect(
        ErrorReporter.contentFree(postgrest),
        withheld(PostgrestException, code: '23514'),
      );
      expect(
        ErrorReporter.contentFree(api),
        withheld(
          AuthApiException,
          code: 'validation_failed',
          statusCode: '400',
        ),
      );
      expect(
        ErrorReporter.contentFree(fetch),
        withheld(AuthRetryableFetchException, statusCode: '500'),
      );
      expect(
        ErrorReporter.contentFree(unknown),
        withheld(AuthUnknownException),
      );
      expect(ErrorReporter.contentFree(other), withheld(other.runtimeType));
      for (final error in [json, postgrest, api, fetch, unknown, other]) {
        final leaving = '${ErrorReporter.contentFree(error)}';
        expect(leaving, isNot(contains('violet')));
        expect(leaving, isNot(contains('needle')));
      }
    });

    test('a config failure never quotes the body it could not read', () async {
      // ConfigException is forwarded with its message, so the message must
      // never be built from an error that embeds what it choked on — a
      // FormatException carries the source it failed to parse (ADR 0005).
      const body = '{"summary": "the day the sea turned violet"}';
      final stub = ConfigStub()..script([configMalformed(body)]);

      final error = await stub.configClient.fetch().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );

      expect(error, isA<ConfigException>());
      expect('$error', isNot(contains('violet')));
      expect(
        '${ErrorReporter.contentFree(error! as Exception)}',
        isNot(contains('violet')),
      );
    });

    test('a withheld exception is a value: same type and codes, same one', () {
      // What PostHog groups by is all that is left of it, so two failures
      // of the same kind must read as one.
      expect({
        ErrorReporter.contentFree(
          const PostgrestException(message: 'row a', code: '23514'),
        ),
        ErrorReporter.contentFree(
          const PostgrestException(message: 'row b', code: '23514'),
        ),
        ErrorReporter.contentFree(
          const PostgrestException(message: 'row c', code: '42501'),
        ),
      }, hasLength(2));
      expect(
        '${withheld(PostgrestException, code: '23514')}',
        'PostgrestException 23514 (message withheld, ADR 0005)',
      );
      expect(
        '${withheld(AuthApiException, code: 'otp_expired', statusCode: '403')}',
        'AuthApiException 403 otp_expired (message withheld, ADR 0005)',
      );
      expect(
        '${withheld(FormatException)}',
        'FormatException (message withheld, ADR 0005)',
      );
    });

    test('the spy sees the cause chain the SDK walks', () async {
      // PostHog appends an error's causes (`cause`, AsyncError,
      // ParallelWaitError) as further exception items, so they leave too.
      final spy = AnalyticsSpy();
      final caused = _Caused(cause: Exception('root: violet'));
      final async = AsyncError(Exception('async: violet'), trace);
      final parallel = ParallelWaitError<List<Object?>, List<AsyncError?>>(
        const [null],
        [AsyncError(Exception('parallel: violet'), trace)],
      );

      for (final error in [caused, async, parallel]) {
        await spy.posthog.captureException(error: error, stackTrace: trace);
      }

      final outgoing = spy.outgoingStrings.toList();
      expect(outgoing, contains(contains('root: violet')));
      expect(outgoing, contains(contains('async: violet')));
      expect(outgoing, contains(contains('parallel: violet')));
    });
  });
}

class const _Caused({required final Object cause}) implements Exception {
  @override
  String toString() => '_Caused';
}
