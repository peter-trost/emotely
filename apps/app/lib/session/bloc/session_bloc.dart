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
class SessionBloc({required final AgentClient _agentClient})
    extends Bloc<SessionEvent, SessionState> {
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

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) =>
      _round(emit, _agentClient.advance);

  Future<void> _onAnswered(
    SessionAnswered event,
    Emitter<SessionState> emit,
  ) async {
    if (state case SessionAwaitingAnswer(:final pending)) {
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

  Future<void> _onRetried(SessionRetried event, Emitter<SessionState> emit) =>
      _round(emit, _lastRound);

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
        Completed(:final entry) => SessionState.completed(
          entry: entry,
          questions: Map<String, AskQuestion>.unmodifiable(_asked),
        ),
      });
    } on AgentException catch (error) {
      emit(SessionState.failure(message: error.message));
    } on Exception {
      emit(
        const SessionState.failure(
          message: 'Could not reach the journaling assistant.',
        ),
      );
    }
  }

  SessionState _await(PendingQuestion pending) {
    _asked[pending.question.questionId] = pending.question;
    return SessionState.awaitingAnswer(
      pending: pending,
      answered: _asked.length - 1,
    );
  }
}
