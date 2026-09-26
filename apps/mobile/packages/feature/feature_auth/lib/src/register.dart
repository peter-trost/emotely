import 'package:feature_auth/src/bloc/auth_bloc.dart';
import 'package:feature_auth/src/providers/provider_sign_in.dart';
import 'package:get_it/get_it.dart';

/// The auth feature's registrations: the provider sheets, one per process
/// (google_sign_in takes a single `initialize`), set up with the app's
/// [google] clients; and its bloc, a factory like every bloc, of which the
/// app creates the one instance it holds above every screen.
void registerAuth(GetIt getIt, {required GoogleClientIds google}) => getIt
  ..registerSingleton(ProviderSignIn(google: google))
  ..registerFactory(
    () => AuthBloc(
      supabase: getIt(),
      analytics: getIt(),
      errors: getIt(),
      providers: getIt(),
    ),
  );
