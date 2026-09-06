import 'dart:async';

import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/app/environment.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/bloc/session_bloc.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/widgets/answer_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wires a [SessionBloc] to the [AgentClient] in scope and starts a session.
class const SessionPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SessionBloc(
      agentClient: context.read<AgentClient>(),
      analytics: context.read<SessionAnalytics>(),
    )..add(const SessionEvent.started()),
    child: const SessionView(),
  );
}

/// One journaling session, one widget per [SessionState].
class const SessionView({super.key}) extends StatelessWidget {
  static const retryKey = Key('session_view.retry');
  static const questionKey = Key('session_view.question');
  static const updateRequiredKey = Key('session_view.update_required');
  static const updateKey = Key('session_view.update');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Journaling session')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) => switch (state) {
            SessionInitial() || SessionLoading() => const _Thinking(),
            SessionAwaitingAnswer(:final pending, :final answered) => _Question(
              pending: pending,
              answered: answered,
            ),
            SessionCompleted(:final entry, :final questions) => EntryView(
              entry: entry,
              questions: questions,
            ),
            SessionFailure(:final message) => _Failure(message: message),
            SessionUpdateRequired(:final minAppVersion) => _UpdateRequired(
              minAppVersion: minAppVersion,
            ),
          },
        ),
      ),
    ),
  );
}

class const _Thinking() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [CircularProgressIndicator(), Text('Thinking…')],
    ),
  );
}

class const _Question({
  required final PendingQuestion pending,
  required final int answered,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text('Question ${answered + 1}', style: theme.textTheme.labelLarge),
          Text(
            pending.question.question,
            key: SessionView.questionKey,
            style: theme.textTheme.headlineSmall,
          ),
          AnswerInput(
            // A new tool call gets a fresh widget, never a stale draft.
            key: ValueKey(pending.toolCallId),
            question: pending.question,
            onSubmit: (answer) =>
                context.read<SessionBloc>().add(SessionEvent.answered(answer)),
          ),
        ],
      ),
    );
  }
}

/// The force-update screen: no retry, no way around it. This is what lets
/// the server delete deprecated wire shapes instead of keeping them (#37).
class const _UpdateRequired({required final String minAppVersion})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    key: SessionView.updateRequiredKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Text(
          'This version of emotely is no longer supported. '
          'Please update to $minAppVersion or newer to continue.',
          textAlign: TextAlign.center,
        ),
        FilledButton(
          key: SessionView.updateKey,
          // Fire-and-forget: if the store cannot open there is nothing the
          // screen can do about it, and it must stay blocking either way.
          onPressed: () => unawaited(
            launchUrl(
              Uri.parse(storeUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

class const _Failure({required final String message}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Text(message, textAlign: TextAlign.center),
        FilledButton(
          key: SessionView.retryKey,
          onPressed: () =>
              context.read<SessionBloc>().add(const SessionEvent.retried()),
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}
