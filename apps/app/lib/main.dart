// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.
import 'package:emotely/app/environment.dart';
import 'package:emotely/app/theme.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    EmotelyApp(
      agentClient: AgentClient(
        httpClient: http.Client(),
        endpoint: Uri.parse(agentUrl),
      ),
    ),
  );
}

/// Root of the emotely client: theme, the agent client, and the session.
class const EmotelyApp({required final AgentClient agentClient, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: agentClient,
    child: MaterialApp(
      title: 'emotely',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const SessionPage(),
    ),
  );
}
