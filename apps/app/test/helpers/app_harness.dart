import 'package:emotely/app/app.dart';
import 'package:flutter/widgets.dart';

import 'agent_stub.dart';
import 'analytics_spy.dart';
import 'supabase_stub.dart';

/// The whole app, wired to the scripted agent, the scripted Supabase and the
/// spied PostHog. The agent client forwards whatever token the Supabase
/// session holds, exactly as in `main.dart`.
Widget appUnderTest({
  required AgentStub agent,
  required SupabaseStub supabase,
  required AnalyticsSpy analytics,
}) {
  agent.accessToken = () => supabase.supabase.auth.currentSession?.accessToken;
  // A journal that accepts every write unless the test scripts otherwise.
  supabase.journalWorks();
  return EmotelyApp(
    agentClient: agent.agentClient,
    analytics: analytics.analytics,
    supabase: supabase.supabase,
    authAnalytics: analytics.authAnalytics,
  );
}
