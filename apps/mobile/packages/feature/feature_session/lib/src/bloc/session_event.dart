part of 'session_bloc.dart';

/// What the session screen can ask of [SessionBloc].
@freezed
sealed class SessionEvent with _$SessionEvent {
  /// Begin a fresh session — or, with [resume], pick the stored one up
  /// where it was left. Only the wish travels: the bloc reads the stored
  /// round back itself, so a session discarded elsewhere in the meantime
  /// starts fresh rather than resuming a copy.
  const factory started({@Default(false) bool resume}) = SessionStarted;

  /// Submit the widget's answer to the pending question.
  const factory answered(Answer answer) = SessionAnswered;

  /// Repeat the round that failed.
  const factory retried() = SessionRetried;
}
