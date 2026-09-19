import 'package:posthog_flutter/posthog_flutter.dart';

/// Sign-in analytics, content-free by construction (ADR 0005): PostHog
/// learns the user's id (a UUID), which step failed, and one boolean saying
/// whether the account is ours — never the email or the code. The methods
/// take no strings but the id, so a leak would be a type error before it was
/// a bug.
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

  /// A review account's password sign-in did not go through (wrong
  /// password, outage).
  Future<void> passwordFailed() =>
      posthog.capture(eventName: 'sign_in_password_failed');

  /// [userId] is the person behind this device's events, whether they just
  /// signed in or the session was restored.
  ///
  /// [internal] says whether this is one of our own accounts, and is the one
  /// thing PostHog learns about the address: the caller derives the boolean
  /// from the email's domain, and the email itself never reaches this class
  /// (ADR 0005). It rides along as the person property
  /// `$internal_or_test_user`, which the project's default "filter out
  /// internal and test users" cohort matches on, so the founder's test
  /// account, the store reviewers and Google's pre-launch crawler drop out of
  /// every dashboard by themselves.
  ///
  /// Sent on every identify, true or false, so a person's flag is explicit
  /// rather than absent — an unset property is not a `false` to a cohort.
  Future<void> identify({required String userId, required bool internal}) =>
      posthog.identify(
        userId: userId,
        userProperties: {r'$internal_or_test_user': internal},
      );

  /// The user completed a sign-in (not a restored session).
  Future<void> signedIn() => posthog.capture(eventName: 'signed_in');

  /// The user signed out: PostHog forgets who this device belongs to.
  Future<void> signedOut() async {
    await posthog.capture(eventName: 'signed_out');
    await posthog.reset();
  }

  /// The user deleted their account: PostHog forgets who this device
  /// belonged to.
  Future<void> accountDeleted() async {
    await posthog.capture(eventName: 'account_deleted');
    await posthog.reset();
  }
}
