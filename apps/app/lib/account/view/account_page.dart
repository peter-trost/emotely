import 'dart:async';

import 'package:emotely/account/bloc/account_bloc.dart';
import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Wires an [AccountBloc] to the Supabase client in scope.
class const AccountPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountBloc(
      supabase: context.read<SupabaseClient>(),
      analytics: context.read<AuthAnalytics>(),
      errors: context.read<ErrorReporter>(),
    ),
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

  /// What deleting means; the screen says it once, the dialog only asks.
  static const consequenceMessage =
      'Deleting your account also deletes every journal entry you wrote. '
      'There is no way back.';
  static const confirmationMessage = 'Delete your account and every entry?';
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (state) {
              AccountIdle() => const _DeleteAccount(),
              // Deleted has no screen of its own: the listener above pops
              // this route the moment it arrives.
              AccountDeleting() || AccountDeleted() => const _Busy(),
              AccountFailure() => const _Failure(),
            },
          ),
        ),
      ),
    ),
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
          // The root swaps to sign-in underneath; this route leaves too.
          context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
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
