// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vehicle {

 String get id; String get userId; String get nickname; String? get make; String? get model; int? get year; String? get uf; String? get color;@VehicleTypeConverter() VehicleType get type; int? get engineDisplacementCc;@DecimalNullableJsonConverter() Decimal? get tankCapacityL; int? get horsepower; String? get fipeCode;@DecimalNullableJsonConverter() Decimal? get fipeValue; String? get fipeReferenceMonth; String? get plate; String? get renavam; String? get chassi;@FuelTypeConverter() FuelType get fuelType; int get initialOdometer; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;@SyncStatusConverter() SyncStatus get syncStatus;
/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleCopyWith<Vehicle> get copyWith => _$VehicleCopyWithImpl<Vehicle>(this as Vehicle, _$identity);

  /// Serializes this Vehicle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.uf, uf) || other.uf == uf)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.horsepower, horsepower) || other.horsepower == horsepower)&&(identical(other.fipeCode, fipeCode) || other.fipeCode == fipeCode)&&(identical(other.fipeValue, fipeValue) || other.fipeValue == fipeValue)&&(identical(other.fipeReferenceMonth, fipeReferenceMonth) || other.fipeReferenceMonth == fipeReferenceMonth)&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.renavam, renavam) || other.renavam == renavam)&&(identical(other.chassi, chassi) || other.chassi == chassi)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.initialOdometer, initialOdometer) || other.initialOdometer == initialOdometer)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,nickname,make,model,year,uf,color,type,engineDisplacementCc,tankCapacityL,horsepower,fipeCode,fipeValue,fipeReferenceMonth,plate,renavam,chassi,fuelType,initialOdometer,createdAt,updatedAt,deletedAt,syncStatus]);

@override
String toString() {
  return 'Vehicle(id: $id, userId: $userId, nickname: $nickname, make: $make, model: $model, year: $year, uf: $uf, color: $color, type: $type, engineDisplacementCc: $engineDisplacementCc, tankCapacityL: $tankCapacityL, horsepower: $horsepower, fipeCode: $fipeCode, fipeValue: $fipeValue, fipeReferenceMonth: $fipeReferenceMonth, plate: $plate, renavam: $renavam, chassi: $chassi, fuelType: $fuelType, initialOdometer: $initialOdometer, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $VehicleCopyWith<$Res>  {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) _then) = _$VehicleCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String nickname, String? make, String? model, int? year, String? uf, String? color,@VehicleTypeConverter() VehicleType type, int? engineDisplacementCc,@DecimalNullableJsonConverter() Decimal? tankCapacityL, int? horsepower, String? fipeCode,@DecimalNullableJsonConverter() Decimal? fipeValue, String? fipeReferenceMonth, String? plate, String? renavam, String? chassi,@FuelTypeConverter() FuelType fuelType, int initialOdometer, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class _$VehicleCopyWithImpl<$Res>
    implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._self, this._then);

  final Vehicle _self;
  final $Res Function(Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? nickname = null,Object? make = freezed,Object? model = freezed,Object? year = freezed,Object? uf = freezed,Object? color = freezed,Object? type = null,Object? engineDisplacementCc = freezed,Object? tankCapacityL = freezed,Object? horsepower = freezed,Object? fipeCode = freezed,Object? fipeValue = freezed,Object? fipeReferenceMonth = freezed,Object? plate = freezed,Object? renavam = freezed,Object? chassi = freezed,Object? fuelType = null,Object? initialOdometer = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,uf: freezed == uf ? _self.uf : uf // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as Decimal?,horsepower: freezed == horsepower ? _self.horsepower : horsepower // ignore: cast_nullable_to_non_nullable
as int?,fipeCode: freezed == fipeCode ? _self.fipeCode : fipeCode // ignore: cast_nullable_to_non_nullable
as String?,fipeValue: freezed == fipeValue ? _self.fipeValue : fipeValue // ignore: cast_nullable_to_non_nullable
as Decimal?,fipeReferenceMonth: freezed == fipeReferenceMonth ? _self.fipeReferenceMonth : fipeReferenceMonth // ignore: cast_nullable_to_non_nullable
as String?,plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,renavam: freezed == renavam ? _self.renavam : renavam // ignore: cast_nullable_to_non_nullable
as String?,chassi: freezed == chassi ? _self.chassi : chassi // ignore: cast_nullable_to_non_nullable
as String?,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,initialOdometer: null == initialOdometer ? _self.initialOdometer : initialOdometer // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Vehicle].
extension VehiclePatterns on Vehicle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vehicle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vehicle value)  $default,){
final _that = this;
switch (_that) {
case _Vehicle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vehicle value)?  $default,){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String nickname,  String? make,  String? model,  int? year,  String? uf,  String? color, @VehicleTypeConverter()  VehicleType type,  int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  String? fipeCode, @DecimalNullableJsonConverter()  Decimal? fipeValue,  String? fipeReferenceMonth,  String? plate,  String? renavam,  String? chassi, @FuelTypeConverter()  FuelType fuelType,  int initialOdometer,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.userId,_that.nickname,_that.make,_that.model,_that.year,_that.uf,_that.color,_that.type,_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.fipeCode,_that.fipeValue,_that.fipeReferenceMonth,_that.plate,_that.renavam,_that.chassi,_that.fuelType,_that.initialOdometer,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String nickname,  String? make,  String? model,  int? year,  String? uf,  String? color, @VehicleTypeConverter()  VehicleType type,  int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  String? fipeCode, @DecimalNullableJsonConverter()  Decimal? fipeValue,  String? fipeReferenceMonth,  String? plate,  String? renavam,  String? chassi, @FuelTypeConverter()  FuelType fuelType,  int initialOdometer,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that.id,_that.userId,_that.nickname,_that.make,_that.model,_that.year,_that.uf,_that.color,_that.type,_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.fipeCode,_that.fipeValue,_that.fipeReferenceMonth,_that.plate,_that.renavam,_that.chassi,_that.fuelType,_that.initialOdometer,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String nickname,  String? make,  String? model,  int? year,  String? uf,  String? color, @VehicleTypeConverter()  VehicleType type,  int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  String? fipeCode, @DecimalNullableJsonConverter()  Decimal? fipeValue,  String? fipeReferenceMonth,  String? plate,  String? renavam,  String? chassi, @FuelTypeConverter()  FuelType fuelType,  int initialOdometer,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.id,_that.userId,_that.nickname,_that.make,_that.model,_that.year,_that.uf,_that.color,_that.type,_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.fipeCode,_that.fipeValue,_that.fipeReferenceMonth,_that.plate,_that.renavam,_that.chassi,_that.fuelType,_that.initialOdometer,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vehicle implements Vehicle {
  const _Vehicle({required this.id, required this.userId, required this.nickname, this.make, this.model, this.year, this.uf, this.color, @VehicleTypeConverter() this.type = VehicleType.carro, this.engineDisplacementCc, @DecimalNullableJsonConverter() this.tankCapacityL, this.horsepower, this.fipeCode, @DecimalNullableJsonConverter() this.fipeValue, this.fipeReferenceMonth, this.plate, this.renavam, this.chassi, @FuelTypeConverter() required this.fuelType, required this.initialOdometer, required this.createdAt, required this.updatedAt, this.deletedAt, @SyncStatusConverter() required this.syncStatus});
  factory _Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String nickname;
@override final  String? make;
@override final  String? model;
@override final  int? year;
@override final  String? uf;
@override final  String? color;
@override@JsonKey()@VehicleTypeConverter() final  VehicleType type;
@override final  int? engineDisplacementCc;
@override@DecimalNullableJsonConverter() final  Decimal? tankCapacityL;
@override final  int? horsepower;
@override final  String? fipeCode;
@override@DecimalNullableJsonConverter() final  Decimal? fipeValue;
@override final  String? fipeReferenceMonth;
@override final  String? plate;
@override final  String? renavam;
@override final  String? chassi;
@override@FuelTypeConverter() final  FuelType fuelType;
@override final  int initialOdometer;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override@SyncStatusConverter() final  SyncStatus syncStatus;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleCopyWith<_Vehicle> get copyWith => __$VehicleCopyWithImpl<_Vehicle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vehicle&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.uf, uf) || other.uf == uf)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.horsepower, horsepower) || other.horsepower == horsepower)&&(identical(other.fipeCode, fipeCode) || other.fipeCode == fipeCode)&&(identical(other.fipeValue, fipeValue) || other.fipeValue == fipeValue)&&(identical(other.fipeReferenceMonth, fipeReferenceMonth) || other.fipeReferenceMonth == fipeReferenceMonth)&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.renavam, renavam) || other.renavam == renavam)&&(identical(other.chassi, chassi) || other.chassi == chassi)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.initialOdometer, initialOdometer) || other.initialOdometer == initialOdometer)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,nickname,make,model,year,uf,color,type,engineDisplacementCc,tankCapacityL,horsepower,fipeCode,fipeValue,fipeReferenceMonth,plate,renavam,chassi,fuelType,initialOdometer,createdAt,updatedAt,deletedAt,syncStatus]);

@override
String toString() {
  return 'Vehicle(id: $id, userId: $userId, nickname: $nickname, make: $make, model: $model, year: $year, uf: $uf, color: $color, type: $type, engineDisplacementCc: $engineDisplacementCc, tankCapacityL: $tankCapacityL, horsepower: $horsepower, fipeCode: $fipeCode, fipeValue: $fipeValue, fipeReferenceMonth: $fipeReferenceMonth, plate: $plate, renavam: $renavam, chassi: $chassi, fuelType: $fuelType, initialOdometer: $initialOdometer, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$VehicleCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$VehicleCopyWith(_Vehicle value, $Res Function(_Vehicle) _then) = __$VehicleCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String nickname, String? make, String? model, int? year, String? uf, String? color,@VehicleTypeConverter() VehicleType type, int? engineDisplacementCc,@DecimalNullableJsonConverter() Decimal? tankCapacityL, int? horsepower, String? fipeCode,@DecimalNullableJsonConverter() Decimal? fipeValue, String? fipeReferenceMonth, String? plate, String? renavam, String? chassi,@FuelTypeConverter() FuelType fuelType, int initialOdometer, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class __$VehicleCopyWithImpl<$Res>
    implements _$VehicleCopyWith<$Res> {
  __$VehicleCopyWithImpl(this._self, this._then);

  final _Vehicle _self;
  final $Res Function(_Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? nickname = null,Object? make = freezed,Object? model = freezed,Object? year = freezed,Object? uf = freezed,Object? color = freezed,Object? type = null,Object? engineDisplacementCc = freezed,Object? tankCapacityL = freezed,Object? horsepower = freezed,Object? fipeCode = freezed,Object? fipeValue = freezed,Object? fipeReferenceMonth = freezed,Object? plate = freezed,Object? renavam = freezed,Object? chassi = freezed,Object? fuelType = null,Object? initialOdometer = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Vehicle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,uf: freezed == uf ? _self.uf : uf // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as Decimal?,horsepower: freezed == horsepower ? _self.horsepower : horsepower // ignore: cast_nullable_to_non_nullable
as int?,fipeCode: freezed == fipeCode ? _self.fipeCode : fipeCode // ignore: cast_nullable_to_non_nullable
as String?,fipeValue: freezed == fipeValue ? _self.fipeValue : fipeValue // ignore: cast_nullable_to_non_nullable
as Decimal?,fipeReferenceMonth: freezed == fipeReferenceMonth ? _self.fipeReferenceMonth : fipeReferenceMonth // ignore: cast_nullable_to_non_nullable
as String?,plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,renavam: freezed == renavam ? _self.renavam : renavam // ignore: cast_nullable_to_non_nullable
as String?,chassi: freezed == chassi ? _self.chassi : chassi // ignore: cast_nullable_to_non_nullable
as String?,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,initialOdometer: null == initialOdometer ? _self.initialOdometer : initialOdometer // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
