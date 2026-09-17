part of 'config_bloc.dart';

/// What can happen to the startup gate.
@freezed
sealed class ConfigEvent with _$ConfigEvent {
  /// Read the config. Also the retry: the screen re-adds it after a failure.
  const factory loaded() = ConfigLoaded;
}
