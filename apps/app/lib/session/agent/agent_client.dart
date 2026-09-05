import 'dart:convert';

import 'package:emotely/session/agent/advance_response.dart';
import 'package:http/http.dart' as http;

/// The client's answer to the pending question: the tool call it answers
/// and the raw widget value the server records.
typedef SessionAnswer = ({String toolCallId, Object? value});

/// The only network seam of the app: one call per session round.
///
/// The session is stateless on the server; the caller echoes the signed
/// transcript it was handed last time.
class const AgentClient({
  required final http.Client httpClient,
  required final Uri endpoint,
}) {
  /// Advances the session: no transcript starts one, a transcript plus the
  /// [answer] to its pending question continues it.
  Future<AdvanceResponse> advance({
    List<Object?>? transcript,
    String? signature,
    SessionAnswer? answer,
  }) async {
    final response = await httpClient.post(
      endpoint,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'transcript': ?transcript,
        'signature': ?signature,
        if (answer != null)
          'answer': {'toolCallId': answer.toolCallId, 'value': answer.value},
      }),
    );
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
      final decoded = jsonDecode(body);
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
