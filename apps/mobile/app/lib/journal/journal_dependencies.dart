import 'package:emotely/journal/bloc/journal_bloc.dart';
import 'package:get_it/get_it.dart';

/// The journal feature's registrations: its bloc, a fresh one per screen.
void registerJournal(GetIt getIt) => getIt.registerFactory(
  () => JournalBloc(repository: getIt(), analytics: getIt()),
);
