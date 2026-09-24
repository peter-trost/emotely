import 'package:agent_client/src/agent_client.dart';
import 'package:agent_client/src/config_client.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

/// Registers the two clients as singletons — eagerly, so a bad URL fails at
/// startup and not on the first round.
///
/// The http clients are the seams a test replaces (one scripted client per
/// endpoint); production passes the same client twice, one connection pool
/// for one host. [accessToken] is read on every session round, so the token
/// the app holds *now* travels, never the one it held at registration;
/// [refreshAccessToken] renews it when the agent says it lapsed.
void registerAgentClient(
  GetIt getIt, {
  required http.Client agentHttpClient,
  required http.Client configHttpClient,
  required Uri agentUrl,
  required Uri configUrl,
  required String appVersion,
  required String? Function() accessToken,
  required Future<void> Function() refreshAccessToken,
}) {
  getIt
    ..registerSingleton(
      AgentClient(
        httpClient: agentHttpClient,
        endpoint: agentUrl,
        appVersion: appVersion,
        accessToken: accessToken,
        refreshAccessToken: refreshAccessToken,
      ),
    )
    ..registerSingleton(
      ConfigClient(httpClient: configHttpClient, endpoint: configUrl),
    );
}
