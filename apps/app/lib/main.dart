// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.
import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/app.dart';
import 'package:emotely/app/environment.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Posthog().setup(PostHogConfig(posthogKey)..host = posthogHost);
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
  runApp(
    EmotelyApp(
      agentClient: AgentClient(
        httpClient: http.Client(),
        endpoint: Uri.parse(agentUrl),
        // `version` is pubspec's `version` without the build number.
        appVersion: packageInfo.version,
        accessToken: () => supabase.client.auth.currentSession?.accessToken,
      ),
      analytics: SessionAnalytics(posthog: posthog),
      supabase: supabase.client,
      authAnalytics: AuthAnalytics(posthog: posthog),
    ),
  );
}
