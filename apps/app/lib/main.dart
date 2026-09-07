// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/environment.dart';
import 'package:emotely/app/theme.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Posthog().setup(PostHogConfig(posthogKey)..host = posthogHost);
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(
    EmotelyApp(
      agentClient: AgentClient(
        httpClient: http.Client(),
        endpoint: Uri.parse(agentUrl),
        // `version` is pubspec's `version` without the build number.
        appVersion: packageInfo.version,
      ),
      analytics: SessionAnalytics(posthog: Posthog()),
    ),
  );
}

/// Root of the emotely client: theme, the agent client, analytics, and the
/// session.
class const EmotelyApp({
  required final AgentClient agentClient,
  required final SessionAnalytics analytics,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: agentClient),
      RepositoryProvider.value(value: analytics),
    ],
    child: MaterialApp(
      title: 'emotely',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const SessionPage(),
    ),
  );
}
