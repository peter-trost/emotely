part of 'account_bloc.dart';

/// What the account screen can ask of [AccountBloc].
@freezed
sealed class AccountEvent with _$AccountEvent {
  /// Delete the account and everything in it; the user has confirmed.
  const factory deletionRequested() = AccountDeletionRequested;
}
