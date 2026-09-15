import 'dart:async';
import 'dart:convert';

import 'package:emotely/config/startup_config.dart';
import 'package:http/http.dart' as http;

/// Reads `GET /api/config`: what the app must know before it may run.
///
/// Unauthenticated by design. The users this call exists to block are on a
/// version the server no longer serves, and they must be told so before the
/// sign-in screen — which their build may no longer be able to drive.
class const ConfigClient({
  required final http.Client httpClient,
  required final Uri endpoint,
  final Duration timeout = defaultTimeout,
}) {
  /// Shorter than a session round: this runs before the first frame the user
  /// can act on, and a slow answer is indistinguishable from a hung one.
  static const defaultTimeout = Duration(seconds: 10);

  /// The startup config, or a thrown [ConfigException] if it cannot be had.
  /// The caller blocks on failure rather than guessing a minimum.
  Future<StartupConfig> fetch() async {
    final http.Response response;
    try {
      response = await httpClient.get(endpoint).timeout(timeout);
    } on Exception catch (error) {
      // A transport error names a host, never content — the same rule
      // `ErrorReporter.contentFree` applies to `ClientException` itself.
      throw ConfigException('Could not reach emotely: $error');
    }
    if (response.statusCode != 200) {
      throw ConfigException('emotely answered ${response.statusCode}.');
    }
    final Object? decoded;
    try {
      // Same UTF-8 care as the session client: the server sends
      // `application/json` with no charset.
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on Exception {
      // Never the error's text: a `FormatException` embeds the source it
      // choked on, which here is the response body (ADR 0005). The status
      // code above is all a debugger gets, and all it needs.
      throw const ConfigException('emotely sent a config it could not read.');
    }
    // Every key the decoder needs, present and a String, checked before it
    // runs: a missing or mistyped field inside the generated `fromJson` is a
    // `TypeError`, and an Error must not be caught (`avoid_catching_errors`).
    // A partial config is just a bad response and has to block like one, not
    // crash the app on launch. The decode itself still goes through
    // `fromJson`, so the wire names live in one place — the generated code
    // the contract test pins — and not a second time in this condition.
    if (decoded case final Map<String, dynamic> json
        when StartupConfig.wireKeys.every((key) => json[key] is String)) {
      return StartupConfig.fromJson(json);
    }
    throw const ConfigException('emotely sent a config it could not read.');
  }
}

/// The startup config could not be read. Always blocking: the app cannot tell
/// "no minimum" from "could not ask", and must not assume the friendlier one.
class const ConfigException(final String message) implements Exception {
  @override
  String toString() => 'ConfigException: $message';
}
