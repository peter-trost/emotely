import 'dart:async';

import 'package:analytics/analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:journal_repository/journal_repository.dart';

part 'journal_bloc.freezed.dart';
part 'journal_event.dart';
part 'journal_state.dart';

/// The journal as the home screen shows it: every filed entry, and the
/// session still in progress if there is one.
class JournalBloc({
  required final JournalRepository _repository,
  required final JournalAnalytics _analytics,
}) extends Bloc<JournalEvent, JournalState> {
  this : super(const JournalState.loading()) {
    on<JournalLoaded>(_onLoaded);
    on<JournalSessionDiscarded>(_onSessionDiscarded);
  }

  Future<void> _onLoaded(
    JournalLoaded event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalState.loading());
    try {
      final entries = await _repository.entries();
      final openSession = await _repository.openSession();
      unawaited(
        _analytics.journalViewed(
          entries: entries.length,
          openSession: openSession != null,
        ),
      );
      emit(JournalState.ready(entries: entries, openSession: openSession));
    } on Exception {
      emit(const JournalState.failure());
    }
  }

  Future<void> _onSessionDiscarded(
    JournalSessionDiscarded event,
    Emitter<JournalState> emit,
  ) async {
    if (state case JournalReady(openSession: final session?)) {
      emit(const JournalState.loading());
      try {
        await _repository.discardSession(session.id);
        unawaited(_analytics.sessionDiscarded());
      } on Exception {
        emit(const JournalState.failure());
        return;
      }
      await _onLoaded(const JournalLoaded(), emit);
    }
  }
}
