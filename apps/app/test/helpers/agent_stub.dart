import 'dart:convert';

import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

/// One scripted server round.
typedef Round = Future<http.Response> Function();

/// The agent, scripted at the http seam: canned rounds go out in order,
/// every request body is recorded for assertions.
class AgentStub() {
  final MockClient client = MockClient();
  final requests = <Map<String, dynamic>>[];
  final _rounds = <Round>[];

  /// The endpoint the stub answers on; any URL works, it never leaves the
  /// process.
  static final Uri endpoint = Uri.parse(
    'https://agent.test/api/advance-session',
  );

  /// An [AgentClient] talking to this stub.
  AgentClient get agentClient =>
      AgentClient(httpClient: client, endpoint: endpoint);

  /// The last request body, decoded.
  Map<String, dynamic> get lastRequest => requests.last;

  /// Queues the next rounds, served first-in first-out.
  void script(List<Round> rounds) {
    _rounds.addAll(rounds);
    when(client.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((invocation) {
          requests.add(
            jsonDecode(invocation.namedArguments[#body] as String)
                as Map<String, dynamic>,
          );
          if (_rounds.isEmpty) {
            throw StateError('agent stub script exhausted');
          }
          return _rounds.removeAt(0)();
        });
  }
}

/// The agent asks [question]; the transcript and signature are what the
/// client must echo on the next round.
Round awaiting({
  required String toolCallId,
  required AskQuestion question,
  String signature = 'sig',
  List<Object?> transcript = const ['round'],
}) =>
    () async => _json({
      'status': 'awaiting_answer',
      'transcript': transcript,
      'signature': signature,
      'promptId': 'session/v1',
      'pending': {'toolCallId': toolCallId, 'question': question.toJson()},
    });

/// The agent finished with [summary] and the recorded [answers].
Round completed({
  required String summary,
  required Map<String, Answer> answers,
}) =>
    () async => _json({
      'status': 'completed',
      'transcript': const ['round', 'round'],
      'signature': 'final',
      'promptId': 'session/v1',
      'entry': {
        'summary': summary,
        'answers': answers.map((id, answer) => MapEntry(id, answer.toJson())),
      },
    });

/// The server refused the round with [statusCode] and [message].
Round refused(int statusCode, String message) =>
    () async => _response({'error': message}, statusCode);

/// A raw server response, for bodies that are not the JSON envelope.
Round raw(String body, int statusCode) =>
    () async => http.Response.bytes(utf8.encode(body), statusCode);

/// The network failed before any response.
Round unreachable() =>
    () async => throw http.ClientException('Connection refused');

/// [round], but only after [delay] — long enough to observe the in-flight
/// state before `pumpAndSettle` runs the clock forward.
Round delayed(Round round, [Duration delay = const Duration(seconds: 1)]) =>
    () => Future<http.Response>.delayed(delay, round);

http.Response _json(Map<String, Object?> body) => _response(body, 200);

// Mirrors the server: `application/json` with no charset, UTF-8 bytes.
http.Response _response(Map<String, Object?> body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
