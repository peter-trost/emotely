part of 'account_bloc.dart';

/// What the account screen can ask of [AccountBloc].
@freezed
sealed class AccountEvent with _$AccountEvent {
  /// Delete the account and everything in it; the user has confirmed.
  const factory deletionRequested() = AccountDeletionRequested;

  /// Open the mail app on a message to us. An event rather than a call from
  /// the widget because the mail carries the build, which is a dependency,
  /// and a widget reads the container only for its bloc and its navigator
  /// (ADR 0015).
  const factory feedbackRequested() = AccountFeedbackRequested;
}
