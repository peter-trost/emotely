// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColorAnswer _$ColorAnswerFromJson(Map<String, dynamic> json) => ColorAnswer(
  (json['value'] as List<dynamic>)
      .map((e) => const HexColorConverter().fromJson(e as String))
      .toList(),
  $type: json['answer_type'] as String?,
);

Map<String, dynamic> _$ColorAnswerToJson(ColorAnswer instance) =>
    <String, dynamic>{
      'value': instance.value.map(const HexColorConverter().toJson).toList(),
      'answer_type': instance.$type,
    };

EmojiAnswer _$EmojiAnswerFromJson(Map<String, dynamic> json) => EmojiAnswer(
  (json['value'] as List<dynamic>).map((e) => e as String).toList(),
  $type: json['answer_type'] as String?,
);

Map<String, dynamic> _$EmojiAnswerToJson(EmojiAnswer instance) =>
    <String, dynamic>{'value': instance.value, 'answer_type': instance.$type};

LongtextAnswer _$LongtextAnswerFromJson(Map<String, dynamic> json) =>
    LongtextAnswer(
      json['value'] as String,
      $type: json['answer_type'] as String?,
    );

Map<String, dynamic> _$LongtextAnswerToJson(LongtextAnswer instance) =>
    <String, dynamic>{'value': instance.value, 'answer_type': instance.$type};

RatingAnswer _$RatingAnswerFromJson(Map<String, dynamic> json) => RatingAnswer(
  (json['value'] as num).toInt(),
  $type: json['answer_type'] as String?,
);

Map<String, dynamic> _$RatingAnswerToJson(RatingAnswer instance) =>
    <String, dynamic>{'value': instance.value, 'answer_type': instance.$type};

TextListAnswer _$TextListAnswerFromJson(Map<String, dynamic> json) =>
    TextListAnswer(
      (json['value'] as List<dynamic>).map((e) => e as String).toList(),
      $type: json['answer_type'] as String?,
    );

Map<String, dynamic> _$TextListAnswerToJson(TextListAnswer instance) =>
    <String, dynamic>{'value': instance.value, 'answer_type': instance.$type};
