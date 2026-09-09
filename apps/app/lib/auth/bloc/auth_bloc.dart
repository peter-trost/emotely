import 'dart:async';

import 'package:emotely/analytics/auth_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// gotrue has its own AuthState (the stream event); ours is the bloc state.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

/// Who is signed in, and the two-step email code sign-in that gets there:
/// request a code for an email, then verify it. Supabase Auth owns the
/// session (persistence, refresh); this bloc mirrors it into UI state and
/// tells PostHog who the user is.
class AuthBloc({
  required final SupabaseClient _supabase,
  required final AuthAnalytics _analytics,
}) extends Bloc<AuthEvent, AuthState> {
  this : super(_initial(_supabase.auth.currentSession)) {
    on<AuthCodeRequested>(_onCodeRequested);
    on<AuthCodeSubmitted>(_onCodeSubmitted);
    on<AuthEmailChangeRequested>(_onEmailChangeRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthSessionChanged>(_onSessionChanged);
    if (state case AuthSignedIn(:final userId)) {
      unawaited(_analytics.identify(userId: userId));
    }
    _sessionChanges = _supabase.auth.onAuthStateChange.listen(
      (change) => add(AuthEvent.sessionChanged(change.session?.user.id)),
      // A failed background refresh is reported here; the SDK keeps the
      // session until it really expires and signs out through the stream
      // then, so there is nothing to do with the error itself.
      onError: (Object _, StackTrace _) {},
    );
  }

  late final StreamSubscription<void> _sessionChanges;

  static AuthState _initial(Session? session) => session == null
      ? const AuthState.signedOut()
      : AuthState.signedIn(userId: session.user.id);

  Future<void> _onCodeRequested(
    AuthCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.requestingCode(email: event.email));
    unawaited(_analytics.codeRequested());
    try {
      await _supabase.auth.signInWithOtp(email: event.email);
      emit(AuthState.codeSent(email: event.email));
    } on Exception catch (error) {
      unawaited(_analytics.codeRequestFailed());
      emit(
        AuthState.signedOut(
          error: _describe(error, fallback: couldNotSendMessage),
        ),
      );
    }
  }

  Future<void> _onCodeSubmitted(
    AuthCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state case AuthCodeSent(:final email)) {
      emit(AuthState.verifying(email: email));
      try {
        final response = await _supabase.auth.verifyOTP(
          email: email,
          token: event.code,
          type: OtpType.email,
        );
        // Supabase answers 200 without a session for a few flows this app
        // never starts (two-step email changes); here it can only mean the
        // code did not sign anyone in.
        if (response.session case final session?) {
          unawaited(_analytics.signedIn());
          _signedIn(session.user.id, emit);
        } else {
          _rejected(email, wrongCodeMessage, emit);
        }
      } on Exception catch (error) {
        _rejected(email, _describe(error, fallback: wrongCodeMessage), emit);
      }
    }
  }

  void _onEmailChangeRequested(
    AuthEmailChangeRequested event,
    Emitter<AuthState> emit,
  ) => emit(const AuthState.signedOut());

  /// Ends the session on this device. The SDK drops it locally first and
  /// reports that on its stream, which is what moves the UI; whether the
  /// server-side revocation then succeeds changes nothing here.
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _supabase.auth.signOut();
    } on Exception {
      // Already signed out locally; see above.
    }
    unawaited(_analytics.signedOut());
  }

  /// Supabase's own view of the session, which wins: a sign-out, an expiry
  /// or a deleted account ends the signed-in state wherever the UI is.
  void _onSessionChanged(AuthSessionChanged event, Emitter<AuthState> emit) {
    switch (event.userId) {
      case null:
        if (state is AuthSignedIn) {
          emit(const AuthState.signedOut());
        }
      case final userId:
        if (state != AuthState.signedIn(userId: userId)) {
          _signedIn(userId, emit);
        }
    }
  }

  void _rejected(String email, String error, Emitter<AuthState> emit) {
    unawaited(_analytics.codeRejected());
    emit(AuthState.codeSent(email: email, error: error));
  }

  void _signedIn(String userId, Emitter<AuthState> emit) {
    unawaited(_analytics.identify(userId: userId));
    emit(AuthState.signedIn(userId: userId));
  }

  /// User-facing copy for the failures a sign-in can hit; the raw message
  /// never reaches the screen. Anything Supabase refused that is not the
  /// rate limit is the step's own [fallback].
  static String _describe(Exception error, {required String fallback}) =>
      switch (error) {
        AuthApiException(code: 'over_email_send_rate_limit') =>
          tooManyCodesMessage,
        AuthRetryableFetchException() => unreachableMessage,
        _ => fallback,
      };

  static const tooManyCodesMessage =
      'Too many codes were requested. Please try again later.';
  static const couldNotSendMessage =
      'Could not send a code to that email. Check the address and try again.';
  static const wrongCodeMessage =
      'That code is wrong or has expired. Request a new one if needed.';
  static const unreachableMessage = 'Could not reach the sign-in service.';

  @override
  Future<void> close() async {
    await _sessionChanges.cancel();
    await super.close();
  }
}
