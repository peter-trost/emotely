import 'package:emotely/app/app.dart';
import 'package:flutter/widgets.dart';

import 'agent_stub.dart';
import 'analytics_spy.dart';
import 'config_stub.dart';
import 'supabase_stub.dart';

/// The whole app, wired to the scripted agent, the scripted Supabase and the
/// spied PostHog. The agent client forwards whatever token the Supabase
/// session holds, exactly as in `main.dart`.
Widget appUnderTest({
  required AgentStub agent,
  required SupabaseStub supabase,
  required AnalyticsSpy analytics,
  ConfigStub? config,
}) {
  agent.accessToken = () => supabase.supabase.auth.currentSession?.accessToken;
  // A journal that accepts every write unless the test scripts otherwise.
  supabase.journalWorks();
  // A startup gate that opens unless the test scripts otherwise; without it
  // every test would sit on the checking screen.
  final configStub = config ?? (ConfigStub()..serves());
  return EmotelyApp(
    appVersion: AgentStub.appVersion,
    configClient: configStub.configClient,
    agentClient: agent.agentClient,
    analytics: analytics.analytics,
    supabase: supabase.supabase,
    authAnalytics: analytics.authAnalytics,
    journalAnalytics: analytics.journalAnalytics,
    consentAnalytics: analytics.consentAnalytics,
    errorReporter: analytics.errorReporter,
  );
}
