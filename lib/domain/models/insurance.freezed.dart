// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insurance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Insurance {

 String get id; String get vehicleId; String? get insurer; String? get policyNumber; DateTime get startsAt; DateTime get endsAt;@DecimalNullableJsonConverter() Decimal? get premiumPaid; String? get notes; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;@SyncStatusConverter() SyncStatus get syncStatus;
/// Create a copy of Insurance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsuranceCopyWith<Insurance> get copyWith => _$InsuranceCopyWithImpl<Insurance>(this as Insurance, _$identity);

  /// Serializes this Insurance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Insurance&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.insurer, insurer) || other.insurer == insurer)&&(identical(other.policyNumber, policyNumber) || other.policyNumber == policyNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.premiumPaid, premiumPaid) || other.premiumPaid == premiumPaid)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,insurer,policyNumber,startsAt,endsAt,premiumPaid,notes,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Insurance(id: $id, vehicleId: $vehicleId, insurer: $insurer, policyNumber: $policyNumber, startsAt: $startsAt, endsAt: $endsAt, premiumPaid: $premiumPaid, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $InsuranceCopyWith<$Res>  {
  factory $InsuranceCopyWith(Insurance value, $Res Function(Insurance) _then) = _$InsuranceCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, String? insurer, String? policyNumber, DateTime startsAt, DateTime endsAt,@DecimalNullableJsonConverter() Decimal? premiumPaid, String? notes, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class _$InsuranceCopyWithImpl<$Res>
    implements $InsuranceCopyWith<$Res> {
  _$InsuranceCopyWithImpl(this._self, this._then);

  final Insurance _self;
  final $Res Function(Insurance) _then;

/// Create a copy of Insurance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? insurer = freezed,Object? policyNumber = freezed,Object? startsAt = null,Object? endsAt = null,Object? premiumPaid = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,insurer: freezed == insurer ? _self.insurer : insurer // ignore: cast_nullable_to_non_nullable
as String?,policyNumber: freezed == policyNumber ? _self.policyNumber : policyNumber // ignore: cast_nullable_to_non_nullable
as String?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,premiumPaid: freezed == premiumPaid ? _self.premiumPaid : premiumPaid // ignore: cast_nullable_to_non_nullable
as Decimal?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Insurance].
extension InsurancePatterns on Insurance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Insurance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Insurance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Insurance value)  $default,){
final _that = this;
switch (_that) {
case _Insurance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Insurance value)?  $default,){
final _that = this;
switch (_that) {
case _Insurance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String? insurer,  String? policyNumber,  DateTime startsAt,  DateTime endsAt, @DecimalNullableJsonConverter()  Decimal? premiumPaid,  String? notes,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Insurance() when $default != null:
return $default(_that.id,_that.vehicleId,_that.insurer,_that.policyNumber,_that.startsAt,_that.endsAt,_that.premiumPaid,_that.notes,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String? insurer,  String? policyNumber,  DateTime startsAt,  DateTime endsAt, @DecimalNullableJsonConverter()  Decimal? premiumPaid,  String? notes,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Insurance():
return $default(_that.id,_that.vehicleId,_that.insurer,_that.policyNumber,_that.startsAt,_that.endsAt,_that.premiumPaid,_that.notes,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  String? insurer,  String? policyNumber,  DateTime startsAt,  DateTime endsAt, @DecimalNullableJsonConverter()  Decimal? premiumPaid,  String? notes,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Insurance() when $default != null:
return $default(_that.id,_that.vehicleId,_that.insurer,_that.policyNumber,_that.startsAt,_that.endsAt,_that.premiumPaid,_that.notes,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Insurance implements Insurance {
  const _Insurance({required this.id, required this.vehicleId, this.insurer, this.policyNumber, required this.startsAt, required this.endsAt, @DecimalNullableJsonConverter() this.premiumPaid, this.notes, required this.createdAt, required this.updatedAt, this.deletedAt, @SyncStatusConverter() required this.syncStatus});
  factory _Insurance.fromJson(Map<String, dynamic> json) => _$InsuranceFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  String? insurer;
@override final  String? policyNumber;
@override final  DateTime startsAt;
@override final  DateTime endsAt;
@override@DecimalNullableJsonConverter() final  Decimal? premiumPaid;
@override final  String? notes;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override@SyncStatusConverter() final  SyncStatus syncStatus;

/// Create a copy of Insurance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsuranceCopyWith<_Insurance> get copyWith => __$InsuranceCopyWithImpl<_Insurance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InsuranceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Insurance&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.insurer, insurer) || other.insurer == insurer)&&(identical(other.policyNumber, policyNumber) || other.policyNumber == policyNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.premiumPaid, premiumPaid) || other.premiumPaid == premiumPaid)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,insurer,policyNumber,startsAt,endsAt,premiumPaid,notes,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Insurance(id: $id, vehicleId: $vehicleId, insurer: $insurer, policyNumber: $policyNumber, startsAt: $startsAt, endsAt: $endsAt, premiumPaid: $premiumPaid, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$InsuranceCopyWith<$Res> implements $InsuranceCopyWith<$Res> {
  factory _$InsuranceCopyWith(_Insurance value, $Res Function(_Insurance) _then) = __$InsuranceCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, String? insurer, String? policyNumber, DateTime startsAt, DateTime endsAt,@DecimalNullableJsonConverter() Decimal? premiumPaid, String? notes, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class __$InsuranceCopyWithImpl<$Res>
    implements _$InsuranceCopyWith<$Res> {
  __$InsuranceCopyWithImpl(this._self, this._then);

  final _Insurance _self;
  final $Res Function(_Insurance) _then;

/// Create a copy of Insurance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? insurer = freezed,Object? policyNumber = freezed,Object? startsAt = null,Object? endsAt = null,Object? premiumPaid = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Insurance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,insurer: freezed == insurer ? _self.insurer : insurer // ignore: cast_nullable_to_non_nullable
as String?,policyNumber: freezed == policyNumber ? _self.policyNumber : policyNumber // ignore: cast_nullable_to_non_nullable
as String?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,premiumPaid: freezed == premiumPaid ? _self.premiumPaid : premiumPaid // ignore: cast_nullable_to_non_nullable
as Decimal?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
