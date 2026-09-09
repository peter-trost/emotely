import 'dart:async';

import 'package:emotely/analytics/journal_analytics.dart';
import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/journal/bloc/journal_bloc.dart';
import 'package:emotely/journal/journal_models.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:emotely/journal/view/entry_page.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Home: the journal so far and the way into the next session.
class const JournalPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => JournalBloc(
      store: context.read<JournalStore>(),
      analytics: context.read<JournalAnalytics>(),
    )..add(const JournalEvent.loaded()),
    child: const JournalView(),
  );
}

/// One widget per [JournalState]; entries and the session card when ready.
class const JournalView({super.key}) extends StatelessWidget {
  static const startKey = Key('journal_view.start');
  static const continueKey = Key('journal_view.continue');
  static const discardKey = Key('journal_view.discard');
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
  static Future<void> _open(
    BuildContext context, {
    required OpenSession? resume,
  }) async {
    final journal = context.read<JournalBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SessionPage(resume: resume)),
    );
    journal.add(const JournalEvent.loaded());
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
