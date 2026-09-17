import 'package:agent_client/agent_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerAgentClient', () {
    test('registers both clients over the clients and URLs it is given', () {
      final getIt = GetIt.asNewInstance();
      final agent = AgentStub();
      final config = ConfigStub();

      registerAgentClient(
        getIt,
        agentHttpClient: agent.client,
        configHttpClient: config.client,
        agentUrl: AgentStub.endpoint,
        configUrl: ConfigStub.endpoint,
        appVersion: '2.0.0',
        accessToken: () => 'jwt-123',
      );

      final agentClient = getIt<AgentClient>();
      expect(agentClient.httpClient, same(agent.client));
      expect(agentClient.endpoint, AgentStub.endpoint);
      expect(agentClient.appVersion, '2.0.0');
      expect(agentClient.accessToken(), 'jwt-123');
      final configClient = getIt<ConfigClient>();
      expect(configClient.httpClient, same(config.client));
      expect(configClient.endpoint, ConfigStub.endpoint);
    });

    test('registers each client once, as a singleton', () {
      final getIt = GetIt.asNewInstance();
      registerAgentClient(
        getIt,
        agentHttpClient: AgentStub().client,
        configHttpClient: ConfigStub().client,
        agentUrl: AgentStub.endpoint,
        configUrl: ConfigStub.endpoint,
        appVersion: '2.0.0',
        accessToken: () => null,
      );

      expect(getIt<AgentClient>(), same(getIt<AgentClient>()));
      expect(getIt<ConfigClient>(), same(getIt<ConfigClient>()));
    });
  });
}
