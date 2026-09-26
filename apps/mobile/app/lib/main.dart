// coverage:ignore-file
// The launch sequence; the graph it composes is `registerApp`, which the
// app's tests compose the same way over scripted leaves.

import 'package:analytics/analytics.dart';
import 'package:emotely/app/app.dart';
import 'package:emotely/app/dependencies.dart';
import 'package:emotely/app/environment.dart';
import 'package:feedback_link/feedback_link.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
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
  // One http client for both agent endpoints: same host, one connection pool.
  final httpClient = http.Client();
  registerApp(
    GetIt.I,
    agentHttpClient: httpClient,
    configHttpClient: httpClient,
    supabase: supabase.client,
    posthog: Posthog(),
    // `version` is pubspec's `version` without the build number.
    appVersion: packageInfo.version,
    // What a feedback mail says about the build it came from; the platform
    // and its version the utility reads for itself.
    build: BuildInfo.ofPlatform(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    ),
    // Checked here, once: a bad define fails the launch, not the first round.
    agentUrl: urlFrom(agentUrl, define: 'EMOTELY_AGENT_URL'),
    configUrl: urlFrom(configUrl, define: 'EMOTELY_CONFIG_URL'),
    google: googleClients,
  );
  runApp(const EmotelyApp());
}
