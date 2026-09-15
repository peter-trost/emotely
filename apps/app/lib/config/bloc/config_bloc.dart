import 'dart:async';

import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/config/config_client.dart';
import 'package:emotely/config/startup_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part 'config_bloc.freezed.dart';
part 'config_event.dart';
part 'config_state.dart';

/// The startup gate: reads the server's config once and decides whether this
/// build may run at all (#49).
///
/// It sits above everything else, including sign-in, because a build the
/// server no longer serves must be told so before it tries to do anything —
/// and because the store link the user needs comes from this same call.
class ConfigBloc({
  required final ConfigClient _client,
  required final String _appVersion,
  required final SessionAnalytics _analytics,
  required final ErrorReporter _errors,
}) extends Bloc<ConfigEvent, ConfigState> {
  this : super(const ConfigState.unknown()) {
    on<ConfigLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(ConfigLoaded event, Emitter<ConfigState> emit) async {
    // The gate shows the checking screen while this runs, so there is no
    // retry button on screen to press twice: one read is in flight at a time
    // by construction, and no re-entrancy guard is needed here.
    emit(const ConfigState.unknown());
    final StartupConfig config;
    try {
      config = await _client.fetch();
    } on ConfigException catch (error, stackTrace) {
      unawaited(_errors.configLoadFailed(error, stackTrace));
      emit(ConfigState.failure(message: error.message));
      return;
    }
    emit(
      _blocks(config)
          ? ConfigState.updateRequired(
              minAppVersion: config.minAppVersion,
              storeUrl: config.storeUrl,
            )
          : const ConfigState.ready(),
    );
  }

  /// Whether the server's minimum is newer than this build. An unparseable
  /// version on either side blocks: the gate exists to be conservative, and
  /// guessing "allowed" is the one wrong answer it must never give.
  bool _blocks(StartupConfig config) {
    final blocked = _isNewerThanThisBuild(config.minAppVersion);
    if (blocked) {
      unawaited(
        _analytics.updateRequired(
          minAppVersion: config.minAppVersion,
          appVersion: _appVersion,
        ),
      );
    }
    return blocked;
  }

  bool _isNewerThanThisBuild(String minAppVersion) {
    try {
      return Version.parse(minAppVersion) > Version.parse(_appVersion);
    } on FormatException {
      return true;
    }
  }
}
