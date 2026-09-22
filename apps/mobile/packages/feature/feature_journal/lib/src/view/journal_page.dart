import 'dart:async';

import 'package:feature_journal/src/bloc/journal_bloc.dart';
import 'package:feature_journal/src/navigator.dart';
import 'package:feature_journal/src/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:journal_repository/journal_repository.dart';
import 'package:material_ui/material_ui.dart';

/// Home: the journal so far and the way into the next session.
///
/// Everything it leads to — the session, the consent screen, and its own
/// entries on their routes — is the app's to show, so it asks for them
/// through [JournalNavigator] (ADR 0015, ADR 0016).
class const JournalPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.I<JournalBloc>()..add(const JournalEvent.loaded()),
    child: const JournalView(),
  );
}

/// One widget per [JournalState]; entries and the session card when ready.
class const JournalView({super.key}) extends StatelessWidget {
  static const startKey = Key('journal_view.start');
  static const continueKey = Key('journal_view.continue');
  static const discardKey = Key('journal_view.discard');
  static const retryKey = Key('journal_view.retry');
  static const emptyKey = Key('journal_view.empty');
  static Key entryKey(String id) => Key('journal_view.entry.$id');

  static const failureMessage = 'Could not load your journal.';

  @override
  Widget build(BuildContext context) => Scaffold(
    // The account and signing out live on the More tab, next to it.
    appBar: AppBar(title: const Text('Your journal')),
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
          onPressed: () => unawaited(_open(context, resume: session.id)),
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
  /// app asking rather than as an error. The answer comes from the server
  /// before every session, never from what this device read at launch.
  static Future<void> _open(
    BuildContext context, {
    required String? resume,
  }) async {
    final journal = context.read<JournalBloc>();
    final app = GetIt.I<JournalNavigator>();
    // Each await is a server round trip; a page that is gone by the time
    // the answer arrives navigates nowhere on its own behalf.
    if (!await journal.consentStands()) {
      if (!context.mounted || !await app.requestConsent(context)) {
        return;
      }
    }
    if (!context.mounted) {
      return;
    }
    await app.startSession(context, resume: resume);
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
      context.read<JournalBloc>().add(const JournalEvent.entryOpened());
      // The journal's own screen, on the journal's own route (ADR 0016).
      EntryRoute(id: record.id).go(context);
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
