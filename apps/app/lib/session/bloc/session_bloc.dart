import 'dart:async';

import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_bloc.freezed.dart';
part 'session_event.dart';
part 'session_state.dart';

/// Drives one journaling session: start, answer question after question,
/// finish with the entry. All state the server needs travels in the signed
/// transcript this bloc holds between rounds.
///
/// Analytics calls are fire-and-forget: they describe the session, they
/// never gate it.
class SessionBloc({
  required final AgentClient _agentClient,
  required final SessionAnalytics _analytics,
}) extends Bloc<SessionEvent, SessionState> {
  this : super(const SessionState.initial()) {
    on<SessionStarted>(_onStarted);
    on<SessionAnswered>(_onAnswered);
    on<SessionRetried>(_onRetried);
  }

  List<Object?>? _transcript;
  String? _signature;
  final _asked = <String, AskQuestion>{};

  /// The round to repeat on retry; the transcript never changes on failure,
  /// so replaying the exact same request is always safe.
  late Future<AdvanceResponse> Function() _lastRound;

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) {
    unawaited(_analytics.sessionStarted());
    return _round(emit, _agentClient.advance);
  }

  Future<void> _onAnswered(
    SessionAnswered event,
    Emitter<SessionState> emit,
  ) async {
    if (state case SessionAwaitingAnswer(:final pending)) {
      unawaited(_analytics.answerSubmitted(question: pending.question));
      await _round(
        emit,
        () => _agentClient.advance(
          transcript: _transcript,
          signature: _signature,
          answer: (
            toolCallId: pending.toolCallId,
            value: event.answer.wireValue,
          ),
        ),
      );
    }
  }

  Future<void> _onRetried(SessionRetried event, Emitter<SessionState> emit) {
    unawaited(_analytics.sessionRetried());
    return _round(emit, _lastRound);
  }

  Future<void> _round(
    Emitter<SessionState> emit,
    Future<AdvanceResponse> Function() round,
  ) async {
    _lastRound = round;
    emit(SessionState.loading(answered: _asked.length));
    try {
      final response = await round();
      _transcript = response.transcript;
      _signature = response.signature;
      emit(switch (response) {
        AwaitingAnswer(:final pending) => _await(pending),
        Completed(:final entry) => _complete(entry),
      });
    } on AgentException catch (error) {
      unawaited(_analytics.sessionFailed(statusCode: error.statusCode));
      emit(SessionState.failure(message: error.message));
    } on Exception {
      unawaited(_analytics.sessionFailed());
      emit(
        const SessionState.failure(
          message: 'Could not reach the journaling assistant.',
        ),
      );
    }
  }

  SessionState _await(PendingQuestion pending) {
    final index = _asked.length;
    _asked[pending.question.questionId] = pending.question;
    unawaited(
      _analytics.questionAsked(question: pending.question, index: index),
    );
    return SessionState.awaitingAnswer(pending: pending, answered: index);
  }

  SessionState _complete(JournalEntry entry) {
    unawaited(_analytics.sessionCompleted(answers: entry.answers.length));
    return SessionState.completed(
      entry: entry,
      questions: Map<String, AskQuestion>.unmodifiable(_asked),
    );
  }
}
