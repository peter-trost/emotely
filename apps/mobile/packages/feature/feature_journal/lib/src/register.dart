import 'package:feature_journal/src/bloc/journal_bloc.dart';
import 'package:get_it/get_it.dart';

/// The journal feature's registrations: its bloc, a fresh one per screen.
/// The app registers a `JournalNavigator` implementation itself; it is the
/// app's to provide, not this feature's.
void registerJournal(GetIt getIt) => getIt.registerFactory(
  () => JournalBloc(repository: getIt(), consent: getIt(), analytics: getIt()),
);
