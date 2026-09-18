part of 'journal_bloc.dart';

/// What the journal screen shows.
@freezed
sealed class JournalState with _$JournalState {
  /// The journal is being read.
  const factory loading() = JournalLoading;

  /// The [entries], newest first, and the session to continue if any.
  const factory ready({
    required List<EntryRecord> entries,
    OpenSession? openSession,
  }) = JournalReady;

  /// The journal could not be read; the screen offers a retry.
  const factory failure() = JournalFailure;
}
