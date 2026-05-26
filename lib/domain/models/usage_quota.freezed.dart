// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_quota.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UsageQuota {

 String get userId; String get month; int get scanCount; bool get isPremium;
/// Create a copy of UsageQuota
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageQuotaCopyWith<UsageQuota> get copyWith => _$UsageQuotaCopyWithImpl<UsageQuota>(this as UsageQuota, _$identity);

  /// Serializes this UsageQuota to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageQuota&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.month, month) || other.month == month)&&(identical(other.scanCount, scanCount) || other.scanCount == scanCount)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,month,scanCount,isPremium);

@override
String toString() {
  return 'UsageQuota(userId: $userId, month: $month, scanCount: $scanCount, isPremium: $isPremium)';
}


}

/// @nodoc
abstract mixin class $UsageQuotaCopyWith<$Res>  {
  factory $UsageQuotaCopyWith(UsageQuota value, $Res Function(UsageQuota) _then) = _$UsageQuotaCopyWithImpl;
@useResult
$Res call({
 String userId, String month, int scanCount, bool isPremium
});




}
/// @nodoc
class _$UsageQuotaCopyWithImpl<$Res>
    implements $UsageQuotaCopyWith<$Res> {
  _$UsageQuotaCopyWithImpl(this._self, this._then);

  final UsageQuota _self;
  final $Res Function(UsageQuota) _then;

/// Create a copy of UsageQuota
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? month = null,Object? scanCount = null,Object? isPremium = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,scanCount: null == scanCount ? _self.scanCount : scanCount // ignore: cast_nullable_to_non_nullable
as int,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageQuota].
extension UsageQuotaPatterns on UsageQuota {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageQuota value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageQuota() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageQuota value)  $default,){
final _that = this;
switch (_that) {
case _UsageQuota():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageQuota value)?  $default,){
final _that = this;
switch (_that) {
case _UsageQuota() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String month,  int scanCount,  bool isPremium)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageQuota() when $default != null:
return $default(_that.userId,_that.month,_that.scanCount,_that.isPremium);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String month,  int scanCount,  bool isPremium)  $default,) {final _that = this;
switch (_that) {
case _UsageQuota():
return $default(_that.userId,_that.month,_that.scanCount,_that.isPremium);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String month,  int scanCount,  bool isPremium)?  $default,) {final _that = this;
switch (_that) {
case _UsageQuota() when $default != null:
return $default(_that.userId,_that.month,_that.scanCount,_that.isPremium);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageQuota implements UsageQuota {
  const _UsageQuota({required this.userId, required this.month, required this.scanCount, required this.isPremium});
  factory _UsageQuota.fromJson(Map<String, dynamic> json) => _$UsageQuotaFromJson(json);

@override final  String userId;
@override final  String month;
@override final  int scanCount;
@override final  bool isPremium;

/// Create a copy of UsageQuota
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageQuotaCopyWith<_UsageQuota> get copyWith => __$UsageQuotaCopyWithImpl<_UsageQuota>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageQuotaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageQuota&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.month, month) || other.month == month)&&(identical(other.scanCount, scanCount) || other.scanCount == scanCount)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,month,scanCount,isPremium);

@override
String toString() {
  return 'UsageQuota(userId: $userId, month: $month, scanCount: $scanCount, isPremium: $isPremium)';
}


}

/// @nodoc
abstract mixin class _$UsageQuotaCopyWith<$Res> implements $UsageQuotaCopyWith<$Res> {
  factory _$UsageQuotaCopyWith(_UsageQuota value, $Res Function(_UsageQuota) _then) = __$UsageQuotaCopyWithImpl;
@override @useResult
$Res call({
 String userId, String month, int scanCount, bool isPremium
});




}
/// @nodoc
class __$UsageQuotaCopyWithImpl<$Res>
    implements _$UsageQuotaCopyWith<$Res> {
  __$UsageQuotaCopyWithImpl(this._self, this._then);

  final _UsageQuota _self;
  final $Res Function(_UsageQuota) _then;

/// Create a copy of UsageQuota
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? month = null,Object? scanCount = null,Object? isPremium = null,}) {
  return _then(_UsageQuota(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,scanCount: null == scanCount ? _self.scanCount : scanCount // ignore: cast_nullable_to_non_nullable
as int,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
