import 'dart:async';

import 'package:feature_account/src/account/bloc/account_bloc.dart';
import 'package:feature_account/src/consent/bloc/consent_bloc.dart';
import 'package:feature_account/src/consent/consent_text.dart';
import 'package:feature_account/src/navigator.dart';
import 'package:feedback_link/feedback_link.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';

/// Wires an [AccountBloc] to the Supabase client in scope.
class const AccountPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.I<AccountBloc>(),
    child: const AccountView(),
  );
}

/// The account screen: what deleting the account means, and the button that
/// does it after a confirmation. Leaves on its own once the account is gone;
/// the root has already swapped the journal for sign-in underneath.
class const AccountView({super.key}) extends StatelessWidget {
  static const deleteKey = Key('account_view.delete');
  static const confirmKey = Key('account_view.confirm');
  static const cancelKey = Key('account_view.cancel');
  static const retryKey = Key('account_view.retry');
  static const signOutKey = Key('account_view.sign_out');
  static const privacyNoticeKey = Key('account_view.privacy_notice');
  static const imprintKey = Key('account_view.imprint');
  static const feedbackKey = Key('account_view.feedback');
  static const withdrawConsentKey = Key('account_view.withdraw_consent');
  static const restoreConsentKey = Key('account_view.restore_consent');
  static const consentRetryKey = Key('account_view.consent_retry');

  /// What deleting means; the screen says it once, the dialog only asks.
  static const consequenceMessage =
      'Deleting your account also deletes every journal entry you wrote. '
      'There is no way back.';
  static const confirmationMessage = 'Delete your account and every entry?';

  /// Under the feedback row: says what the mail already contains, so
  /// nobody has to wonder whether tapping it sends anything they wrote.
  static const feedbackExplanation =
      'Opens your mail app. Carries your app version and device, '
      'nothing from your journal.';
  static const failureMessage = AccountBloc.failureMessage;

  @override
  Widget build(BuildContext context) => BlocConsumer<AccountBloc, AccountState>(
    listenWhen: (_, state) => state is AccountDeleted,
    listener: (context, _) {
      // Only this route pops itself; never whatever else may be on top,
      // and never the root under it.
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Navigator.of(context).pop();
      }
    },
    // The server deletes the account whether or not this screen stays; the
    // bloc lives with the route, so leaving mid-flight would drop the local
    // sign-out and keep a session for a user who no longer exists. Every
    // way out (back arrow, system back, swipe) asks the route first.
    builder: (context, state) => PopScope(
      canPop: state is! AccountDeleting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: SafeArea(
          child: switch (state) {
            AccountIdle() => const _Account(),
            // Deleted has no screen of its own: the listener above pops
            // this route the moment it arrives.
            AccountDeleting() || AccountDeleted() => const _Busy(),
            AccountFailure() => const _Margin(child: _Failure()),
          },
        ),
      ),
    ),
  );
}

/// Everything the account screen offers when nothing is in flight: the
/// consent that can be taken back, the two documents the stores and § 5 DDG
/// require to be reachable from inside the app, and the deletion.
class const _Account() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    // The column stretches to the viewport's width, not to the scroll
    // view's unbounded height, so the buttons keep their full-width look
    // without the content growing without limit. The margin sits on each
    // section rather than the page, because the legal rows claim the full
    // width (see [_Legal]).
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        _Margin(child: _Consent()),
        _Legal(),
        _Margin(child: Divider()),
        _Margin(child: _DeleteAccount()),
      ],
    ),
  );
}

/// The page margin. Sections get it one by one so a list row in between
/// can run edge to edge.
class const _Margin({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: child,
  );
}

/// Withdrawing consent, and giving it again — both one tap, because Art. 7
/// (3) requires taking it back to be as easy as giving it, and neither may
/// require deleting the account.
class const _Consent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<ConsentBloc, ConsentState>(
    builder: (context, state) => switch (state) {
      ConsentBusy() => const Center(child: CircularProgressIndicator()),
      ConsentWithdrawFailure() => const _ConsentFailed(
        message: withdrawFailureMessage,
        event: ConsentEvent.withdrawn(),
        label: withdrawConsentLabel,
        buttonKey: AccountView.withdrawConsentKey,
      ),
      ConsentKnown(granted: true) => const _ConsentStanding(),
      // A grant is only ever written from the consent screen, on its own
      // route with a bloc of its own; a failed write there is that screen's
      // to say. Should this bloc ever hold one, consent does not stand, and
      // the way back is the same screen.
      ConsentKnown(granted: false) ||
      ConsentWriteFailure() => const _ConsentGone(),
      // The answer is not in hand: the read failed, or (only if this screen
      // is somehow reached before the journal's eager load finished) has
      // not arrived. Rendering nothing would leave a user who came here to
      // withdraw with no control and no explanation — the one thing Art. 7
      // (3) cannot tolerate — so say so and offer to look again.
      ConsentFailure() || ConsentUnknown() => const _ConsentUnknown(),
    },
  );
}

/// Whether consent stands could not be read. Says so and offers to look
/// again, rather than leaving the section silently empty: a user who came
/// here to withdraw must never find nothing and no reason why.
class const _ConsentUnknown() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        consentUnknownMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      OutlinedButton(
        key: AccountView.consentRetryKey,
        onPressed: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.loaded()),
        child: const Text('Try again'),
      ),
    ],
  );
}

/// Consent stands: say what it covers, and offer to take it back.
class const _ConsentStanding() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        withdrawConsentExplanation,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      OutlinedButton(
        key: AccountView.withdrawConsentKey,
        onPressed: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.withdrawn()),
        child: const Text(withdrawConsentLabel),
      ),
    ],
  );
}

/// Consent does not stand — never given, or taken back: say what that
/// means, and offer the way forward.
///
/// The way forward is the consent screen itself, not a button that grants
/// on the spot. Art. 7 (3) requires withdrawal to be as easy as giving; it
/// does not license making *giving* easier the second time, and a one-tap
/// re-grant would be a weaker act than the first while writing a record that
/// claims the same thing. So the second consent is the same three points
/// and the same unticked box as the first.
class const _ConsentGone() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        consentMissingExplanation,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      OutlinedButton(
        key: AccountView.restoreConsentKey,
        onPressed: () => unawaited(_askAgain(context)),
        child: const Text(giveConsentLabel),
      ),
    ],
  );

  /// The consent screen on its own route, which the app shows (ADR 0015);
  /// once it closes, this screen asks the server again rather than trusting
  /// what it showed before — the record is what counts.
  static Future<void> _askAgain(BuildContext context) async {
    final consent = context.read<ConsentBloc>();
    await GetIt.I<AccountNavigator>().requestConsent(Navigator.of(context));
    consent.add(const ConsentEvent.loaded());
  }
}

/// A consent write did not land. Says so and offers the same act again,
/// rather than showing a state the server does not agree with.
class const _ConsentFailed({
  required final String message,
  required final ConsentEvent event,
  required final String label,
  required final Key buttonKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      OutlinedButton(
        key: buttonKey,
        onPressed: () => context.read<ConsentBloc>().add(event),
        child: Text(label),
      ),
    ],
  );
}

/// Every link that leaves the app. The privacy notice and the imprint are
/// required to be reachable from inside the app — Apple guideline 5.1.1 (i)
/// and Google Play's User Data policy for the notice, § 5 DDG for the
/// imprint of a German provider — and the feedback mail sits with them
/// because it is the same act: a labelled row that hands the user to
/// another app.
///
/// The rows run edge to edge, outside the page margin, with the theme's
/// own content inset: a row is a button the width of the screen, and its
/// highlight should say so rather than light up a strip inside the margin.
class const _Legal() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        key: AccountView.privacyNoticeKey,
        title: const Text(privacyNoticeLabel),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => unawaited(openPrivacyNotice()),
      ),
      ListTile(
        key: AccountView.imprintKey,
        title: const Text(imprintLabel),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => unawaited(openImprint()),
      ),
      // Unlike the two above, the mail carries the build the user is
      // running, which is a dependency — so it goes through the bloc
      // rather than being launched from here (ADR 0015).
      ListTile(
        key: AccountView.feedbackKey,
        title: const Text(feedbackLabel),
        subtitle: const Text(AccountView.feedbackExplanation),
        trailing: const Icon(Icons.mail_outline),
        onTap: () => context.read<AccountBloc>().add(
          const AccountEvent.feedbackRequested(),
        ),
      ),
    ],
  );
}

class const _DeleteAccount() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        AccountView.consequenceMessage,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      OutlinedButton(
        key: AccountView.deleteKey,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => unawaited(_confirm(context)),
        child: const Text('Delete account'),
      ),
    ],
  );

  /// The dialog sits above this screen on the navigator, outside the
  /// bloc's scope, so the bloc is captured before it opens.
  static Future<void> _confirm(BuildContext context) {
    final account = context.read<AccountBloc>();
    return showDialog<void>(
      context: context,
      builder: (_) => _Confirmation(
        onConfirm: () => account.add(const AccountEvent.deletionRequested()),
      ),
    );
  }
}

/// Asks once more, naming the loss in the question; the only way to delete.
class const _Confirmation({required final VoidCallback onConfirm})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(AccountView.confirmationMessage),
    actions: [
      TextButton(
        key: AccountView.cancelKey,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: AccountView.confirmKey,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: () {
          Navigator.of(context).pop();
          onConfirm();
        },
        child: const Text('Delete'),
      ),
    ],
  );
}

/// Retry, or sign out: the server may have deleted the account even though
/// the answer never arrived, and this device should not keep a session it
/// may no longer be entitled to. (`delete_account` is idempotent, so the
/// retry is safe either way.)
class const _Failure() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        AccountView.failureMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      FilledButton(
        key: AccountView.retryKey,
        onPressed: () => context.read<AccountBloc>().add(
          const AccountEvent.deletionRequested(),
        ),
        child: const Text('Try again'),
      ),
      TextButton(
        key: AccountView.signOutKey,
        onPressed: () {
          // The app signs out (the root swaps to sign-in underneath); this
          // route leaves too. Resolving the navigator is one of the two
          // container calls a widget may make (ADR 0015).
          GetIt.I<AccountNavigator>().signOut(context);
          Navigator.of(context).pop();
        },
        child: const Text('Sign out'),
      ),
    ],
  );
}

class const _Busy() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
