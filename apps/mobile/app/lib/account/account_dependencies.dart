import 'package:emotely/account/bloc/account_bloc.dart';
import 'package:get_it/get_it.dart';

/// The account feature's registrations: its bloc, a fresh one per screen.
void registerAccount(GetIt getIt) => getIt.registerFactory(
  () => AccountBloc(supabase: getIt(), analytics: getIt(), errors: getIt()),
);
