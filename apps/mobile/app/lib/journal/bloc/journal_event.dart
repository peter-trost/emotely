part of 'journal_bloc.dart';

/// What the journal screen can ask of [JournalBloc].
@freezed
sealed class JournalEvent with _$JournalEvent {
  /// Read the journal (again).
  const factory loaded() = JournalLoaded;

  /// Drop the unfinished session.
  const factory sessionDiscarded() = JournalSessionDiscarded;
}
