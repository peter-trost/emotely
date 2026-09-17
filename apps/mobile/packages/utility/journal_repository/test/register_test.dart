import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:journal_repository/journal_repository.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerJournalRepository', () {
    test('registers one repository over the Supabase client', () {
      final getIt = GetIt.asNewInstance();
      final supabase = SupabaseStub();

      registerJournalRepository(getIt, supabase: supabase.supabase);

      final repository = getIt<JournalRepository>();
      expect(repository.supabase, same(supabase.supabase));
      expect(repository, same(getIt<JournalRepository>()));
    });
  });
}
