import 'dart:async';

import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/contract/contract.dart';
import 'package:emotely/journal/journal_store.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

part 'session_bloc.freezed.dart';
part 'session_event.dart';
part 'session_state.dart';

/// Drives one journaling session: start, answer question after question,
/// finish with the entry. All state the server needs travels in the signed
/// transcript this bloc holds between rounds, and every round is written to
/// the user's journal so nothing is lost with the app (ADR 0010).
///
/// Analytics calls are fire-and-forget: they describe the session, they
/// never gate it.
class SessionBloc({
  required final AgentClient _agentClient,
  required final SessionAnalytics _analytics,
  required final JournalStore _store,
}) extends Bloc<SessionEvent, SessionState> {
  this : super(const SessionState.initial()) {
    on<SessionStarted>(_onStarted);
    on<SessionAnswered>(_onAnswered);
    on<SessionRetried>(_onRetried);
  }

  /// The failure copy when the finished entry could not be filed.
  static const entrySaveFailedMessage =
      'Your entry could not be saved. Please try again.';

  List<Object?>? _transcript;
  String? _signature;
  String? _sessionId;
  final _asked = <String, AskQuestion>{};

  /// What to repeat on retry: the model round that failed, or the filing of
  /// an entry the model already produced. Neither changes state on failure,
  /// so repeating is always safe.
  late Future<void> Function(Emitter<SessionState> emit) _retry;

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
          answer: (toolCallId: pending.toolCallId, answer: event.answer),
        ),
      );
    }
  }

  Future<void> _onRetried(SessionRetried event, Emitter<SessionState> emit) {
    unawaited(_analytics.sessionRetried());
    return _retry(emit);
  }

  Future<void> _round(
    Emitter<SessionState> emit,
    Future<AdvanceResponse> Function() round,
  ) async {
    _retry = (emit) => _round(emit, round);
    emit(SessionState.loading(answered: _asked.length));
    try {
      final response = await round();
      if (_requiresUpdate(response.minAppVersion)) {
        emit(
          SessionState.updateRequired(minAppVersion: response.minAppVersion!),
        );
        return;
      }
      _transcript = response.transcript;
      _signature = response.signature;
      switch (response) {
        case AwaitingAnswer(:final pending):
          final next = _await(pending);
          await _save(pending);
          emit(next);
        case Completed(:final entry):
          await _file(entry, emit);
      }
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

  /// Whether the server's [minAppVersion] is newer than the version this
  /// app reported. No minimum, or one this app already meets, never blocks.
  bool _requiresUpdate(String? minAppVersion) {
    if (minAppVersion == null) {
      return false;
    }
    final blocked =
        Version.parse(minAppVersion) > Version.parse(_agentClient.appVersion);
    if (blocked) {
      unawaited(
        _analytics.updateRequired(
          minAppVersion: minAppVersion,
          appVersion: _agentClient.appVersion,
        ),
      );
    }
    return blocked;
  }

  SessionState _await(PendingQuestion pending) {
    final index = _asked.length;
    _asked[pending.question.questionId] = pending.question;
    unawaited(
      _analytics.questionAsked(question: pending.question, index: index),
    );
    return SessionState.awaitingAnswer(pending: pending, answered: index);
  }

  /// Writes the round to the journal. Best effort: a round that cannot be
  /// saved is still a round, and the row is created on completion at the
  /// latest; the entry is what must not be lost.
  Future<void> _save(PendingQuestion? pending) async {
    try {
      _sessionId = await _store.saveRound(
        sessionId: _sessionId,
        transcript: _transcript!,
        signature: _signature!,
        pending: pending,
        questions: _asked.values,
        appVersion: _agentClient.appVersion,
      );
    } on Exception {
      unawaited(_analytics.sessionSaveFailed());
    }
  }

  /// Files the finished [entry]; the session is only over once it is in the
  /// journal, so a failure here is a failure with a retry, not an entry
  /// shown once and gone.
  Future<void> _file(JournalEntry entry, Emitter<SessionState> emit) async {
    _retry = (emit) => _file(entry, emit);
    emit(SessionState.loading(answered: _asked.length));
    try {
      _sessionId ??= await _store.saveRound(
        sessionId: null,
        transcript: _transcript!,
        signature: _signature!,
        pending: null,
        questions: _asked.values,
        appVersion: _agentClient.appVersion,
      );
      await _store.completeSession(
        sessionId: _sessionId!,
        entry: entry,
        questions: _asked.values,
      );
    } on Exception {
      unawaited(_analytics.entrySaveFailed());
      emit(const SessionState.failure(message: entrySaveFailedMessage));
      return;
    }
    unawaited(_analytics.sessionCompleted(answers: entry.answers.length));
    emit(
      SessionState.completed(
        entry: entry,
        questions: Map<String, AskQuestion>.unmodifiable(_asked),
      ),
    );
  }
}
