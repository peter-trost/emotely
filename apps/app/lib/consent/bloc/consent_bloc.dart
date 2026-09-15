import 'dart:async';

import 'package:emotely/analytics/consent_analytics.dart';
import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/consent/consent_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent_bloc.freezed.dart';
part 'consent_event.dart';
part 'consent_state.dart';

/// Whether the user has given the explicit consent (Art. 9 (2) (a) GDPR)
/// that a session needs, and the two acts that change it.
///
/// The answer always comes from the server ([ConsentStore]), never from a
/// flag on this device: a reinstall must not lose it and must not invent it.
/// Every screen that can start a session asks this bloc first, and a session
/// never starts on a consent that was not written down — if the write fails,
/// the state says so and the gate stays shut.
class ConsentBloc({
  required final ConsentStore _store,
  required final ConsentAnalytics _analytics,
  required final ErrorReporter _errors,
}) extends Bloc<ConsentEvent, ConsentState> {
  this : super(const ConsentState.unknown()) {
    on<ConsentLoaded>(_onLoaded);
    on<ConsentGranted>(_onGranted);
    on<ConsentWithdrawn>(_onWithdrawn);
    on<ConsentDeclined>(_onDeclined);
  }

  Future<void> _onLoaded(
    ConsentLoaded event,
    Emitter<ConsentState> emit,
  ) async {
    emit(const ConsentState.unknown());
    try {
      emit(ConsentState.known(granted: await _store.isGranted()));
    } on Exception catch (error, stackTrace) {
      unawaited(_errors.consentLoadFailed(error, stackTrace));
      emit(const ConsentState.failure());
    }
  }

  /// The user ticked the box and pressed the button. The session may start
  /// only once the server has the record, so the failure path emits a
  /// failure rather than a granted state.
  Future<void> _onGranted(
    ConsentGranted event,
    Emitter<ConsentState> emit,
  ) async {
    // A second tap while the first is in flight would write the same row
    // again (harmlessly) but could race the state back to `busy` after the
    // screen had already left. One at a time.
    if (state is ConsentBusy) {
      return;
    }
    emit(const ConsentState.busy());
    try {
      await _store.grant();
    } on Exception catch (error, stackTrace) {
      unawaited(_errors.consentWriteFailed(error, stackTrace));
      emit(const ConsentState.writeFailure());
      return;
    }
    unawaited(_analytics.consentGranted());
    emit(const ConsentState.known(granted: true));
  }

  /// The user took their consent back (Art. 7 (3)). Same shape as granting,
  /// because taking it back must be no harder than giving it.
  Future<void> _onWithdrawn(
    ConsentWithdrawn event,
    Emitter<ConsentState> emit,
  ) async {
    if (state is ConsentBusy) {
      return;
    }
    emit(const ConsentState.busy());
    try {
      await _store.withdraw();
    } on Exception catch (error, stackTrace) {
      unawaited(_errors.consentWriteFailed(error, stackTrace));
      emit(const ConsentState.withdrawFailure());
      return;
    }
    unawaited(_analytics.consentWithdrawn());
    emit(const ConsentState.known(granted: false));
  }

  /// The user declined. Nothing is written: a refusal is the absence of a
  /// consent, not a record of its own, and inventing a row for it would be
  /// storing a decision the user did not ask us to keep.
  void _onDeclined(ConsentDeclined event, Emitter<ConsentState> emit) {
    unawaited(_analytics.consentDeclined());
    emit(const ConsentState.known(granted: false));
  }
}
