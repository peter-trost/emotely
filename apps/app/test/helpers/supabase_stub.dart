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
    when(client.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((invocation) {
          final uri = invocation.positionalArguments.first as Uri;
          final raw = invocation.namedArguments[#body];
          requests.add((
            path: uri.path,
            body: raw is String && raw.isNotEmpty
                ? jsonDecode(raw) as Map<String, dynamic>
                : const {},
          ));
          final queue = _rounds[uri.path];
          if (queue == null || queue.isEmpty) {
            throw StateError('supabase stub: nothing scripted for ${uri.path}');
          }
          return queue.removeAt(0)();
        });
  }

  final client = MockClient();

  /// Every request the SDK made, as `(path, decoded body)`.
  final requests = <({String path, Map<String, dynamic> body})>[];
  final _rounds = <String, List<AuthRound>>{};

  static const url = 'https://project.supabase.test';
  static const publishableKey = 'sb_publishable_test';
  static const userId = '00000000-0000-0000-0000-00000000000a';
  static const email = 'alice@example.com';

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

  /// Queues responses per endpoint, served first-in first-out.
  void script({
    List<AuthRound> otp = const [],
    List<AuthRound> verify = const [],
    List<AuthRound> logout = const [],
  }) {
    _rounds.putIfAbsent('/auth/v1/otp', () => []).addAll(otp);
    _rounds.putIfAbsent('/auth/v1/verify', () => []).addAll(verify);
    _rounds.putIfAbsent('/auth/v1/logout', () => []).addAll(logout);
  }

  /// Starts the client with a live session, as after a restored sign-in.
  Future<void> signedIn() =>
      supabase.auth.recoverSession(jsonEncode(session()));

  /// The bodies the app posted to [path], in order.
  List<Map<String, dynamic>> bodies(String path) => [
    for (final request in requests)
      if (request.path == path) request.body,
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
