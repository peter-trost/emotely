import 'dart:async';

import 'package:emotely/account/view/account_page.dart';
import 'package:emotely/analytics/consent_analytics.dart';
import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/analytics/journal_analytics.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/consent/bloc/consent_bloc.dart';
import 'package:emotely/consent/consent_store.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:emotely/consent/view/consent_page.dart';
import 'package:emotely/journal/bloc/journal_bloc.dart';
import 'package:emotely/journal/journal_models.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:emotely/journal/view/entry_page.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Home: the journal so far and the way into the next session.
///
/// Owns the [ConsentBloc] as well as the journal's own, because the two
/// screens that care whether consent stands — this one, which will not start
/// a session without it, and the account screen, which can take it back —
/// both live under this route. One bloc, one answer, read from the server.
class const JournalPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => JournalBloc(
          store: context.read<JournalStore>(),
          analytics: context.read<JournalAnalytics>(),
        )..add(const JournalEvent.loaded()),
      ),
      BlocProvider(
        // Eager: the answer has to be in hand before Start is tapped, and
        // a lazy provider would not read it until something looked, which
        // is the tap itself — one frame too late.
        lazy: false,
        create: (context) => ConsentBloc(
          store: context.read<ConsentStore>(),
          analytics: context.read<ConsentAnalytics>(),
          errors: context.read<ErrorReporter>(),
        )..add(const ConsentEvent.loaded()),
      ),
    ],
    child: const JournalView(),
  );
}

/// One widget per [JournalState]; entries and the session card when ready.
class const JournalView({super.key}) extends StatelessWidget {
  static const startKey = Key('journal_view.start');
  static const continueKey = Key('journal_view.continue');
  static const discardKey = Key('journal_view.discard');
  static const accountKey = Key('journal_view.account');
  static const signOutKey = Key('journal_view.sign_out');
  static const retryKey = Key('journal_view.retry');
  static const emptyKey = Key('journal_view.empty');
  static Key entryKey(String id) => Key('journal_view.entry.$id');

  static const failureMessage = 'Could not load your journal.';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Your journal'),
      actions: [
        IconButton(
          key: accountKey,
          tooltip: 'Account',
          icon: const Icon(Icons.manage_accounts_outlined),
          // The account screen is a route of its own, so it is outside this
          // one's providers; it is handed the same consent bloc, because
          // withdrawing there has to change what Start does back here.
          onPressed: () {
            final consent = context.read<ConsentBloc>();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: consent,
                  child: const AccountPage(),
                ),
              ),
            );
          },
        ),
        IconButton(
          key: signOutKey,
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthEvent.signOutRequested()),
        ),
      ],
    ),
    body: SafeArea(
      child: BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) => switch (state) {
          JournalLoading() => const Center(child: CircularProgressIndicator()),
          JournalFailure() => const _Failure(),
          JournalReady(:final entries, :final openSession) => _Journal(
            entries: entries,
            openSession: openSession,
          ),
        },
      ),
    ),
  );
}

class const _Journal({
  required final List<EntryRecord> entries,
  required final OpenSession? openSession,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: _SessionCard(openSession: openSession),
      ),
      Expanded(
        child: entries.isEmpty
            ? const Center(
                child: Text(
                  'No entries yet. Your first session writes the first one.',
                  key: JournalView.emptyKey,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  for (final record in entries) _EntryTile(record: record),
                ],
              ),
      ),
    ],
  );
}

/// Start a session, or continue (or drop) the one still in progress.
class const _SessionCard({required final OpenSession? openSession})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (openSession) {
    null => FilledButton(
      key: JournalView.startKey,
      onPressed: () => unawaited(_open(context, resume: null)),
      child: const Text('Start a session'),
    ),
    final session => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        const Text('You have an unfinished session.'),
        FilledButton(
          key: JournalView.continueKey,
          onPressed: () => unawaited(_open(context, resume: session)),
          child: const Text('Continue'),
        ),
        TextButton(
          key: JournalView.discardKey,
          onPressed: () => context.read<JournalBloc>().add(
            const JournalEvent.sessionDiscarded(),
          ),
          child: const Text('Discard it'),
        ),
      ],
    ),
  };

  /// Runs the session on its own route; the journal reloads when it is
  /// popped, whether the session finished or not.
  ///
  /// Nothing starts before consent stands. A user who signed up before this
  /// shipped has entries but no consent row, so they are asked here, on the
  /// way into their next session — which is why the question reads as the
  /// app asking rather than as an error.
  static Future<void> _open(
    BuildContext context, {
    required OpenSession? resume,
  }) async {
    final journal = context.read<JournalBloc>();
    final consent = context.read<ConsentBloc>();
    final navigator = Navigator.of(context);
    // Ask the server before every session, never the answer this device
    // happened to read at launch: a withdrawal made on another device must
    // stop this one, which is what the consent screen promises.
    await consent.refresh();
    if (!consent.state.allowsSession) {
      await navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              BlocProvider.value(value: consent, child: const ConsentPage()),
        ),
      );
      // The bloc's state is the authority, not the route's result: it says
      // `granted` only after the server recorded it. A decline, a failed
      // write, a dismissed route and a bloc closed mid-request all leave it
      // shut, and the journal is where the user lands in every one of them —
      // but they are not the same thing to say, so the message is chosen by
      // what actually happened rather than always reading as a refusal.
      if (!consent.state.allowsSession) {
        _saySoFar(navigator, consent.state);
        return;
      }
    }
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => SessionPage(resume: resume)),
    );
    journal.add(const JournalEvent.loaded());
  }

  /// Tells the user, back on the journal, why no session started.
  ///
  /// A refusal and a failed write both leave the gate shut, but they are not
  /// the same news: telling someone who ticked the box and hit a network
  /// error that they chose "Not now" is untrue, and it is the app's own
  /// account of what just happened. Dismissing the screen says nothing at
  /// all — the user left, and knows it.
  static void _saySoFar(NavigatorState navigator, ConsentState state) {
    final message = switch (state) {
      ConsentWriteFailure() => consentFailureMessage,
      ConsentKnown(justDeclined: true) => consentDeclinedMessage,
      // Everything else: a dismissed screen, a failed read, a withdrawal
      // that did not land. The user left, or the screen they left already
      // said its piece; inventing a refusal they did not make would be the
      // app misreporting its own history.
      _ => null,
    };
    if (message == null) {
      return;
    }
    ScaffoldMessenger.maybeOf(navigator.context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class const _EntryTile({required final EntryRecord record})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: JournalView.entryKey(record.id),
    title: Text(
      // Month, day and year: a journal spans years.
      MaterialLocalizations.of(context).formatShortDate(record.createdAt),
    ),
    subtitle: Text(
      record.summary,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    onTap: () {
      unawaited(context.read<JournalAnalytics>().entryOpened());
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EntryPage(record: record)),
      );
    },
  );
}

class const _Failure() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        const Text(JournalView.failureMessage, textAlign: TextAlign.center),
        FilledButton(
          key: JournalView.retryKey,
          onPressed: () =>
              context.read<JournalBloc>().add(const JournalEvent.loaded()),
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}
