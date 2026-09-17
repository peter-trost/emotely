import 'package:consent_repository/consent_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerConsentRepository', () {
    test('registers one repository for the version it is given', () {
      final getIt = GetIt.asNewInstance();
      final supabase = SupabaseStub();

      registerConsentRepository(
        getIt,
        supabase: supabase.supabase,
        version: '2026-01-01',
      );

      final repository = getIt<ConsentRepository>();
      expect(repository.supabase, same(supabase.supabase));
      expect(repository.version, '2026-01-01');
      expect(repository, same(getIt<ConsentRepository>()));
    });
  });
}
