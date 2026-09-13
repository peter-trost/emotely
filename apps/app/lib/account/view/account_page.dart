import 'dart:async';

import 'package:emotely/account/bloc/account_bloc.dart';
import 'package:emotely/analytics/auth_analytics.dart';
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

  static const confirmationMessage =
      'Every journal entry you wrote will be deleted with it. '
      'This cannot be undone.';
  static const failureMessage = AccountBloc.failureMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<AccountBloc, AccountState>(
          listenWhen: (_, state) => state is AccountDeleted,
          listener: (context, _) => Navigator.of(context).pop(),
          builder: (context, state) => switch (state) {
            AccountIdle() => const _DeleteAccount(),
            AccountDeleting() || AccountDeleted() => const _Busy(),
            AccountFailure() => const _Failure(),
          },
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
        'Deleting your account removes it and every journal entry in it. '
        'There is no way back.',
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

/// Names what is lost before anything is; the only way to delete.
class const _Confirmation({required final VoidCallback onConfirm})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete your account?'),
    content: const Text(AccountView.confirmationMessage),
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
    ],
  );
}

class const _Busy() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
