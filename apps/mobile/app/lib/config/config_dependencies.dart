import 'package:emotely/config/bloc/config_bloc.dart';
import 'package:get_it/get_it.dart';

/// The startup gate's registrations: its bloc, which compares the server's
/// minimum against [appVersion] — a build-time value the app hands in, like
/// every other configuration.
void registerConfig(GetIt getIt, {required String appVersion}) =>
    getIt.registerFactory(
      () => ConfigBloc(
        client: getIt(),
        appVersion: appVersion,
        analytics: getIt(),
        errors: getIt(),
      ),
    );
