import 'package:design_system/design_system.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/config/bloc/config_bloc.dart';
import 'package:emotely/config/view/config_gate.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

/// Root of the emotely client: theme, the two blocs that sit above every
/// screen, and the one decision above every screen — signed in or not.
///
/// Every dependency comes out of the container `registerApp` filled
/// (ADR 0015); the widget itself is handed nothing.
class const EmotelyApp({super.key}) extends StatelessWidget {
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
    child: MaterialApp(
      title: 'emotely',
      theme: lightTheme,
      darkTheme: darkTheme,
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
