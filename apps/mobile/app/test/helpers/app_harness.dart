import 'package:emotely/app/app.dart';
import 'package:emotely/app/dependencies.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

/// The whole app, composed by the production `registerApp` over the scripted
/// agent, the scripted config endpoint, the scripted Supabase and the spied
/// PostHog: the leaves are replaced and nothing else, so what a test
/// exercises is the production graph with fake edges. The agent client
/// forwards whatever token the Supabase session holds, exactly as in
/// `main.dart`, because the same code builds it.
///
/// The container is emptied when the test ends. Composing twice in one test
/// fails loudly — get_it refuses to re-register — rather than silently
/// replacing what the first composition built.
Widget appUnderTest({
  required AgentStub agent,
  required SupabaseStub supabase,
  required AnalyticsSpy analytics,
  ConfigStub? config,
}) {
  // A journal that accepts every write unless the test scripts otherwise.
  supabase.journalWorks();
  // A startup gate that opens unless the test scripts otherwise; without it
  // every test would sit on the checking screen.
  final configStub = config ?? (ConfigStub()..serves());
  addTearDown(GetIt.I.reset);
  registerApp(
    GetIt.I,
    agentHttpClient: agent.client,
    configHttpClient: configStub.client,
    supabase: supabase.supabase,
    posthog: analytics.posthog,
    appVersion: AgentStub.appVersion,
    agentUrl: AgentStub.endpoint,
    configUrl: ConfigStub.endpoint,
  );
  return const EmotelyApp();
}
