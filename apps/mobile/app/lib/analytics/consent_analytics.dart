import 'package:emotely/consent/consent_text.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Consent analytics, content-free by construction like the rest (ADR 0005).
///
/// What leaves the device is that a decision was made and which wording it
/// answered — never a word of what the user wrote, and never anything about
/// the user beyond the id PostHog already has. The version is what makes
/// these events worth having: it says how many people were asked again after
/// a wording change, and how many said no.
///
/// The methods take no arguments at all, so there is nothing a caller could
/// pass that should not go out.
class const ConsentAnalytics({required final Posthog posthog}) {
  /// The user gave explicit consent, and the server recorded it.
  Future<void> consentGranted() => posthog.capture(
    eventName: 'consent_granted',
    properties: const {'version': consentVersion},
  );

  /// The user withdrew their consent (Art. 7 (3)).
  Future<void> consentWithdrawn() => posthog.capture(
    eventName: 'consent_withdrawn',
    properties: const {'version': consentVersion},
  );

  /// The user was asked and said no. Nothing was written to the server, but
  /// how often this happens is the one number that says whether the wording
  /// is frightening people off.
  Future<void> consentDeclined() => posthog.capture(
    eventName: 'consent_declined',
    properties: const {'version': consentVersion},
  );
}
