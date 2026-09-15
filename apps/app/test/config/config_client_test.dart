import 'package:emotely/config/config_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group(ConfigClient, () {
    test('reads the minimum and the store link the server serves', () async {
      final stub = ConfigStub()
        ..serves(minAppVersion: '2.1.0', storeUrl: 'https://store.test/x');

      final config = await stub.configClient.fetch();

      expect(config.minAppVersion, '2.1.0');
      expect(config.storeUrl, 'https://store.test/x');
    });

    test('names the status code when the server refuses', () async {
      final stub = ConfigStub()..script([configRefused(503)]);

      await expectLater(
        stub.configClient.fetch(),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('503'),
          ),
        ),
      );
    });

    test('reports itself with its message', () {
      // PostHog records an exception's toString(); this one is written here
      // and carries no journal content, so it goes out as it is.
      expect(const ConfigException('nope').toString(), 'ConfigException: nope');
    });
  });
}
