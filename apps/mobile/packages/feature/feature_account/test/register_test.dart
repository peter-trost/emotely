import 'package:feature_account/feature_account.dart';
import 'package:feature_account/src/account/bloc/account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerAccount', () {
    test('registers both blocs as factories over the utilities', () async {
      final getIt = GetIt.asNewInstance();
      registerUtilitiesUnderTest(
        getIt,
        agent: AgentStub(),
        supabase: SupabaseStub(),
        analytics: AnalyticsSpy(),
      );

      registerAccount(getIt);

      final account = getIt<AccountBloc>();
      final consent = getIt<ConsentBloc>();
      expect(account, isNot(same(getIt<AccountBloc>())));
      expect(consent, isNot(same(getIt<ConsentBloc>())));
      await account.close();
      await consent.close();
    });
  });
}
