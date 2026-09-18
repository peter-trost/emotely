import 'package:agent_client/agent_client.dart';
import 'package:analytics/analytics.dart';
import 'package:consent_repository/consent_repository.dart';
import 'package:emotely/account/account_dependencies.dart';
import 'package:emotely/auth/auth_dependencies.dart';
import 'package:emotely/config/config_dependencies.dart';
import 'package:emotely/consent/consent_dependencies.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:emotely/journal/journal_dependencies.dart';
import 'package:emotely/session/session_dependencies.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:journal_repository/journal_repository.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one composition root (ADR 0015): every utility and every feature
/// registers into [getIt] here, in dependency order, and nowhere else.
///
/// The parameters are the leaves — the http clients, the Supabase client,
/// the PostHog instance — plus the build-time values the app owns. `main`
/// passes the real ones; a test passes scripted ones and nothing else, so
/// what a test exercises is the production graph with fake edges.
///
/// Everything registered here is user-agnostic and lives for the process;
/// blocs are factories, created by the screen that owns them. Nothing is
/// lazy: a dependency that cannot be built fails the launch, not the first
/// screen that needs it.
void registerApp(
  GetIt getIt, {
  required http.Client agentHttpClient,
  required http.Client configHttpClient,
  required SupabaseClient supabase,
  required Posthog posthog,
  required String appVersion,
  required Uri agentUrl,
  required Uri configUrl,
}) {
  getIt.registerSingleton(supabase);
  registerAgentClient(
    getIt,
    agentHttpClient: agentHttpClient,
    configHttpClient: configHttpClient,
    agentUrl: agentUrl,
    configUrl: configUrl,
    appVersion: appVersion,
    // Read on every round: the token the app holds now, not at registration.
    accessToken: () => supabase.auth.currentSession?.accessToken,
  );
  registerAnalytics(getIt, posthog: posthog, consentVersion: consentVersion);
  registerJournalRepository(getIt, supabase: supabase);
  registerConsentRepository(getIt, supabase: supabase, version: consentVersion);
  registerConfig(getIt, appVersion: appVersion);
  registerAuth(getIt);
  registerJournal(getIt);
  registerConsent(getIt);
  registerSession(getIt);
  registerAccount(getIt);
}
