import 'package:emotely/app/routes.dart';
import 'package:feature_account/feature_account.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_journal/feature_journal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// The account screen reads the record again once the route closes, so
  /// what the route answered is of no use to it here.
  @override
  Future<void> requestConsent(NavigatorState navigator) =>
      const ConsentRoute().push<ConsentOutcome>(navigator.context);
}

/// Everything the journal leads to: the session, the consent gate, the
/// account screen, signing out.
class const AppJournalNavigator() implements JournalNavigator {
  @override
  Future<void> startSession(NavigatorState navigator, {String? resume}) =>
      SessionRoute(resume: resume).push<void>(navigator.context);

  /// The consent screen on its own route ([ConsentRoute]), answering how
  /// it was left. A decline, a failed write and a dismissed route all leave
  /// the gate shut and land the user back on the journal — but they are
  /// not the same thing to say, so the message is chosen by what actually
  /// happened rather than always reading as a refusal.
  @override
  Future<bool> requestConsent(NavigatorState navigator) async {
    final outcome = await const ConsentRoute().push<ConsentOutcome>(
      navigator.context,
    );
    if (outcome == ConsentOutcome.granted) {
      return true;
    }
    _saySoFar(navigator, outcome);
    return false;
  }

  /// Tells the user, back on the journal, why no session started. A refusal
  /// and a failed write are not the same news: telling someone who ticked
  /// the box and hit a network error that they chose "Not now" is untrue.
  /// Dismissing the screen says nothing at all — the user left, and knows
  /// it — and so does a failed read, whose screen already said its piece.
  static void _saySoFar(NavigatorState navigator, ConsentOutcome? outcome) {
    final message = switch (outcome) {
      ConsentOutcome.writeFailed => consentFailureMessage,
      ConsentOutcome.declined => consentDeclinedMessage,
      ConsentOutcome.granted || null => null,
    };
    if (message == null) {
      return;
    }
    ScaffoldMessenger.maybeOf(navigator.context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  /// The router is reached through the navigator's own context, which
  /// outlives any screen: the journal captures the navigator before it
  /// awaits the server, and this must not reach back into a page that may
  /// have gone.
  @override
  void openAccount(NavigatorState navigator) =>
      const AccountRoute().go(navigator.context);

  @override
  void openEntry(NavigatorState navigator, {required String entryId}) =>
      EntryRoute(id: entryId).go(navigator.context);

  @override
  void signOut(BuildContext context) =>
      context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
}
