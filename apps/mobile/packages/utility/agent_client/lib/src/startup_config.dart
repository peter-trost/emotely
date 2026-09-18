import 'package:freezed_annotation/freezed_annotation.dart';

part 'startup_config.freezed.dart';
part 'startup_config.g.dart';

/// What `GET /api/config` answers with, read once at startup.
///
/// Both fields are required, unlike the session envelope's optionals: this is
/// the app's own gate, and a config it cannot fully read is one it must not
/// act on. Wire keys are snake_case; `build.yaml` maps the Dart names.
@freezed
abstract class StartupConfig with _$StartupConfig {
  const factory({
    /// The oldest app version the server still serves. Below it the app shows
    /// the force-update screen and cannot continue.
    required String minAppVersion,

    /// Where that screen sends the user. Server-controlled so the link can be
    /// corrected without an app release, which is the only kind of fix that
    /// reaches someone who cannot install a new app.
    required String storeUrl,
  }) = _StartupConfig;

  factory fromJson(Map<String, dynamic> json) => _$StartupConfigFromJson(json);

  /// The wire keys `fromJson` cannot do without. Taken from the encoder so
  /// they cannot drift from it: both fields are required, so everything
  /// `toJson` writes is something the decoder needs.
  static final Set<String> wireKeys = const StartupConfig(
    minAppVersion: '0.0.0',
    storeUrl: 'https://example.invalid',
  ).toJson().keys.toSet();
}
