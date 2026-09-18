part of 'session_bloc.dart';

/// Where the session is; the screen renders exactly one widget per state.
@freezed
sealed class SessionState with _$SessionState {
  /// Nothing has happened yet.
  const factory initial() = SessionInitial;

  /// A round is in flight; [answered] questions are recorded so far.
  const factory loading({required int answered}) = SessionLoading;

  /// The agent asked [pending]; [answered] questions came before it.
  const factory awaitingAnswer({
    required PendingQuestion pending,
    required int answered,
  }) = SessionAwaitingAnswer;

  /// The session is over: the [entry], plus every question that was asked
  /// so answers can be shown with their question text.
  const factory completed({
    required JournalEntry entry,
    required Map<String, AskQuestion> questions,
  }) = SessionCompleted;

  /// The last round failed with [message]; the screen offers a retry.
  const factory failure({required String message}) = SessionFailure;
}
