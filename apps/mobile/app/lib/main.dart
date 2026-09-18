// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.

import 'package:agent_client/agent_client.dart';
import 'package:analytics/analytics.dart';
import 'package:emotely/app/app.dart';
import 'package:emotely/app/environment.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Error tracking (ADR 0004, no Sentry): uncaught errors are captured by
  // the SDK outside debug runs, handled failures by ErrorReporter always.
  await Posthog().setup(
    withErrorTracking(
      PostHogConfig(posthogKey)..host = posthogHost,
      autocapture: !kDebugMode,
    ),
  );
  // Sign-in is a typed code, never a link, so no deep links and no PKCE
  // exchange; the session itself is persisted and refreshed by the SDK.
  final supabase = await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      detectSessionInUri: false,
    ),
  );
  final packageInfo = await PackageInfo.fromPlatform();
  final posthog = Posthog();
  // One client for both endpoints: same host, same connection pool.
  final httpClient = http.Client();
  runApp(
    EmotelyApp(
      // `version` is pubspec's `version` without the build number.
      appVersion: packageInfo.version,
      configClient: ConfigClient(
        httpClient: httpClient,
        endpoint: Uri.parse(configUrl),
      ),
      agentClient: AgentClient(
        httpClient: httpClient,
        endpoint: Uri.parse(agentUrl),
        appVersion: packageInfo.version,
        accessToken: () => supabase.client.auth.currentSession?.accessToken,
      ),
      analytics: SessionAnalytics(posthog: posthog),
      supabase: supabase.client,
      authAnalytics: AuthAnalytics(posthog: posthog),
      journalAnalytics: JournalAnalytics(posthog: posthog),
      consentAnalytics: ConsentAnalytics(
        posthog: posthog,
        version: consentVersion,
      ),
      errorReporter: ErrorReporter(posthog: posthog),
    ),
  );
}
