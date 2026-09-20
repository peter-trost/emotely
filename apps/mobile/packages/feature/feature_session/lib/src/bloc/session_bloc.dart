import 'dart:async';

import 'package:agent_client/agent_client.dart';
import 'package:analytics/analytics.dart';
import 'package:contract/contract.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:journal_repository/journal_repository.dart';

part 'session_bloc.freezed.dart';
part 'session_event.dart';
part 'session_state.dart';

/// Drives one journaling session: start, answer question after question,
/// finish with the entry. All state the server needs travels in the signed
/// transcript this bloc holds between rounds, and every round is written to
/// the user's journal so nothing is lost with the app (ADR 0010).
///
/// Analytics and error reports are fire-and-forget: they describe the
/// session, they never gate it.
class SessionBloc({
  required final AgentClient _agentClient,
  required final SessionAnalytics _analytics,
  required final ErrorReporter _errors,
  required final JournalRepository _repository,
}) extends Bloc<SessionEvent, SessionState> {
  this : super(const SessionState.initial()) {
    on<SessionStarted>(_onStarted);
    on<SessionAnswered>(_onAnswered);
    on<SessionRetried>(_onRetried);
  }

  /// The failure copy when the finished entry could not be filed.
  static const entrySaveFailedMessage =
      'Your entry could not be saved. Please try again.';

  /// The failure copy when the session to resume could not be read back.
  static const sessionReadFailedMessage =
      'Could not load your unfinished session. Please try again.';

  /// What the server answers when the gateway refused the round: the model
  /// could not be reached, so no amount of retrying now will help.
  static const modelUnavailableStatus = 502;

  /// The failure copy for [modelUnavailableStatus]. Says the three things
  /// the user needs and nothing more: it is us and not their connection,
  /// what they have written is safe, and waiting is the thing that helps.
  /// The server's own message never reaches here — it names models and
  /// providers the client has no business showing (#107).
  static const modelUnavailableMessage =
      'The journaling assistant is unavailable right now. This is not your '
      'connection, and your entry is safe. Please try again later.';

  List<Object?>? _transcript;
  String? _signature;
  String? _sessionId;
  final _asked = <String, AskQuestion>{};

  /// What to repeat on retry: the model round that failed, or the filing of
  /// an entry the model already produced. Neither changes state on failure,
  /// so repeating is always safe.
  late Future<void> Function(Emitter<SessionState> emit) _retry;

  Future<void> _onStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    if (event.resume) {
      _retry = (emit) => _onStarted(event, emit);
      emit(const SessionState.loading(answered: 0));
      final OpenSession? stored;
      try {
        stored = await _repository.openSession();
      } on Exception catch (error, stackTrace) {
        unawaited(_analytics.sessionFailed());
        unawaited(_errors.sessionFailed(error, stackTrace));
        emit(const SessionState.failure(message: sessionReadFailedMessage));
        return;
      }
      // Gone in the meantime — discarded on another device, or finished
      // there: the offer was the journal's, the answer is the server's.
      if (stored != null) {
        await _resume(stored, emit);
        return;
      }
    }
    unawaited(_analytics.sessionStarted());
    await _round(emit, _agentClient.advance);
  }

  /// Picks a stored session up: the pending question goes straight back on
  /// screen. A row saved after the last answer but before its entry was
  /// filed has no pending question; the agent finishes it again.
  Future<void> _resume(OpenSession session, Emitter<SessionState> emit) {
    unawaited(_analytics.sessionResumed());
    _sessionId = session.id;
    _transcript = session.transcript;
    _signature = session.signature;
    _asked.addEntries([
      for (final question in session.questions)
        MapEntry(question.questionId, question),
    ]);
    if (session.pending case final pending?) {
      _asked[pending.question.questionId] = pending.question;
      emit(
        SessionState.awaitingAnswer(
          pending: pending,
          answered: _asked.length - 1,
        ),
      );
      return Future.value();
    }
    return _round(
      emit,
      () =>
          _agentClient.advance(transcript: _transcript, signature: _signature),
    );
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
    } on AgentException catch (error, stackTrace) {
      unawaited(_analytics.sessionFailed(statusCode: error.statusCode));
      unawaited(
        _errors.sessionFailed(error, stackTrace, statusCode: error.statusCode),
      );
      // A refused model is the one refusal the user can act on differently:
      // retrying now cannot succeed, so it gets copy of our own rather than
      // the server's. Every other status keeps the server's message, which
      // is written for the user (a rate limit, a bad request).
      emit(
        SessionState.failure(
          message: error.statusCode == modelUnavailableStatus
              ? modelUnavailableMessage
              : error.message,
        ),
      );
    } on Exception catch (error, stackTrace) {
      unawaited(_analytics.sessionFailed());
      unawaited(_errors.sessionFailed(error, stackTrace));
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

  /// Writes the round to the journal. Best effort: a round that cannot be
  /// saved is still a round, and the row is created on completion at the
  /// latest; the entry is what must not be lost.
  Future<void> _save(PendingQuestion? pending) async {
    try {
      _sessionId = await _repository.saveRound(
        sessionId: _sessionId,
        transcript: _transcript!,
        signature: _signature!,
        pending: pending,
        questions: _asked.values,
        appVersion: _agentClient.appVersion,
      );
    } on Exception catch (error, stackTrace) {
      unawaited(_analytics.sessionSaveFailed());
      unawaited(
        _errors.sessionSaveFailed(error, stackTrace, sessionId: _sessionId),
      );
    }
  }

  /// Counts the journal now that this entry is in it, so the third one can
  /// be marked (the survey trigger `third_entry_written`). Runs after the
  /// entry is persisted and after `session_completed`, and swallows its own
  /// failure: a milestone that cannot be counted is not worth a session.
  ///
  /// Swallowed towards the user, not towards us — the failure is reported,
  /// because the alternative is a milestone that stops firing and looks
  /// exactly like nobody reaching three entries.
  Future<void> _markMilestone() async {
    try {
      await _analytics.entryWritten(entries: await _repository.countEntries());
    } on Exception catch (error, stackTrace) {
      unawaited(_errors.entryMilestoneFailed(error, stackTrace));
    }
  }

  /// Files the finished [entry]; the session is only over once it is in the
  /// journal, so a failure here is a failure with a retry, not an entry
  /// shown once and gone.
  Future<void> _file(JournalEntry entry, Emitter<SessionState> emit) async {
    _retry = (emit) => _file(entry, emit);
    emit(SessionState.loading(answered: _asked.length));
    try {
      _sessionId ??= await _repository.saveRound(
        sessionId: null,
        transcript: _transcript!,
        signature: _signature!,
        pending: null,
        questions: _asked.values,
        appVersion: _agentClient.appVersion,
      );
      await _repository.completeSession(
        sessionId: _sessionId!,
        entry: entry,
        questions: _asked.values,
      );
    } on Exception catch (error, stackTrace) {
      unawaited(_analytics.entrySaveFailed());
      unawaited(
        _errors.entrySaveFailed(error, stackTrace, sessionId: _sessionId),
      );
      emit(const SessionState.failure(message: entrySaveFailedMessage));
      return;
    }
    unawaited(_analytics.sessionCompleted(answers: entry.answers.length));
    unawaited(_markMilestone());
    emit(
      SessionState.completed(
        entry: entry,
        questions: Map<String, AskQuestion>.unmodifiable(_asked),
      ),
    );
  }
}
