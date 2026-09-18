import 'package:design_system/design_system.dart';
import 'package:emotely/config/bloc/config_bloc.dart';
import 'package:emotely/config/view/config_gate.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_journal/feature_journal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Root of the emotely client: theme, the two blocs that sit above every
/// screen, and the one decision above every screen — signed in or not.
///
/// Every dependency comes out of the container `registerApp` filled
/// (ADR 0015); the widget itself is handed nothing.
class const EmotelyApp({super.key}) extends StatefulWidget {
  @override
  State<EmotelyApp> createState() => _EmotelyAppState();
}

class _EmotelyAppState() extends State<EmotelyApp> {
  /// One observer per mounted app, built once rather than per rebuild: it
  /// registers itself with the widgets binding and tracks this navigator's
  /// routes, so neither a fresh one each frame nor one shared between apps
  /// would do.
  final _surveyObserver = PosthogObserver();

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => GetIt.I<AuthBloc>()),
      // Not lazy: the gate must ask before the first frame the user could
      // act on, not when something happens to read it.
      BlocProvider(
        lazy: false,
        create: (_) => GetIt.I<ConfigBloc>()..add(const ConfigEvent.loaded()),
      ),
    ],
    // PostHog draws a popover survey into the navigator's own context, which
    // it reaches through `PosthogObserver`; without the observer it finds no
    // context and logs that it cannot show the survey, and without the
    // wrapper it has nothing to draw into (ADR 0004). Surveys carry only
    // what the user types into them — no journal text passes through here,
    // and session replay stays off (ADR 0005).
    //
    // The wrapper goes in `builder`, under the navigator rather than over
    // it: above `MaterialApp` its own state would outlive a remount of the
    // app and keep the old route stack alive with it.
    child: MaterialApp(
      title: 'emotely',
      theme: lightTheme,
      darkTheme: darkTheme,
      navigatorObservers: [_surveyObserver],
      builder: (context, child) =>
          PostHogWidget(child: child ?? const SizedBox.shrink()),
      home: const ConfigGate(child: _Root()),
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
