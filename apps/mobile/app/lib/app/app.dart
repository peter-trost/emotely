import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/consent_analytics.dart';
import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/analytics/journal_analytics.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/theme.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/config/bloc/config_bloc.dart';
import 'package:emotely/config/config_client.dart';
import 'package:emotely/config/view/config_gate.dart';
import 'package:emotely/consent/consent_store.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Root of the emotely client: theme, the services every screen may need,
/// and the one decision above every screen — signed in or not.
class const EmotelyApp({
  required final AgentClient agentClient,
  required final ConfigClient configClient,
  required final String appVersion,
  required final SessionAnalytics analytics,
  required final SupabaseClient supabase,
  required final AuthAnalytics authAnalytics,
  required final JournalAnalytics journalAnalytics,
  required final ConsentAnalytics consentAnalytics,
  required final ErrorReporter errorReporter,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: agentClient),
      RepositoryProvider.value(value: analytics),
      RepositoryProvider.value(value: supabase),
      RepositoryProvider.value(value: authAnalytics),
      RepositoryProvider(create: (_) => JournalStore(supabase: supabase)),
      RepositoryProvider(create: (_) => ConsentStore(supabase: supabase)),
      RepositoryProvider.value(value: journalAnalytics),
      RepositoryProvider.value(value: consentAnalytics),
      RepositoryProvider.value(value: errorReporter),
      RepositoryProvider.value(value: configClient),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            supabase: supabase,
            analytics: authAnalytics,
            errors: errorReporter,
          ),
        ),
        // Not lazy: the gate must ask before the first frame the user could
        // act on, not when something happens to read it.
        BlocProvider(
          lazy: false,
          create: (_) => ConfigBloc(
            client: configClient,
            appVersion: appVersion,
            analytics: analytics,
            errors: errorReporter,
          )..add(const ConfigEvent.loaded()),
        ),
      ],
      child: MaterialApp(
        title: 'emotely',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const ConfigGate(child: _Root()),
      ),
    ),
  );
}

/// Signed in: the journal. Anything else: sign in first.
class const _Root() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) =>
        state is AuthSignedIn ? const JournalPage() : const SignInPage(),
  );
}
