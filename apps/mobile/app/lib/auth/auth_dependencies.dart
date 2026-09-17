import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// The auth feature's registrations: its bloc. A factory like every bloc;
/// the app creates the one instance it holds above every screen.
void registerAuth(GetIt getIt) => getIt.registerFactory(
  () => AuthBloc(supabase: getIt(), analytics: getIt(), errors: getIt()),
);
