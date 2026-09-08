import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mocks.mocks.dart';

/// One scripted Supabase Auth response.
typedef AuthRound = Future<http.Response> Function();

/// Supabase, scripted at the http seam like the agent: canned responses per
/// auth endpoint, every request recorded. The [SupabaseClient] it hands out
/// is the real SDK, so session handling, token exposure and auth events are
/// the production code paths.
class SupabaseStub() {
  this {
    // Auth (gotrue) posts through the client's verb methods ...
    when(client.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer(
          (invocation) => _serve(
            'POST',
            invocation.positionalArguments.first as Uri,
            invocation.namedArguments[#body],
          ),
        );
    // ... while the data API (postgrest) builds a request and sends it.
    when(client.send(any)).thenAnswer((invocation) async {
      final request = invocation.positionalArguments.first as http.BaseRequest;
      final response = await _serve(
        request.method,
        request.url,
        request is http.Request ? request.body : null,
      );
      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    });
  }

  Future<http.Response> _serve(String method, Uri uri, Object? raw) {
    final key = '$method ${uri.path}';
    requests.add(
      RecordedRequest(
        method: method,
        path: uri.path,
        query: uri.queryParameters,
        body: raw is String && raw.isNotEmpty
            ? jsonDecode(raw) as Object
            : null,
      ),
    );
    final queue = _rounds[key];
    if (queue != null && queue.isNotEmpty) {
      return queue.removeAt(0)();
    }
    final fallback = _defaults[key];
    if (fallback == null) {
      throw StateError('supabase stub: nothing scripted for $key');
    }
    return fallback();
  }

  final client = MockClient();

  /// Every request the SDK made: method, path, query and decoded body.
  final requests = <RecordedRequest>[];
  final _rounds = <String, List<AuthRound>>{};
  final _defaults = <String, AuthRound>{};

  static const url = 'https://project.supabase.test';
  static const publishableKey = 'sb_publishable_test';
  static const userId = '00000000-0000-0000-0000-00000000000a';
  static const email = 'alice@example.com';
  static const sessionId = '20000000-0000-0000-0000-000000000001';
  static const entryId = '30000000-0000-0000-0000-000000000001';

  /// The token the app must forward to the agent once signed in.
  static final accessToken = jwt(sub: userId);

  /// The real client, talking to this stub; no persistence, no refresh
  /// timer, no deep links.
  late final supabase = SupabaseClient(
    url,
    publishableKey,
    httpClient: client,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  /// Queues auth responses per endpoint, served first-in first-out.
  void script({
    List<AuthRound> otp = const [],
    List<AuthRound> verify = const [],
    List<AuthRound> logout = const [],
  }) {
    rest('POST /auth/v1/otp', otp);
    rest('POST /auth/v1/verify', verify);
    rest('POST /auth/v1/logout', logout);
  }

  /// Queues responses for one `METHOD /path`, e.g. `POST /rest/v1/sessions`;
  /// scripted rounds are served before any [always] fallback.
  void rest(String endpoint, List<AuthRound> rounds) =>
      _rounds.putIfAbsent(endpoint, () => []).addAll(rounds);

  /// Answers every unscripted request to [endpoint] with [round].
  void always(String endpoint, AuthRound round) => _defaults[endpoint] = round;

  /// A journal that accepts everything: sessions are created as [sessionId],
  /// updated and closed without complaint. What most session tests want.
  void journalWorks({String sessionId = SupabaseStub.sessionId}) {
    always('DELETE /rest/v1/sessions', rowsChanged());
    always('POST /rest/v1/sessions', rowCreated(sessionId));
    always('PATCH /rest/v1/sessions', rowsChanged());
    always('POST /rest/v1/rpc/complete_session', rpcReturned(entryId));
  }

  /// Starts the client with a live session, as after a restored sign-in.
  Future<void> signedIn() =>
      supabase.auth.recoverSession(jsonEncode(session()));

  /// The requests the app made to `METHOD /path`, in order.
  List<RecordedRequest> to(String endpoint) => [
    for (final request in requests)
      if ('${request.method} ${request.path}' == endpoint) request,
  ];

  /// The JSON object bodies the app posted to [path], in order.
  List<Map<String, dynamic>> bodies(String path) => [
    for (final request in requests)
      if (request.path == path && request.body is Map<String, dynamic>)
        request.body! as Map<String, dynamic>,
  ];

  /// A session as Supabase Auth returns it after a verified code.
  static Map<String, Object?> session({String sub = userId}) => {
    'access_token': jwt(sub: sub),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-$sub',
    'user': {
      'id': sub,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email,
      'created_at': '2026-09-01T00:00:00Z',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
    },
  };

  /// A token shaped like Supabase's (the SDK reads `exp` from it, so it
  /// expires far in the future); the signature is never checked on the
  /// device. Deterministic per [sub], so tests can compare it.
  static String jwt({required String sub}) {
    final header = {'alg': 'ES256', 'typ': 'JWT'};
    final claims = {
      'sub': sub,
      'role': 'authenticated',
      'aud': 'authenticated',
      'exp': DateTime.utc(2099).millisecondsSinceEpoch ~/ 1000,
    };
    return [header, claims].map(_segment).followedBy(['signature']).join('.');
  }

  static String _segment(Map<String, Object> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
}

/// Supabase accepted the email and sent a code.
AuthRound codeSent() =>
    () async => _json(const {}, 200);

/// Supabase accepted the code and granted a session.
AuthRound sessionGranted({String sub = SupabaseStub.userId}) =>
    () async => _json(SupabaseStub.session(sub: sub), 200);

/// Supabase refused with its error envelope, e.g. `otp_expired`.
AuthRound authRefused({
  required int statusCode,
  required String errorCode,
  required String message,
}) =>
    () async => _json({
      'code': statusCode,
      'error_code': errorCode,
      'msg': message,
    }, statusCode);

/// The session was ended server-side.
AuthRound signedOut() =>
    () async => http.Response('', 204);

/// Supabase is unreachable.
AuthRound authUnreachable() =>
    () async => throw http.ClientException('Connection refused');

/// [round], but only after [delay] — long enough to observe the in-flight
/// state before `pumpAndSettle` runs the clock forward.
AuthRound delayedAuth(
  AuthRound round, [
  Duration delay = const Duration(seconds: 1),
]) =>
    () => Future<http.Response>.delayed(delay, round);

http.Response _json(Map<String, Object?> body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );

/// Supabase accepted the request but granted no session.
AuthRound sessionWithheld() =>
    () async => _json(const {}, 200);

/// One request the SDK made, as the stub saw it.
class const RecordedRequest({
  required final String method,
  required final String path,
  required final Map<String, String> query,
  required final Object? body,
});

/// The data API created a row with [id] (`insert(...).select('id').single()`).
AuthRound rowCreated(String id) =>
    () async => _json({'id': id}, 201);

/// The data API changed rows and returned nothing (`Prefer: return=minimal`).
AuthRound rowsChanged() =>
    () async => http.Response('', 204);

/// A database function returned [value].
AuthRound rpcReturned(Object? value) =>
    () async => http.Response.bytes(
      utf8.encode(jsonEncode(value)),
      200,
      headers: const {'content-type': 'application/json'},
    );

/// The data API refused; postgrest raises it as a `PostgrestException`.
/// 4xx on purpose: postgrest retries 5xx on idempotent methods, which would
/// eat several scripted rounds for one failure.
AuthRound restRefused({int statusCode = 409, String message = 'refused'}) =>
    () async => _json({'code': 'XX000', 'message': message}, statusCode);
