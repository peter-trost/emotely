import 'package:emotely/session/bloc/session_bloc.dart';
import 'package:get_it/get_it.dart';

/// The session feature's registrations: its bloc, a fresh one per screen.
void registerSession(GetIt getIt) => getIt.registerFactory(
  () => SessionBloc(
    agentClient: getIt(),
    analytics: getIt(),
    errors: getIt(),
    repository: getIt(),
  ),
);
