import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

import 'sign_in_robot.dart';

void main() {
  group('registerAuth', () {
    test('registers the bloc as a factory over the utilities', () async {
      final getIt = GetIt.asNewInstance();
      registerUtilitiesUnderTest(
        getIt,
        agent: AgentStub(),
        supabase: SupabaseStub(),
        analytics: AnalyticsSpy(),
      );

      registerAuth(getIt, google: SignInRobot.googleClients);

      final first = getIt<AuthBloc>();
      final second = getIt<AuthBloc>();
      expect(first, isNot(same(second)));
      await first.close();
      await second.close();
    });
  });
}
