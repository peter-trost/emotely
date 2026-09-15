part of 'consent_bloc.dart';

/// What the screens can tell [ConsentBloc]. No variant carries anything the
/// user wrote — a version identifier and nothing else travels here — so the
/// generated `toString` is left alone (ADR 0005 concerns content, and there
/// is none).
@freezed
sealed class ConsentEvent with _$ConsentEvent {
  /// Read from the server whether consent stands. Sent on every start and
  /// whenever the answer may be stale.
  const factory loaded() = ConsentLoaded;

  /// The user ticked the box and pressed the button.
  const factory granted() = ConsentGranted;

  /// The user took their consent back (Art. 7 (3)).
  const factory withdrawn() = ConsentWithdrawn;

  /// The user chose not to consent. Nothing is written.
  const factory declined() = ConsentDeclined;
}
