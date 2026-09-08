part of 'auth_bloc.dart';

/// Where sign-in stands; the screen renders exactly one step per state.
@freezed
sealed class AuthState with _$AuthState {
  /// Nobody is signed in; the email step, with the last [error] if any.
  const factory signedOut({String? error}) = AuthSignedOut;

  /// A code is on its way to [email].
  const factory requestingCode({required String email}) = AuthRequestingCode;

  /// [email] has a code to type in, with the last [error] if any.
  const factory codeSent({required String email, String? error}) = AuthCodeSent;

  /// The code for [email] is being checked.
  const factory verifying({required String email}) = AuthVerifying;

  /// [userId] is signed in.
  const factory signedIn({required String userId}) = AuthSignedIn;
}
