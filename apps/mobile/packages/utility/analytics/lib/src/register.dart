import 'package:analytics/src/auth_analytics.dart';
import 'package:analytics/src/consent_analytics.dart';
import 'package:analytics/src/error_reporter.dart';
import 'package:analytics/src/journal_analytics.dart';
import 'package:analytics/src/session_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Registers every event builder and the error reporter as singletons over
/// the one [posthog] instance — the seam a test replaces with its spy.
/// [consentVersion] names the wording the app currently asks consent for.
void registerAnalytics(
  GetIt getIt, {
  required Posthog posthog,
  required String consentVersion,
}) {
  getIt
    ..registerSingleton(SessionAnalytics(posthog: posthog))
    ..registerSingleton(AuthAnalytics(posthog: posthog))
    ..registerSingleton(JournalAnalytics(posthog: posthog))
    ..registerSingleton(
      ConsentAnalytics(posthog: posthog, version: consentVersion),
    )
    ..registerSingleton(ErrorReporter(posthog: posthog));
}
