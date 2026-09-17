import 'dart:convert';

import 'package:agent_client/agent_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:testing/testing.dart';

/// One scripted answer to `GET /api/config`.
typedef ConfigRound = Future<http.Response> Function();

/// The startup config endpoint, scripted at the http seam.
///
/// Serves a config the running build satisfies unless a test says otherwise,
/// so every existing test keeps reaching the app behind the gate.
class ConfigStub() {
  final client = MockClient();
  var _calls = 0;
  final _rounds = <ConfigRound>[];

  /// Every URL the app asked for, in order.
  final requested = <Uri>[];

  /// How many times the app asked. The gate must ask once per launch, and
  /// once more per retry — never once per session round.
  int get calls => _calls;

  static final Uri endpoint = Uri.parse('https://agent.test/api/config');

  /// The minimum the running build meets; the stub agent reports `1.2.3`.
  static const minAppVersion = '1.0.0';
  static const storeUrl = 'https://store.test/emotely';

  /// A client talking to this stub. [platform] is fixed so tests do not
  /// depend on the host they run on.
  ConfigClient get configClient =>
      ConfigClient(httpClient: client, endpoint: endpoint, platform: platform);

  /// What the client reports itself as; overridable per test.
  var platform = 'ios';

  /// Queues the answers, served first-in first-out; the last one repeats so
  /// a test need not script a round per retry.
  void script(List<ConfigRound> rounds) {
    _rounds
      ..clear()
      ..addAll(rounds);
    when(client.get(any, headers: anyNamed('headers')))
        .thenAnswer((invocation) {
          _calls++;
          requested.add(invocation.positionalArguments.first as Uri);
          return _rounds.length == 1 ? _rounds.first() : _rounds.removeAt(0)();
        });
  }

  /// The default: a config this build satisfies.
  void serves({
    String minAppVersion = ConfigStub.minAppVersion,
    String storeUrl = ConfigStub.storeUrl,
  }) =>
      script([servesConfig(minAppVersion: minAppVersion, storeUrl: storeUrl)]);
}

/// The server serves [minAppVersion] and points at [storeUrl].
ConfigRound servesConfig({
  String minAppVersion = ConfigStub.minAppVersion,
  String storeUrl = ConfigStub.storeUrl,
}) =>
    () async => _response({
      'min_app_version': minAppVersion,
      'store_url': storeUrl,
    }, 200);

/// The server refused with [statusCode].
ConfigRound configRefused(int statusCode) =>
    () async => _response({'error': 'nope'}, statusCode);

/// The network failed before any response.
ConfigRound configUnreachable() =>
    () async => throw http.ClientException('Connection refused');

/// A body the app cannot read as a config.
ConfigRound configMalformed([String body = 'not json']) =>
    () async => http.Response.bytes(utf8.encode(body), 200);

/// [round], but only after [delay] — long enough to observe the gate's
/// checking screen before `pumpAndSettle` runs the clock forward.
ConfigRound configDelayed(
  ConfigRound round, [
  Duration delay = const Duration(seconds: 1),
]) =>
    () => Future<http.Response>.delayed(delay, round);

// Mirrors the server: `application/json` with no charset, UTF-8 bytes.
http.Response _response(Map<String, Object?> body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
