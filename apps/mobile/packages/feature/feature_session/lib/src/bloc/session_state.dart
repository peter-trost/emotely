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

  /// The last step failed for [reason]; the screen words it and offers the
  /// way out: a retry, or a fresh session when retrying cannot work.
  const factory failure({required SessionFailureReason reason}) =
      SessionFailure;
}

/// Why a session step failed, as the user needs to know it. The bloc names
/// the reason, the screen owns the words, so every message is localizable
/// and no server text ever reaches a screen.
enum SessionFailureReason() {
  /// No answer from the agent at all: offline, timed out, or not the agent.
  unreachable,

  /// The agent's model is unavailable; waiting is what helps.
  modelUnavailable,

  /// The agent refused the round for a reason retrying may fix.
  refused,

  /// The agent will never continue this session (its transcript is not one
  /// the agent signed, or it is past the message cap): only a fresh session
  /// helps.
  cannotContinue,

  /// The finished entry could not be filed.
  entrySaveFailed,

  /// The unfinished session could not be read back.
  sessionReadFailed,
}
