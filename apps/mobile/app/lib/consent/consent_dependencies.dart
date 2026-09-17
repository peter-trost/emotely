import 'package:emotely/consent/bloc/consent_bloc.dart';
import 'package:get_it/get_it.dart';

/// The consent feature's registrations: its bloc, a fresh one per owner.
void registerConsent(GetIt getIt) => getIt.registerFactory(
  () => ConsentBloc(repository: getIt(), analytics: getIt(), errors: getIt()),
);
