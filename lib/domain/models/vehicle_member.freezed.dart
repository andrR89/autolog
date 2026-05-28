// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehicleMember {

 String get vehicleId; String get userId; String get role; DateTime get createdAt;
/// Create a copy of VehicleMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleMemberCopyWith<VehicleMember> get copyWith => _$VehicleMemberCopyWithImpl<VehicleMember>(this as VehicleMember, _$identity);

  /// Serializes this VehicleMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleMember&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vehicleId,userId,role,createdAt);

@override
String toString() {
  return 'VehicleMember(vehicleId: $vehicleId, userId: $userId, role: $role, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VehicleMemberCopyWith<$Res>  {
  factory $VehicleMemberCopyWith(VehicleMember value, $Res Function(VehicleMember) _then) = _$VehicleMemberCopyWithImpl;
@useResult
$Res call({
 String vehicleId, String userId, String role, DateTime createdAt
});




}
/// @nodoc
class _$VehicleMemberCopyWithImpl<$Res>
    implements $VehicleMemberCopyWith<$Res> {
  _$VehicleMemberCopyWithImpl(this._self, this._then);

  final VehicleMember _self;
  final $Res Function(VehicleMember) _then;

/// Create a copy of VehicleMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vehicleId = null,Object? userId = null,Object? role = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleMember].
extension VehicleMemberPatterns on VehicleMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleMember value)  $default,){
final _that = this;
switch (_that) {
case _VehicleMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleMember value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String vehicleId,  String userId,  String role,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleMember() when $default != null:
return $default(_that.vehicleId,_that.userId,_that.role,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String vehicleId,  String userId,  String role,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _VehicleMember():
return $default(_that.vehicleId,_that.userId,_that.role,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String vehicleId,  String userId,  String role,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VehicleMember() when $default != null:
return $default(_that.vehicleId,_that.userId,_that.role,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleMember implements VehicleMember {
  const _VehicleMember({required this.vehicleId, required this.userId, required this.role, required this.createdAt});
  factory _VehicleMember.fromJson(Map<String, dynamic> json) => _$VehicleMemberFromJson(json);

@override final  String vehicleId;
@override final  String userId;
@override final  String role;
@override final  DateTime createdAt;

/// Create a copy of VehicleMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleMemberCopyWith<_VehicleMember> get copyWith => __$VehicleMemberCopyWithImpl<_VehicleMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleMember&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vehicleId,userId,role,createdAt);

@override
String toString() {
  return 'VehicleMember(vehicleId: $vehicleId, userId: $userId, role: $role, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VehicleMemberCopyWith<$Res> implements $VehicleMemberCopyWith<$Res> {
  factory _$VehicleMemberCopyWith(_VehicleMember value, $Res Function(_VehicleMember) _then) = __$VehicleMemberCopyWithImpl;
@override @useResult
$Res call({
 String vehicleId, String userId, String role, DateTime createdAt
});




}
/// @nodoc
class __$VehicleMemberCopyWithImpl<$Res>
    implements _$VehicleMemberCopyWith<$Res> {
  __$VehicleMemberCopyWithImpl(this._self, this._then);

  final _VehicleMember _self;
  final $Res Function(_VehicleMember) _then;

/// Create a copy of VehicleMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vehicleId = null,Object? userId = null,Object? role = null,Object? createdAt = null,}) {
  return _then(_VehicleMember(
vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
