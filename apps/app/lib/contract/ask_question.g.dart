// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AskQuestion _$AskQuestionFromJson(Map<String, dynamic> json) => _AskQuestion(
  questionId: json['question_id'] as String,
  question: json['question'] as String,
  answerType: $enumDecode(_$AnswerTypeEnumMap, json['answer_type']),
);

Map<String, dynamic> _$AskQuestionToJson(_AskQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question': instance.question,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
    };

const _$AnswerTypeEnumMap = {
  AnswerType.color: 'color',
  AnswerType.emoji: 'emoji',
  AnswerType.longtext: 'longtext',
  AnswerType.rating: 'rating',
  AnswerType.textList: 'text_list',
};
