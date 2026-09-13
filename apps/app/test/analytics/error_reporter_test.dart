import 'dart:async';

import 'package:emotely/analytics/error_reporter.dart';
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
      const noCode = AuthApiException('email rate limit exceeded');

      await reporter.sessionFailed(refused, trace, statusCode: 429);
      await reporter.sessionFailed(unreachable, trace);
      await reporter.sessionSaveFailed(saveRefused, trace, sessionId: 's-1');
      await reporter.sessionSaveFailed(saveRefused, trace);
      await reporter.entrySaveFailed(saveRefused, trace, sessionId: 's-1');
      await reporter.codeRequestFailed(noCode, trace);
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
        captured(noCode, {'step': 'sign_in_code_request'}),
        captured(withheld(PostgrestException, code: '42501'), {
          'step': 'account_deletion',
        }),
      ]);
      for (final exception in spy.exceptions) {
        expect(exception.stackTrace, same(trace));
      }
    });

    test('forwards only messages that are known to be free of content', () {
      // Server text the issue allows, and transport errors that only ever
      // name a host: sent as they are.
      const agent = AgentException(500, 'model unavailable');
      const auth = AuthApiException(
        'Signups not allowed',
        code: 'otp_disabled',
      );
      final fetch = AuthRetryableFetchException(message: 'Connection refused');
      final client = http.ClientException('Connection refused');
      final timeout = TimeoutException('Future not completed');
      for (final error in [agent, auth, fetch, client, timeout]) {
        expect(ErrorReporter.contentFree(error), same(error));
      }

      // Anything else could quote what it choked on: a Postgres error the
      // failing row, a JSON error the body. Only the type and a code travel.
      const jsonBody = '{"summary": "the day the sea turned violet"}';
      const json = FormatException('Unexpected character', jsonBody);
      const postgrest = PostgrestException(
        message: 'new row violates check constraint',
        code: '23514',
        details: 'Failing row contains (the day the sea turned violet)',
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
        ErrorReporter.contentFree(unknown),
        withheld(AuthUnknownException),
      );
      expect(ErrorReporter.contentFree(other), withheld(other.runtimeType));
      for (final error in [json, postgrest, unknown, other]) {
        expect(
          '${ErrorReporter.contentFree(error)}',
          isNot(contains('violet')),
        );
      }
    });

    test('a withheld exception is a value: same type and code, same one', () {
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
        '${withheld(FormatException)}',
        'FormatException (message withheld, ADR 0005)',
      );
    });
  });
}
