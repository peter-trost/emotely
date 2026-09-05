// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advance_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
AdvanceResponse _$AdvanceResponseFromJson(
  Map<String, dynamic> json
) {
        switch (json['status']) {
                  case 'awaiting_answer':
          return AwaitingAnswer.fromJson(
            json
          );
                case 'completed':
          return Completed.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'status',
  'AdvanceResponse',
  'Invalid union type "${json['status']}"!'
);
        }
      
}

/// @nodoc
mixin _$AdvanceResponse {

 List<Object?> get transcript; String get signature; String get promptId;
/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvanceResponseCopyWith<AdvanceResponse> get copyWith => _$AdvanceResponseCopyWithImpl<AdvanceResponse>(this as AdvanceResponse, _$identity);

  /// Serializes this AdvanceResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AdvanceResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvanceResponse&&const DeepCollectionEquality().equals(other.transcript, _this.transcript)&&(identical(other.signature, _this.signature) || other.signature == _this.signature)&&(identical(other.promptId, _this.promptId) || other.promptId == _this.promptId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AdvanceResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.transcript),_this.signature,_this.promptId);
}

@override
String toString() {
  final _this = this as AdvanceResponse;
  return 'AdvanceResponse(transcript: ${_this.transcript}, signature: ${_this.signature}, promptId: ${_this.promptId})';
}


}

/// @nodoc
abstract mixin class $AdvanceResponseCopyWith<$Res>  {
  factory $AdvanceResponseCopyWith(AdvanceResponse value, $Res Function(AdvanceResponse) _then) = _$AdvanceResponseCopyWithImpl;
@useResult
$Res call({
 List<Object?> transcript, String signature, String promptId
});




}
/// @nodoc
class _$AdvanceResponseCopyWithImpl<$Res>
    implements $AdvanceResponseCopyWith<$Res> {
  _$AdvanceResponseCopyWithImpl(this._self, this._then);

  final AdvanceResponse _self;
  final $Res Function(AdvanceResponse) _then;

/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transcript = null,Object? signature = null,Object? promptId = null,}) {
  return _then(_self.copyWith(
transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<Object?>,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,promptId: null == promptId ? _self.promptId : promptId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdvanceResponse].
extension AdvanceResponsePatterns on AdvanceResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AwaitingAnswer value)?  awaitingAnswer,TResult Function( Completed value)?  completed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AwaitingAnswer() when awaitingAnswer != null:
return awaitingAnswer(_that);case Completed() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AwaitingAnswer value)  awaitingAnswer,required TResult Function( Completed value)  completed,}){
final _that = this;
switch (_that) {
case AwaitingAnswer():
return awaitingAnswer(_that);case Completed():
return completed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AwaitingAnswer value)?  awaitingAnswer,TResult? Function( Completed value)?  completed,}){
final _that = this;
switch (_that) {
case AwaitingAnswer() when awaitingAnswer != null:
return awaitingAnswer(_that);case Completed() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Object?> transcript,  String signature,  String promptId,  PendingQuestion pending)?  awaitingAnswer,TResult Function( List<Object?> transcript,  String signature,  String promptId,  JournalEntry entry)?  completed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AwaitingAnswer() when awaitingAnswer != null:
return awaitingAnswer(_that.transcript,_that.signature,_that.promptId,_that.pending);case Completed() when completed != null:
return completed(_that.transcript,_that.signature,_that.promptId,_that.entry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Object?> transcript,  String signature,  String promptId,  PendingQuestion pending)  awaitingAnswer,required TResult Function( List<Object?> transcript,  String signature,  String promptId,  JournalEntry entry)  completed,}) {final _that = this;
switch (_that) {
case AwaitingAnswer():
return awaitingAnswer(_that.transcript,_that.signature,_that.promptId,_that.pending);case Completed():
return completed(_that.transcript,_that.signature,_that.promptId,_that.entry);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Object?> transcript,  String signature,  String promptId,  PendingQuestion pending)?  awaitingAnswer,TResult? Function( List<Object?> transcript,  String signature,  String promptId,  JournalEntry entry)?  completed,}) {final _that = this;
switch (_that) {
case AwaitingAnswer() when awaitingAnswer != null:
return awaitingAnswer(_that.transcript,_that.signature,_that.promptId,_that.pending);case Completed() when completed != null:
return completed(_that.transcript,_that.signature,_that.promptId,_that.entry);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.none)
class AwaitingAnswer implements AdvanceResponse {
  const AwaitingAnswer({required  List<Object?> transcript, required this.signature, required this.promptId, required this.pending,  String? $type}): _transcript = transcript,$type = $type ?? 'awaiting_answer';
  factory AwaitingAnswer.fromJson(Map<String, dynamic> json) => _$AwaitingAnswerFromJson(json);

 final  List<Object?> _transcript;
@override List<Object?> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override final  String signature;
@override final  String promptId;
 final  PendingQuestion pending;

@JsonKey(name: 'status')
final String $type;


/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AwaitingAnswerCopyWith<AwaitingAnswer> get copyWith => _$AwaitingAnswerCopyWithImpl<AwaitingAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AwaitingAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AwaitingAnswer&&const DeepCollectionEquality().equals(other.transcript, _transcript)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.promptId, promptId) || other.promptId == promptId)&&(identical(other.pending, pending) || other.pending == pending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcript),signature,promptId,pending);
}

@override
String toString() {
    return 'AdvanceResponse.awaitingAnswer(transcript: $transcript, signature: $signature, promptId: $promptId, pending: $pending)';
}


}

/// @nodoc
abstract mixin class $AwaitingAnswerCopyWith<$Res> implements $AdvanceResponseCopyWith<$Res> {
  factory $AwaitingAnswerCopyWith(AwaitingAnswer value, $Res Function(AwaitingAnswer) _then) = _$AwaitingAnswerCopyWithImpl;
@override @useResult
$Res call({
 List<Object?> transcript, String signature, String promptId, PendingQuestion pending
});


$PendingQuestionCopyWith<$Res> get pending;

}
/// @nodoc
class _$AwaitingAnswerCopyWithImpl<$Res>
    implements $AwaitingAnswerCopyWith<$Res> {
  _$AwaitingAnswerCopyWithImpl(this._self, this._then);

  final AwaitingAnswer _self;
  final $Res Function(AwaitingAnswer) _then;

/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcript = null,Object? signature = null,Object? promptId = null,Object? pending = null,}) {
  return _then(AwaitingAnswer(
transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<Object?>,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,promptId: null == promptId ? _self.promptId : promptId // ignore: cast_nullable_to_non_nullable
as String,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as PendingQuestion,
  ));
}

/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingQuestionCopyWith<$Res> get pending {
  
  return $PendingQuestionCopyWith<$Res>(_self.pending, (value) {
    return _then(_self.copyWith(pending: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.none)
class Completed implements AdvanceResponse {
  const Completed({required  List<Object?> transcript, required this.signature, required this.promptId, required this.entry,  String? $type}): _transcript = transcript,$type = $type ?? 'completed';
  factory Completed.fromJson(Map<String, dynamic> json) => _$CompletedFromJson(json);

 final  List<Object?> _transcript;
@override List<Object?> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override final  String signature;
@override final  String promptId;
 final  JournalEntry entry;

@JsonKey(name: 'status')
final String $type;


/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletedCopyWith<Completed> get copyWith => _$CompletedCopyWithImpl<Completed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompletedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Completed&&const DeepCollectionEquality().equals(other.transcript, _transcript)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.promptId, promptId) || other.promptId == promptId)&&(identical(other.entry, entry) || other.entry == entry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcript),signature,promptId,entry);
}

@override
String toString() {
    return 'AdvanceResponse.completed(transcript: $transcript, signature: $signature, promptId: $promptId, entry: $entry)';
}


}

/// @nodoc
abstract mixin class $CompletedCopyWith<$Res> implements $AdvanceResponseCopyWith<$Res> {
  factory $CompletedCopyWith(Completed value, $Res Function(Completed) _then) = _$CompletedCopyWithImpl;
@override @useResult
$Res call({
 List<Object?> transcript, String signature, String promptId, JournalEntry entry
});


$JournalEntryCopyWith<$Res> get entry;

}
/// @nodoc
class _$CompletedCopyWithImpl<$Res>
    implements $CompletedCopyWith<$Res> {
  _$CompletedCopyWithImpl(this._self, this._then);

  final Completed _self;
  final $Res Function(Completed) _then;

/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcript = null,Object? signature = null,Object? promptId = null,Object? entry = null,}) {
  return _then(Completed(
transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<Object?>,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,promptId: null == promptId ? _self.promptId : promptId // ignore: cast_nullable_to_non_nullable
as String,entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as JournalEntry,
  ));
}

/// Create a copy of AdvanceResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalEntryCopyWith<$Res> get entry {
  
  return $JournalEntryCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}


/// @nodoc
mixin _$PendingQuestion {

 String get toolCallId; AskQuestion get question;
/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingQuestionCopyWith<PendingQuestion> get copyWith => _$PendingQuestionCopyWithImpl<PendingQuestion>(this as PendingQuestion, _$identity);

  /// Serializes this PendingQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PendingQuestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingQuestion&&(identical(other.toolCallId, _this.toolCallId) || other.toolCallId == _this.toolCallId)&&(identical(other.question, _this.question) || other.question == _this.question));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PendingQuestion;
  return Object.hash(runtimeType,_this.toolCallId,_this.question);
}

@override
String toString() {
  final _this = this as PendingQuestion;
  return 'PendingQuestion(toolCallId: ${_this.toolCallId}, question: ${_this.question})';
}


}

/// @nodoc
abstract mixin class $PendingQuestionCopyWith<$Res>  {
  factory $PendingQuestionCopyWith(PendingQuestion value, $Res Function(PendingQuestion) _then) = _$PendingQuestionCopyWithImpl;
@useResult
$Res call({
 String toolCallId, AskQuestion question
});


$AskQuestionCopyWith<$Res> get question;

}
/// @nodoc
class _$PendingQuestionCopyWithImpl<$Res>
    implements $PendingQuestionCopyWith<$Res> {
  _$PendingQuestionCopyWithImpl(this._self, this._then);

  final PendingQuestion _self;
  final $Res Function(PendingQuestion) _then;

/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolCallId = null,Object? question = null,}) {
  return _then(PendingQuestion(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as AskQuestion,
  ));
}
/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AskQuestionCopyWith<$Res> get question {
  
  return $AskQuestionCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingQuestion].
extension PendingQuestionPatterns on PendingQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingQuestion value)  $default,){
final _that = this;
switch (_that) {
case _PendingQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _PendingQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolCallId,  AskQuestion question)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingQuestion() when $default != null:
return $default(_that.toolCallId,_that.question);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolCallId,  AskQuestion question)  $default,) {final _that = this;
switch (_that) {
case _PendingQuestion():
return $default(_that.toolCallId,_that.question);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolCallId,  AskQuestion question)?  $default,) {final _that = this;
switch (_that) {
case _PendingQuestion() when $default != null:
return $default(_that.toolCallId,_that.question);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.none)
class _PendingQuestion implements PendingQuestion {
  const _PendingQuestion({required this.toolCallId, required this.question});
  factory _PendingQuestion.fromJson(Map<String, dynamic> json) => _$PendingQuestionFromJson(json);

@override final  String toolCallId;
@override final  AskQuestion question;

/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingQuestionCopyWith<_PendingQuestion> get copyWith => __$PendingQuestionCopyWithImpl<_PendingQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingQuestion&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.question, question) || other.question == question));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,toolCallId,question);
}

@override
String toString() {
    return 'PendingQuestion(toolCallId: $toolCallId, question: $question)';
}


}

/// @nodoc
abstract mixin class _$PendingQuestionCopyWith<$Res> implements $PendingQuestionCopyWith<$Res> {
  factory _$PendingQuestionCopyWith(_PendingQuestion value, $Res Function(_PendingQuestion) _then) = __$PendingQuestionCopyWithImpl;
@override @useResult
$Res call({
 String toolCallId, AskQuestion question
});


@override $AskQuestionCopyWith<$Res> get question;

}
/// @nodoc
class __$PendingQuestionCopyWithImpl<$Res>
    implements _$PendingQuestionCopyWith<$Res> {
  __$PendingQuestionCopyWithImpl(this._self, this._then);

  final _PendingQuestion _self;
  final $Res Function(_PendingQuestion) _then;

/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolCallId = null,Object? question = null,}) {
  return _then(_PendingQuestion(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as AskQuestion,
  ));
}

/// Create a copy of PendingQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AskQuestionCopyWith<$Res> get question {
  
  return $AskQuestionCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}
}


/// @nodoc
mixin _$JournalEntry {

 String get summary; Map<String, Answer> get answers;
/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryCopyWith<JournalEntry> get copyWith => _$JournalEntryCopyWithImpl<JournalEntry>(this as JournalEntry, _$identity);

  /// Serializes this JournalEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JournalEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntry&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.answers, _this.answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JournalEntry;
  return Object.hash(runtimeType,_this.summary,const DeepCollectionEquality().hash(_this.answers));
}

@override
String toString() {
  final _this = this as JournalEntry;
  return 'JournalEntry(summary: ${_this.summary}, answers: ${_this.answers})';
}


}

/// @nodoc
abstract mixin class $JournalEntryCopyWith<$Res>  {
  factory $JournalEntryCopyWith(JournalEntry value, $Res Function(JournalEntry) _then) = _$JournalEntryCopyWithImpl;
@useResult
$Res call({
 String summary, Map<String, Answer> answers
});




}
/// @nodoc
class _$JournalEntryCopyWithImpl<$Res>
    implements $JournalEntryCopyWith<$Res> {
  _$JournalEntryCopyWithImpl(this._self, this._then);

  final JournalEntry _self;
  final $Res Function(JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? answers = null,}) {
  return _then(JournalEntry(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, Answer>,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalEntry].
extension JournalEntryPatterns on JournalEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalEntry value)  $default,){
final _that = this;
switch (_that) {
case _JournalEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalEntry value)?  $default,){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  Map<String, Answer> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.summary,_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  Map<String, Answer> answers)  $default,) {final _that = this;
switch (_that) {
case _JournalEntry():
return $default(_that.summary,_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  Map<String, Answer> answers)?  $default,) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.summary,_that.answers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JournalEntry implements JournalEntry {
  const _JournalEntry({required this.summary, required  Map<String, Answer> answers}): _answers = answers;
  factory _JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);

@override final  String summary;
 final  Map<String, Answer> _answers;
@override Map<String, Answer> get answers {
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_answers);
}


/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalEntryCopyWith<_JournalEntry> get copyWith => __$JournalEntryCopyWithImpl<_JournalEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalEntry&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.answers, _answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_answers));
}

@override
String toString() {
    return 'JournalEntry(summary: $summary, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$JournalEntryCopyWith<$Res> implements $JournalEntryCopyWith<$Res> {
  factory _$JournalEntryCopyWith(_JournalEntry value, $Res Function(_JournalEntry) _then) = __$JournalEntryCopyWithImpl;
@override @useResult
$Res call({
 String summary, Map<String, Answer> answers
});




}
/// @nodoc
class __$JournalEntryCopyWithImpl<$Res>
    implements _$JournalEntryCopyWith<$Res> {
  __$JournalEntryCopyWithImpl(this._self, this._then);

  final _JournalEntry _self;
  final $Res Function(_JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? answers = null,}) {
  return _then(_JournalEntry(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, Answer>,
  ));
}


}

// dart format on
