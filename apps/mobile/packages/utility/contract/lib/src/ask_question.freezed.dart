// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ask_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AskQuestion {

/// Stable id of the question within its question set.
 String get questionId;/// The question text to show the user.
 String get question;/// Which widget to render.
 AnswerType get answerType;
/// Create a copy of AskQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AskQuestionCopyWith<AskQuestion> get copyWith => _$AskQuestionCopyWithImpl<AskQuestion>(this as AskQuestion, _$identity);

  /// Serializes this AskQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AskQuestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AskQuestion&&(identical(other.questionId, _this.questionId) || other.questionId == _this.questionId)&&(identical(other.question, _this.question) || other.question == _this.question)&&(identical(other.answerType, _this.answerType) || other.answerType == _this.answerType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AskQuestion;
  return Object.hash(runtimeType,_this.questionId,_this.question,_this.answerType);
}

@override
String toString() {
  final _this = this as AskQuestion;
  return 'AskQuestion(questionId: ${_this.questionId}, question: ${_this.question}, answerType: ${_this.answerType})';
}


}

/// @nodoc
abstract mixin class $AskQuestionCopyWith<$Res>  {
  factory $AskQuestionCopyWith(AskQuestion value, $Res Function(AskQuestion) _then) = _$AskQuestionCopyWithImpl;
@useResult
$Res call({
 String questionId, String question, AnswerType answerType
});




}
/// @nodoc
class _$AskQuestionCopyWithImpl<$Res>
    implements $AskQuestionCopyWith<$Res> {
  _$AskQuestionCopyWithImpl(this._self, this._then);

  final AskQuestion _self;
  final $Res Function(AskQuestion) _then;

/// Create a copy of AskQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? question = null,Object? answerType = null,}) {
  return _then(AskQuestion(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answerType: null == answerType ? _self.answerType : answerType // ignore: cast_nullable_to_non_nullable
as AnswerType,
  ));
}

}


/// Adds pattern-matching-related methods to [AskQuestion].
extension AskQuestionPatterns on AskQuestion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AskQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AskQuestion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AskQuestion value)  $default,){
final _that = this;
switch (_that) {
case _AskQuestion():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AskQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _AskQuestion() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String question,  AnswerType answerType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AskQuestion() when $default != null:
return $default(_that.questionId,_that.question,_that.answerType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String question,  AnswerType answerType)  $default,) {final _that = this;
switch (_that) {
case _AskQuestion():
return $default(_that.questionId,_that.question,_that.answerType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String question,  AnswerType answerType)?  $default,) {final _that = this;
switch (_that) {
case _AskQuestion() when $default != null:
return $default(_that.questionId,_that.question,_that.answerType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AskQuestion implements AskQuestion {
  const _AskQuestion({required this.questionId, required this.question, required this.answerType});
  factory _AskQuestion.fromJson(Map<String, dynamic> json) => _$AskQuestionFromJson(json);

/// Stable id of the question within its question set.
@override final  String questionId;
/// The question text to show the user.
@override final  String question;
/// Which widget to render.
@override final  AnswerType answerType;

/// Create a copy of AskQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AskQuestionCopyWith<_AskQuestion> get copyWith => __$AskQuestionCopyWithImpl<_AskQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AskQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AskQuestion&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.question, question) || other.question == question)&&(identical(other.answerType, answerType) || other.answerType == answerType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,questionId,question,answerType);
}

@override
String toString() {
    return 'AskQuestion(questionId: $questionId, question: $question, answerType: $answerType)';
}


}

/// @nodoc
abstract mixin class _$AskQuestionCopyWith<$Res> implements $AskQuestionCopyWith<$Res> {
  factory _$AskQuestionCopyWith(_AskQuestion value, $Res Function(_AskQuestion) _then) = __$AskQuestionCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String question, AnswerType answerType
});




}
/// @nodoc
class __$AskQuestionCopyWithImpl<$Res>
    implements _$AskQuestionCopyWith<$Res> {
  __$AskQuestionCopyWithImpl(this._self, this._then);

  final _AskQuestion _self;
  final $Res Function(_AskQuestion) _then;

/// Create a copy of AskQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? question = null,Object? answerType = null,}) {
  return _then(_AskQuestion(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answerType: null == answerType ? _self.answerType : answerType // ignore: cast_nullable_to_non_nullable
as AnswerType,
  ));
}


}

// dart format on
