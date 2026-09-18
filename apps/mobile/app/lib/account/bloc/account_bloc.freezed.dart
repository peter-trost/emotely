// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountEvent()';
}


}

/// @nodoc
class $AccountEventCopyWith<$Res>  {
$AccountEventCopyWith(AccountEvent _, $Res Function(AccountEvent) __);
}


/// Adds pattern-matching-related methods to [AccountEvent].
extension AccountEventPatterns on AccountEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountDeletionRequested value)?  deletionRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountDeletionRequested() when deletionRequested != null:
return deletionRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountDeletionRequested value)  deletionRequested,}){
final _that = this;
switch (_that) {
case AccountDeletionRequested():
return deletionRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountDeletionRequested value)?  deletionRequested,}){
final _that = this;
switch (_that) {
case AccountDeletionRequested() when deletionRequested != null:
return deletionRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  deletionRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountDeletionRequested() when deletionRequested != null:
return deletionRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  deletionRequested,}) {final _that = this;
switch (_that) {
case AccountDeletionRequested():
return deletionRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  deletionRequested,}) {final _that = this;
switch (_that) {
case AccountDeletionRequested() when deletionRequested != null:
return deletionRequested();case _:
  return null;

}
}

}

/// @nodoc


class AccountDeletionRequested implements AccountEvent {
  const AccountDeletionRequested();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountEvent.deletionRequested()';
}


}




/// @nodoc
mixin _$AccountState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountState()';
}


}

/// @nodoc
class $AccountStateCopyWith<$Res>  {
$AccountStateCopyWith(AccountState _, $Res Function(AccountState) __);
}


/// Adds pattern-matching-related methods to [AccountState].
extension AccountStatePatterns on AccountState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountIdle value)?  idle,TResult Function( AccountDeleting value)?  deleting,TResult Function( AccountDeleted value)?  deleted,TResult Function( AccountFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountIdle() when idle != null:
return idle(_that);case AccountDeleting() when deleting != null:
return deleting(_that);case AccountDeleted() when deleted != null:
return deleted(_that);case AccountFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountIdle value)  idle,required TResult Function( AccountDeleting value)  deleting,required TResult Function( AccountDeleted value)  deleted,required TResult Function( AccountFailure value)  failure,}){
final _that = this;
switch (_that) {
case AccountIdle():
return idle(_that);case AccountDeleting():
return deleting(_that);case AccountDeleted():
return deleted(_that);case AccountFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountIdle value)?  idle,TResult? Function( AccountDeleting value)?  deleting,TResult? Function( AccountDeleted value)?  deleted,TResult? Function( AccountFailure value)?  failure,}){
final _that = this;
switch (_that) {
case AccountIdle() when idle != null:
return idle(_that);case AccountDeleting() when deleting != null:
return deleting(_that);case AccountDeleted() when deleted != null:
return deleted(_that);case AccountFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  deleting,TResult Function()?  deleted,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountIdle() when idle != null:
return idle();case AccountDeleting() when deleting != null:
return deleting();case AccountDeleted() when deleted != null:
return deleted();case AccountFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  deleting,required TResult Function()  deleted,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case AccountIdle():
return idle();case AccountDeleting():
return deleting();case AccountDeleted():
return deleted();case AccountFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  deleting,TResult? Function()?  deleted,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case AccountIdle() when idle != null:
return idle();case AccountDeleting() when deleting != null:
return deleting();case AccountDeleted() when deleted != null:
return deleted();case AccountFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class AccountIdle implements AccountState {
  const AccountIdle();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountState.idle()';
}


}




/// @nodoc


class AccountDeleting implements AccountState {
  const AccountDeleting();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountState.deleting()';
}


}




/// @nodoc


class AccountDeleted implements AccountState {
  const AccountDeleted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountState.deleted()';
}


}




/// @nodoc


class AccountFailure implements AccountState {
  const AccountFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountState.failure()';
}


}




// dart format on
