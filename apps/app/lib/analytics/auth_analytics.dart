import 'package:posthog_flutter/posthog_flutter.dart';

/// Sign-in analytics, content-free by construction (ADR 0005): PostHog
/// learns the user's id (a UUID) and which step failed, never the email or
/// the code. The methods take no strings but the id, so a leak would be a
/// type error before it was a bug.
class const AuthAnalytics({required final Posthog posthog}) {
  /// The user asked for a sign-in code.
  Future<void> codeRequested() =>
      posthog.capture(eventName: 'sign_in_code_requested');

  /// Supabase refused to send a code (rate limit, outage).
  Future<void> codeRequestFailed() =>
      posthog.capture(eventName: 'sign_in_code_request_failed');

  /// The code the user typed was wrong or expired.
  Future<void> codeRejected() =>
      posthog.capture(eventName: 'sign_in_code_rejected');

  /// [userId] is the person behind this device's events, whether they just
  /// signed in or the session was restored.
  Future<void> identify({required String userId}) =>
      posthog.identify(userId: userId);

  /// The user completed a sign-in (not a restored session).
  Future<void> signedIn() => posthog.capture(eventName: 'signed_in');

  /// The user signed out: PostHog forgets who this device belongs to.
  Future<void> signedOut() async {
    await posthog.capture(eventName: 'signed_out');
    await posthog.reset();
  }
}
