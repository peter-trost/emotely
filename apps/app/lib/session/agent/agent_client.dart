import 'dart:async';
import 'dart:convert';

import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:http/http.dart' as http;

/// The client's answer to the pending question: the tool call it answers
/// and the typed [Answer] the widget produced. Only its wire value is posted.
typedef SessionAnswer = ({String toolCallId, Answer answer});

/// The only network seam of the app: one call per session round.
///
/// The session is stateless on the server; the caller echoes the signed
/// transcript it was handed last time.
class const AgentClient({
  required final http.Client httpClient,
  required final Uri endpoint,
  required final String appVersion,
  required final String? Function() accessToken,
  final Duration timeout = defaultTimeout,
}) {
  /// A round is one model call; anything slower than this is a hung request
  /// and surfaces as a failure the user can retry.
  static const defaultTimeout = Duration(seconds: 30);

  /// Advances the session: no transcript starts one, a transcript plus the
  /// [answer] to its pending question continues it. Every request names the
  /// [appVersion] so the server can gate behaviour per version, and carries
  /// the signed-in user's token from [accessToken]; without one the server
  /// refuses the round (ADR 0010).
  Future<AdvanceResponse> advance({
    List<Object?>? transcript,
    String? signature,
    SessionAnswer? answer,
  }) async {
    final response = await httpClient
        .post(
          endpoint,
          headers: {
            'content-type': 'application/json',
            if (accessToken() case final token?)
              'authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'transcript': ?transcript,
            'signature': ?signature,
            if (answer != null)
              'answer': {
                'tool_call_id': answer.toolCallId,
                'value': answer.answer.wireValue,
              },
            'app_version': appVersion,
          }),
        )
        .timeout(timeout);
    // The server sends `application/json` without a charset, which
    // package:http would decode as Latin-1 — emoji answers must survive.
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw AgentException(response.statusCode, _errorMessage(body));
    }
    return AdvanceResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Object?;
      if (decoded case {'error': final String message}) {
        return message;
      }
    } on FormatException {
      // Not JSON: fall through to the generic message.
    }
    return 'unexpected response';
  }
}

/// A non-200 answer from the agent, with the server's own error message.
class const AgentException(final int statusCode, final String message)
    implements Exception {
  @override
  String toString() => 'AgentException($statusCode): $message';
}
