import 'package:emotely/session/agent/advance_response.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/bloc/session_bloc.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/widgets/answer_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Wires a [SessionBloc] to the [AgentClient] in scope and starts a session.
class const SessionPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        SessionBloc(agentClient: context.read<AgentClient>())
          ..add(const SessionEvent.started()),
    child: const SessionView(),
  );
}

/// One journaling session, one widget per [SessionState].
class const SessionView({super.key}) extends StatelessWidget {
  static const retryKey = Key('session_view.retry');
  static const questionKey = Key('session_view.question');

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
