// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AwaitingAnswer _$AwaitingAnswerFromJson(Map<String, dynamic> json) =>
    AwaitingAnswer(
      transcript: json['transcript'] as List<dynamic>,
      signature: json['signature'] as String,
      promptId: json['promptId'] as String,
      pending: PendingQuestion.fromJson(
        json['pending'] as Map<String, dynamic>,
      ),
      $type: json['status'] as String?,
    );

Map<String, dynamic> _$AwaitingAnswerToJson(AwaitingAnswer instance) =>
    <String, dynamic>{
      'transcript': instance.transcript,
      'signature': instance.signature,
      'promptId': instance.promptId,
      'pending': instance.pending.toJson(),
      'status': instance.$type,
    };

Completed _$CompletedFromJson(Map<String, dynamic> json) => Completed(
  transcript: json['transcript'] as List<dynamic>,
  signature: json['signature'] as String,
  promptId: json['promptId'] as String,
  entry: JournalEntry.fromJson(json['entry'] as Map<String, dynamic>),
  $type: json['status'] as String?,
);

Map<String, dynamic> _$CompletedToJson(Completed instance) => <String, dynamic>{
  'transcript': instance.transcript,
  'signature': instance.signature,
  'promptId': instance.promptId,
  'entry': instance.entry.toJson(),
  'status': instance.$type,
};

_PendingQuestion _$PendingQuestionFromJson(Map<String, dynamic> json) =>
    _PendingQuestion(
      toolCallId: json['toolCallId'] as String,
      question: AskQuestion.fromJson(json['question'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PendingQuestionToJson(_PendingQuestion instance) =>
    <String, dynamic>{
      'toolCallId': instance.toolCallId,
      'question': instance.question.toJson(),
    };

_JournalEntry _$JournalEntryFromJson(Map<String, dynamic> json) =>
    _JournalEntry(
      summary: json['summary'] as String,
      answers: (json['answers'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Answer.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$JournalEntryToJson(_JournalEntry instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'answers': instance.answers.map((k, e) => MapEntry(k, e.toJson())),
    };
