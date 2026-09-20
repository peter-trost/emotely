// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entry_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntryEvent {

 String get entryId;
/// Create a copy of EntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryEventCopyWith<EntryEvent> get copyWith => _$EntryEventCopyWithImpl<EntryEvent>(this as EntryEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EntryEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryEvent&&(identical(other.entryId, _this.entryId) || other.entryId == _this.entryId));
}


@override
int get hashCode {
  final _this = this as EntryEvent;
  return Object.hash(runtimeType,_this.entryId);
}

@override
String toString() {
  final _this = this as EntryEvent;
  return 'EntryEvent(entryId: ${_this.entryId})';
}


}

/// @nodoc
abstract mixin class $EntryEventCopyWith<$Res>  {
  factory $EntryEventCopyWith(EntryEvent value, $Res Function(EntryEvent) _then) = _$EntryEventCopyWithImpl;
@useResult
$Res call({
 String entryId
});




}
/// @nodoc
class _$EntryEventCopyWithImpl<$Res>
    implements $EntryEventCopyWith<$Res> {
  _$EntryEventCopyWithImpl(this._self, this._then);

  final EntryEvent _self;
  final $Res Function(EntryEvent) _then;

/// Create a copy of EntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entryId = null,}) {
  return _then(EntryEvent.loaded(
null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryEvent].
extension EntryEventPatterns on EntryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EntryLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EntryLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EntryLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case EntryLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EntryLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case EntryLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String entryId)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EntryLoaded() when loaded != null:
return loaded(_that.entryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String entryId)  loaded,}) {final _that = this;
switch (_that) {
case EntryLoaded():
return loaded(_that.entryId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String entryId)?  loaded,}) {final _that = this;
switch (_that) {
case EntryLoaded() when loaded != null:
return loaded(_that.entryId);case _:
  return null;

}
}

}

/// @nodoc


class EntryLoaded implements EntryEvent {
  const EntryLoaded(this.entryId);
  

@override final  String entryId;

/// Create a copy of EntryEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryLoadedCopyWith<EntryLoaded> get copyWith => _$EntryLoadedCopyWithImpl<EntryLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryLoaded&&(identical(other.entryId, entryId) || other.entryId == entryId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,entryId);
}

@override
String toString() {
    return 'EntryEvent.loaded(entryId: $entryId)';
}


}

/// @nodoc
abstract mixin class $EntryLoadedCopyWith<$Res> implements $EntryEventCopyWith<$Res> {
  factory $EntryLoadedCopyWith(EntryLoaded value, $Res Function(EntryLoaded) _then) = _$EntryLoadedCopyWithImpl;
@override @useResult
$Res call({
 String entryId
});




}
/// @nodoc
class _$EntryLoadedCopyWithImpl<$Res>
    implements $EntryLoadedCopyWith<$Res> {
  _$EntryLoadedCopyWithImpl(this._self, this._then);

  final EntryLoaded _self;
  final $Res Function(EntryLoaded) _then;

/// Create a copy of EntryEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entryId = null,}) {
  return _then(EntryLoaded(
null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EntryState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryState);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $EntryStateCopyWith<$Res>  {
$EntryStateCopyWith(EntryState _, $Res Function(EntryState) __);
}


/// Adds pattern-matching-related methods to [EntryState].
extension EntryStatePatterns on EntryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EntryLoading value)?  loading,TResult Function( EntryReady value)?  ready,TResult Function( EntryFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EntryLoading() when loading != null:
return loading(_that);case EntryReady() when ready != null:
return ready(_that);case EntryFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EntryLoading value)  loading,required TResult Function( EntryReady value)  ready,required TResult Function( EntryFailure value)  failure,}){
final _that = this;
switch (_that) {
case EntryLoading():
return loading(_that);case EntryReady():
return ready(_that);case EntryFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EntryLoading value)?  loading,TResult? Function( EntryReady value)?  ready,TResult? Function( EntryFailure value)?  failure,}){
final _that = this;
switch (_that) {
case EntryLoading() when loading != null:
return loading(_that);case EntryReady() when ready != null:
return ready(_that);case EntryFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( EntryRecord record)?  ready,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EntryLoading() when loading != null:
return loading();case EntryReady() when ready != null:
return ready(_that.record);case EntryFailure() when failure != null:
return failure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( EntryRecord record)  ready,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case EntryLoading():
return loading();case EntryReady():
return ready(_that.record);case EntryFailure():
return failure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( EntryRecord record)?  ready,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case EntryLoading() when loading != null:
return loading();case EntryReady() when ready != null:
return ready(_that.record);case EntryFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class EntryLoading implements EntryState {
  const EntryLoading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryLoading);
}


@override
int get hashCode => runtimeType.hashCode;



}




/// @nodoc


class EntryReady implements EntryState {
  const EntryReady({required this.record});
  

 final  EntryRecord record;

/// Create a copy of EntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryReadyCopyWith<EntryReady> get copyWith => _$EntryReadyCopyWithImpl<EntryReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryReady&&(identical(other.record, record) || other.record == record));
}


@override
int get hashCode {
    return Object.hash(runtimeType,record);
}



}

/// @nodoc
abstract mixin class $EntryReadyCopyWith<$Res> implements $EntryStateCopyWith<$Res> {
  factory $EntryReadyCopyWith(EntryReady value, $Res Function(EntryReady) _then) = _$EntryReadyCopyWithImpl;
@useResult
$Res call({
 EntryRecord record
});


$EntryRecordCopyWith<$Res> get record;

}
/// @nodoc
class _$EntryReadyCopyWithImpl<$Res>
    implements $EntryReadyCopyWith<$Res> {
  _$EntryReadyCopyWithImpl(this._self, this._then);

  final EntryReady _self;
  final $Res Function(EntryReady) _then;

/// Create a copy of EntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? record = null,}) {
  return _then(EntryReady(
record: null == record ? _self.record : record // ignore: cast_nullable_to_non_nullable
as EntryRecord,
  ));
}

/// Create a copy of EntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryRecordCopyWith<$Res> get record {
  
  return $EntryRecordCopyWith<$Res>(_self.record, (value) {
    return _then(_self.copyWith(record: value));
  });
}
}

/// @nodoc


class EntryFailure implements EntryState {
  const EntryFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryFailure);
}


@override
int get hashCode => runtimeType.hashCode;



}




// dart format on
