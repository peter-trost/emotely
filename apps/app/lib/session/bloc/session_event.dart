part of 'session_bloc.dart';

/// What the session screen can ask of [SessionBloc].
@freezed
sealed class SessionEvent with _$SessionEvent {
  /// Begin a fresh session.
  const factory started() = SessionStarted;

  /// Submit the widget's answer to the pending question.
  const factory answered(Answer answer) = SessionAnswered;

  /// Repeat the round that failed.
  const factory retried() = SessionRetried;
}
