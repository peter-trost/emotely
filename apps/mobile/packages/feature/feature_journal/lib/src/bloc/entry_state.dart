part of 'entry_bloc.dart';

/// Where the entry stands: being read, read, or not readable.
///
/// No generated `toString`: `ready` carries the entry, which is journal
/// content, and a `BlocObserver` or an error log printing a transition must
/// never print that (ADR 0005).
@Freezed(toStringOverride: false)
sealed class EntryState with _$EntryState {
  const factory loading() = EntryLoading;

  const factory ready({required EntryRecord record}) = EntryReady;

  /// The entry could not be read, or the journal holds no such entry.
  const factory failure() = EntryFailure;
}
