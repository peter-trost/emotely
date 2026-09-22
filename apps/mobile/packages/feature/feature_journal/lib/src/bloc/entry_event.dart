part of 'entry_bloc.dart';

/// What the entry screen can ask of [EntryBloc].
@freezed
sealed class EntryEvent with _$EntryEvent {
  /// Read the entry [entryId] back, or read it again.
  const factory loaded(String entryId) = EntryLoaded;
}
