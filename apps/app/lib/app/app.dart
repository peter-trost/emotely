import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/theme.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Root of the emotely client: theme, the services every screen may need,
/// and the one decision above every screen — signed in or not.
class const EmotelyApp({
  required final AgentClient agentClient,
  required final SessionAnalytics analytics,
  required final SupabaseClient supabase,
  required final AuthAnalytics authAnalytics,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: agentClient),
      RepositoryProvider.value(value: analytics),
      RepositoryProvider.value(value: supabase),
      RepositoryProvider(create: (_) => JournalStore(supabase: supabase)),
    ],
    child: BlocProvider(
      create: (_) => AuthBloc(supabase: supabase, analytics: authAnalytics),
      child: MaterialApp(
        title: 'emotely',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const _Root(),
      ),
    ),
  );
}

/// Signed in: the journaling session. Anything else: sign in first.
class const _Root() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) =>
        state is AuthSignedIn ? const SessionPage() : const SignInPage(),
  );
}
