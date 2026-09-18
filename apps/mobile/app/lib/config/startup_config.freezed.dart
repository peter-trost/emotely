// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'startup_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StartupConfig {

/// The oldest app version the server still serves. Below it the app shows
/// the force-update screen and cannot continue.
 String get minAppVersion;/// Where that screen sends the user. Server-controlled so the link can be
/// corrected without an app release, which is the only kind of fix that
/// reaches someone who cannot install a new app.
 String get storeUrl;
/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartupConfigCopyWith<StartupConfig> get copyWith => _$StartupConfigCopyWithImpl<StartupConfig>(this as StartupConfig, _$identity);

  /// Serializes this StartupConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StartupConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupConfig&&(identical(other.minAppVersion, _this.minAppVersion) || other.minAppVersion == _this.minAppVersion)&&(identical(other.storeUrl, _this.storeUrl) || other.storeUrl == _this.storeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StartupConfig;
  return Object.hash(runtimeType,_this.minAppVersion,_this.storeUrl);
}

@override
String toString() {
  final _this = this as StartupConfig;
  return 'StartupConfig(minAppVersion: ${_this.minAppVersion}, storeUrl: ${_this.storeUrl})';
}


}

/// @nodoc
abstract mixin class $StartupConfigCopyWith<$Res>  {
  factory $StartupConfigCopyWith(StartupConfig value, $Res Function(StartupConfig) _then) = _$StartupConfigCopyWithImpl;
@useResult
$Res call({
 String minAppVersion, String storeUrl
});




}
/// @nodoc
class _$StartupConfigCopyWithImpl<$Res>
    implements $StartupConfigCopyWith<$Res> {
  _$StartupConfigCopyWithImpl(this._self, this._then);

  final StartupConfig _self;
  final $Res Function(StartupConfig) _then;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minAppVersion = null,Object? storeUrl = null,}) {
  return _then(StartupConfig(
minAppVersion: null == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String,storeUrl: null == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StartupConfig].
extension StartupConfigPatterns on StartupConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartupConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartupConfig value)  $default,){
final _that = this;
switch (_that) {
case _StartupConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartupConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String minAppVersion,  String storeUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
return $default(_that.minAppVersion,_that.storeUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String minAppVersion,  String storeUrl)  $default,) {final _that = this;
switch (_that) {
case _StartupConfig():
return $default(_that.minAppVersion,_that.storeUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String minAppVersion,  String storeUrl)?  $default,) {final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
return $default(_that.minAppVersion,_that.storeUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StartupConfig implements StartupConfig {
  const _StartupConfig({required this.minAppVersion, required this.storeUrl});
  factory _StartupConfig.fromJson(Map<String, dynamic> json) => _$StartupConfigFromJson(json);

/// The oldest app version the server still serves. Below it the app shows
/// the force-update screen and cannot continue.
@override final  String minAppVersion;
/// Where that screen sends the user. Server-controlled so the link can be
/// corrected without an app release, which is the only kind of fix that
/// reaches someone who cannot install a new app.
@override final  String storeUrl;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartupConfigCopyWith<_StartupConfig> get copyWith => __$StartupConfigCopyWithImpl<_StartupConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartupConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartupConfig&&(identical(other.minAppVersion, minAppVersion) || other.minAppVersion == minAppVersion)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,minAppVersion,storeUrl);
}

@override
String toString() {
    return 'StartupConfig(minAppVersion: $minAppVersion, storeUrl: $storeUrl)';
}


}

/// @nodoc
abstract mixin class _$StartupConfigCopyWith<$Res> implements $StartupConfigCopyWith<$Res> {
  factory _$StartupConfigCopyWith(_StartupConfig value, $Res Function(_StartupConfig) _then) = __$StartupConfigCopyWithImpl;
@override @useResult
$Res call({
 String minAppVersion, String storeUrl
});




}
/// @nodoc
class __$StartupConfigCopyWithImpl<$Res>
    implements _$StartupConfigCopyWith<$Res> {
  __$StartupConfigCopyWithImpl(this._self, this._then);

  final _StartupConfig _self;
  final $Res Function(_StartupConfig) _then;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minAppVersion = null,Object? storeUrl = null,}) {
  return _then(_StartupConfig(
minAppVersion: null == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String,storeUrl: null == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
