import 'package:feature_auth/src/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// The auth feature's registrations: its bloc. A factory like every bloc;
/// the app creates the one instance it holds above every screen.
///
/// [passwordAccounts] are addresses that sign in with a password as the
/// review accounts do, on top of them; the app decides which (none in a
/// release build).
void registerAuth(GetIt getIt, {Set<String> passwordAccounts = const {}}) =>
    getIt.registerFactory(
      () => AuthBloc(
        supabase: getIt(),
        analytics: getIt(),
        errors: getIt(),
        passwordAccounts: passwordAccounts,
      ),
    );
