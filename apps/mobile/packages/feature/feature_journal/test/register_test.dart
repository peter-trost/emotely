import 'package:feature_journal/feature_journal.dart';
import 'package:feature_journal/src/bloc/journal_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerJournal', () {
    test('registers the bloc as a factory over the utilities', () async {
      final getIt = GetIt.asNewInstance();
      registerUtilitiesUnderTest(
        getIt,
        agent: AgentStub(),
        supabase: SupabaseStub(),
        analytics: AnalyticsSpy(),
      );

      registerJournal(getIt);

      final first = getIt<JournalBloc>();
      final second = getIt<JournalBloc>();
      expect(first, isNot(same(second)));
      await first.close();
      await second.close();
    });
  });
}
