part of 'auth_bloc.dart';

/// What the sign-in screen, and Supabase itself, can tell [AuthBloc].
@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Send a sign-in code to [email].
  const factory codeRequested(String email) = AuthCodeRequested;

  /// Verify the [code] the user received.
  const factory codeSubmitted(String code) = AuthCodeSubmitted;

  /// Back to the email step.
  const factory emailChangeRequested() = AuthEmailChangeRequested;

  /// Supabase reports a session for [userId], or none. Mirrors the SDK's
  /// auth stream; the UI never sends it.
  const factory sessionChanged(String? userId) = AuthSessionChanged;
}
