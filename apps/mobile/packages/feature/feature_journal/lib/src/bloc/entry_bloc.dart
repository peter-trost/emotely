import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:journal_repository/journal_repository.dart';

part 'entry_bloc.freezed.dart';
part 'entry_event.dart';
part 'entry_state.dart';

/// One filed entry, read back by its id: the entry screen is reached by
/// its location alone (ADR 0016), so it asks the journal for the entry
/// rather than being handed one.
class EntryBloc({required final JournalRepository _repository})
    extends Bloc<EntryEvent, EntryState> {
  this : super(const EntryState.loading()) {
    on<EntryLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(EntryLoaded event, Emitter<EntryState> emit) async {
    emit(const EntryState.loading());
    try {
      final record = await _repository.entry(event.entryId);
      // An entry that is gone is not an error of the app's, but there is
      // nothing to show either; the screen says so and offers to look again.
      emit(
        record == null
            ? const EntryState.failure()
            : EntryState.ready(record: record),
      );
    } on Exception {
      emit(const EntryState.failure());
    }
  }
}
