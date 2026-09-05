import 'package:emotely/contract/contract.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'advance_response.freezed.dart';
part 'advance_response.g.dart';

/// What `POST /api/advance-session` answers with: either the next question
/// to render or the finished entry, always with the re-signed transcript.
///
/// The HTTP envelope is camelCase (it is JS-side JSON); only the tool
/// payloads inside it follow the snake_case contract.
@Freezed(unionKey: 'status')
sealed class AdvanceResponse with _$AdvanceResponse {
  @JsonSerializable(fieldRename: FieldRename.none)
  const factory awaitingAnswer({
    required List<Object?> transcript,
    required String signature,
    required String promptId,
    required PendingQuestion pending,
  }) = AwaitingAnswer;

  @JsonSerializable(fieldRename: FieldRename.none)
  const factory completed({
    required List<Object?> transcript,
    required String signature,
    required String promptId,
    required JournalEntry entry,
  }) = Completed;

  factory fromJson(Map<String, dynamic> json) =>
      _$AdvanceResponseFromJson(json);
}

/// The `ask_question` tool call the client must answer next.
@freezed
abstract class PendingQuestion with _$PendingQuestion {
  @JsonSerializable(fieldRename: FieldRename.none)
  const factory({required String toolCallId, required AskQuestion question}) =
      _PendingQuestion;

  factory fromJson(Map<String, dynamic> json) =>
      _$PendingQuestionFromJson(json);
}

/// The completed session: the agent's summary and every recorded answer,
/// keyed by question id.
@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory({
    required String summary,
    required Map<String, Answer> answers,
  }) = _JournalEntry;

  factory fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);
}
