// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/theme.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Where the agent runs; override per build with
/// `--dart-define=EMOTELY_AGENT_URL=…`.
const agentUrl = String.fromEnvironment(
  'EMOTELY_AGENT_URL',
  defaultValue: 'https://emotely-agent.vercel.app/api/advance-session',
);

/// The PostHog project token (`--dart-define=POSTHOG_KEY=phc_…`). Empty
/// means analytics off: the SDK skips setup and captures go nowhere.
const posthogKey = String.fromEnvironment('POSTHOG_KEY');

/// EU cloud, like the agent (ADR 0004).
const posthogHost = 'https://eu.i.posthog.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Posthog().setup(PostHogConfig(posthogKey)..host = posthogHost);
  runApp(
    EmotelyApp(
      agentClient: AgentClient(
        httpClient: http.Client(),
        endpoint: Uri.parse(agentUrl),
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
