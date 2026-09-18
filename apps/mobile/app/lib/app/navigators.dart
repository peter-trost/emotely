import 'package:feature_account/feature_account.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_journal/feature_journal.dart';
import 'package:feature_session/feature_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:journal_repository/journal_repository.dart';
import 'package:material_ui/material_ui.dart';

/// The app's side of every feature's navigator (ADR 0015): a feature says
/// what it needs from the outside, the app says how — with the real pages
/// and the real blocs, which only the app may know together.

/// Signing out is the auth feature's act: the root swaps to sign-in once
/// the auth bloc has ended the session.
class const AppAccountNavigator() implements AccountNavigator {
  @override
  void signOut(BuildContext context) =>
      context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
}

/// Everything the journal leads to: the session, the consent gate, the
/// account screen, signing out.
class const AppJournalNavigator() implements JournalNavigator {
  @override
  Future<void> startSession(NavigatorState navigator, {OpenSession? resume}) =>
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => SessionPage(resume: resume)),
      );

  /// The consent screen on its own route with a bloc of its own, which is
  /// the authority on the answer: `granted` only after the server recorded
  /// it. A decline, a failed write and a dismissed route all leave it shut
  /// and land the user back on the journal — but they are not the same
  /// thing to say, so the message is chosen by what actually happened
  /// rather than always reading as a refusal.
  @override
  Future<bool> requestConsent(NavigatorState navigator) async {
    // The route owns the bloc (the provider closes it when the route is
    // disposed); this keeps a reference only to read the answer after the
    // pop. Awaiting the close here instead would wait on the outgoing
    // route, which still listens until its transition ends.
    final consent = GetIt.I<ConsentBloc>()..add(const ConsentEvent.loaded());
    await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<ConsentBloc>(
          create: (_) => consent,
          child: const ConsentPage(),
        ),
      ),
    );
    if (consent.state.allowsSession) {
      return true;
    }
    _saySoFar(navigator, consent.state);
    return false;
  }

  /// Tells the user, back on the journal, why no session started. A refusal
  /// and a failed write are not the same news: telling someone who ticked
  /// the box and hit a network error that they chose "Not now" is untrue.
  /// Dismissing the screen says nothing at all — the user left, and knows
  /// it — and so does a failed read, whose screen already said its piece.
  static void _saySoFar(NavigatorState navigator, ConsentState state) {
    final message = switch (state) {
      ConsentWriteFailure() => consentFailureMessage,
      ConsentKnown(justDeclined: true) => consentDeclinedMessage,
      _ => null,
    };
    if (message == null) {
      return;
    }
    ScaffoldMessenger.maybeOf(navigator.context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  /// The account screen owns a consent bloc of its own for the section that
  /// takes consent back; the journal asks the server again before every
  /// session, so nothing has to be shared between the two routes.
  @override
  void openAccount(NavigatorState navigator) => navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => GetIt.I<ConsentBloc>()..add(const ConsentEvent.loaded()),
        child: const AccountPage(),
      ),
    ),
  );

  @override
  void signOut(BuildContext context) =>
      context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
}
