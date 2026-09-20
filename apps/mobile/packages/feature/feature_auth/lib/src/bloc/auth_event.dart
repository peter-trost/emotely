part of 'auth_bloc.dart';

/// What the sign-in screen, and Supabase itself, can tell [AuthBloc].
///
/// No generated `toString`: the variants carry the email, the code and a
/// password, and a `BlocObserver` or an error log printing an event must
/// never print those (ADR 0005). `Instance of 'AuthPasswordSubmitted'` is
/// all a transition ever shows.
@Freezed(toStringOverride: false)
sealed class AuthEvent with _$AuthEvent {
  /// Continue with [email]: a sign-in code is sent to it, unless it is a
  /// review account, which is asked for its password instead.
  const factory emailSubmitted(String email) = AuthEmailSubmitted;

  /// Verify the [code] the user received.
  const factory codeSubmitted(String code) = AuthCodeSubmitted;

  /// Check the [password] of the review account at the password step.
  const factory passwordSubmitted(String password) = AuthPasswordSubmitted;

  /// Back to the email step.
  const factory emailChangeRequested() = AuthEmailChangeRequested;

  /// Sign out of this device.
  const factory signOutRequested() = AuthSignOutRequested;

  /// Supabase reports a session for [userId] with sign-in address [email],
  /// or none. Mirrors the SDK's auth stream; the UI never sends it. The
  /// address rides along only so the bloc can derive PostHog's
  /// internal-account flag from its domain; it reaches neither the state nor
  /// the screen.
  const factory sessionChanged(String? userId, String? email) =
      AuthSessionChanged;
}
