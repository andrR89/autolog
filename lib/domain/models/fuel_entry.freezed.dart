// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FuelEntry {

 String get id; String get vehicleId; DateTime get date; int get odometer;@DecimalJsonConverter() Decimal get liters;@DecimalJsonConverter() Decimal get pricePerLiter;@DecimalJsonConverter() Decimal get totalCost; bool get fullTank;@FuelTypeConverter() FuelType get fuelType;@FuelSourceConverter() FuelSource get source; String? get receiptImageUrl; String? get stationName; String? get stationBrand; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;@SyncStatusConverter() SyncStatus get syncStatus;
/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelEntryCopyWith<FuelEntry> get copyWith => _$FuelEntryCopyWithImpl<FuelEntry>(this as FuelEntry, _$identity);

  /// Serializes this FuelEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.fullTank, fullTank) || other.fullTank == fullTank)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.source, source) || other.source == source)&&(identical(other.receiptImageUrl, receiptImageUrl) || other.receiptImageUrl == receiptImageUrl)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.stationBrand, stationBrand) || other.stationBrand == stationBrand)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,odometer,liters,pricePerLiter,totalCost,fullTank,fuelType,source,receiptImageUrl,stationName,stationBrand,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'FuelEntry(id: $id, vehicleId: $vehicleId, date: $date, odometer: $odometer, liters: $liters, pricePerLiter: $pricePerLiter, totalCost: $totalCost, fullTank: $fullTank, fuelType: $fuelType, source: $source, receiptImageUrl: $receiptImageUrl, stationName: $stationName, stationBrand: $stationBrand, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $FuelEntryCopyWith<$Res>  {
  factory $FuelEntryCopyWith(FuelEntry value, $Res Function(FuelEntry) _then) = _$FuelEntryCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, DateTime date, int odometer,@DecimalJsonConverter() Decimal liters,@DecimalJsonConverter() Decimal pricePerLiter,@DecimalJsonConverter() Decimal totalCost, bool fullTank,@FuelTypeConverter() FuelType fuelType,@FuelSourceConverter() FuelSource source, String? receiptImageUrl, String? stationName, String? stationBrand, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class _$FuelEntryCopyWithImpl<$Res>
    implements $FuelEntryCopyWith<$Res> {
  _$FuelEntryCopyWithImpl(this._self, this._then);

  final FuelEntry _self;
  final $Res Function(FuelEntry) _then;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? odometer = null,Object? liters = null,Object? pricePerLiter = null,Object? totalCost = null,Object? fullTank = null,Object? fuelType = null,Object? source = null,Object? receiptImageUrl = freezed,Object? stationName = freezed,Object? stationBrand = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odometer: null == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as int,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as Decimal,pricePerLiter: null == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,fullTank: null == fullTank ? _self.fullTank : fullTank // ignore: cast_nullable_to_non_nullable
as bool,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FuelSource,receiptImageUrl: freezed == receiptImageUrl ? _self.receiptImageUrl : receiptImageUrl // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,stationBrand: freezed == stationBrand ? _self.stationBrand : stationBrand // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [FuelEntry].
extension FuelEntryPatterns on FuelEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FuelEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FuelEntry value)  $default,){
final _that = this;
switch (_that) {
case _FuelEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FuelEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  int odometer, @DecimalJsonConverter()  Decimal liters, @DecimalJsonConverter()  Decimal pricePerLiter, @DecimalJsonConverter()  Decimal totalCost,  bool fullTank, @FuelTypeConverter()  FuelType fuelType, @FuelSourceConverter()  FuelSource source,  String? receiptImageUrl,  String? stationName,  String? stationBrand,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.odometer,_that.liters,_that.pricePerLiter,_that.totalCost,_that.fullTank,_that.fuelType,_that.source,_that.receiptImageUrl,_that.stationName,_that.stationBrand,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  int odometer, @DecimalJsonConverter()  Decimal liters, @DecimalJsonConverter()  Decimal pricePerLiter, @DecimalJsonConverter()  Decimal totalCost,  bool fullTank, @FuelTypeConverter()  FuelType fuelType, @FuelSourceConverter()  FuelSource source,  String? receiptImageUrl,  String? stationName,  String? stationBrand,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _FuelEntry():
return $default(_that.id,_that.vehicleId,_that.date,_that.odometer,_that.liters,_that.pricePerLiter,_that.totalCost,_that.fullTank,_that.fuelType,_that.source,_that.receiptImageUrl,_that.stationName,_that.stationBrand,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  DateTime date,  int odometer, @DecimalJsonConverter()  Decimal liters, @DecimalJsonConverter()  Decimal pricePerLiter, @DecimalJsonConverter()  Decimal totalCost,  bool fullTank, @FuelTypeConverter()  FuelType fuelType, @FuelSourceConverter()  FuelSource source,  String? receiptImageUrl,  String? stationName,  String? stationBrand,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _FuelEntry() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.odometer,_that.liters,_that.pricePerLiter,_that.totalCost,_that.fullTank,_that.fuelType,_that.source,_that.receiptImageUrl,_that.stationName,_that.stationBrand,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FuelEntry implements FuelEntry {
  const _FuelEntry({required this.id, required this.vehicleId, required this.date, required this.odometer, @DecimalJsonConverter() required this.liters, @DecimalJsonConverter() required this.pricePerLiter, @DecimalJsonConverter() required this.totalCost, required this.fullTank, @FuelTypeConverter() required this.fuelType, @FuelSourceConverter() required this.source, this.receiptImageUrl, this.stationName, this.stationBrand, required this.createdAt, required this.updatedAt, this.deletedAt, @SyncStatusConverter() required this.syncStatus});
  factory _FuelEntry.fromJson(Map<String, dynamic> json) => _$FuelEntryFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  DateTime date;
@override final  int odometer;
@override@DecimalJsonConverter() final  Decimal liters;
@override@DecimalJsonConverter() final  Decimal pricePerLiter;
@override@DecimalJsonConverter() final  Decimal totalCost;
@override final  bool fullTank;
@override@FuelTypeConverter() final  FuelType fuelType;
@override@FuelSourceConverter() final  FuelSource source;
@override final  String? receiptImageUrl;
@override final  String? stationName;
@override final  String? stationBrand;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override@SyncStatusConverter() final  SyncStatus syncStatus;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelEntryCopyWith<_FuelEntry> get copyWith => __$FuelEntryCopyWithImpl<_FuelEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FuelEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.odometer, odometer) || other.odometer == odometer)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.fullTank, fullTank) || other.fullTank == fullTank)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.source, source) || other.source == source)&&(identical(other.receiptImageUrl, receiptImageUrl) || other.receiptImageUrl == receiptImageUrl)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.stationBrand, stationBrand) || other.stationBrand == stationBrand)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,odometer,liters,pricePerLiter,totalCost,fullTank,fuelType,source,receiptImageUrl,stationName,stationBrand,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'FuelEntry(id: $id, vehicleId: $vehicleId, date: $date, odometer: $odometer, liters: $liters, pricePerLiter: $pricePerLiter, totalCost: $totalCost, fullTank: $fullTank, fuelType: $fuelType, source: $source, receiptImageUrl: $receiptImageUrl, stationName: $stationName, stationBrand: $stationBrand, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$FuelEntryCopyWith<$Res> implements $FuelEntryCopyWith<$Res> {
  factory _$FuelEntryCopyWith(_FuelEntry value, $Res Function(_FuelEntry) _then) = __$FuelEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, DateTime date, int odometer,@DecimalJsonConverter() Decimal liters,@DecimalJsonConverter() Decimal pricePerLiter,@DecimalJsonConverter() Decimal totalCost, bool fullTank,@FuelTypeConverter() FuelType fuelType,@FuelSourceConverter() FuelSource source, String? receiptImageUrl, String? stationName, String? stationBrand, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class __$FuelEntryCopyWithImpl<$Res>
    implements _$FuelEntryCopyWith<$Res> {
  __$FuelEntryCopyWithImpl(this._self, this._then);

  final _FuelEntry _self;
  final $Res Function(_FuelEntry) _then;

/// Create a copy of FuelEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? odometer = null,Object? liters = null,Object? pricePerLiter = null,Object? totalCost = null,Object? fullTank = null,Object? fuelType = null,Object? source = null,Object? receiptImageUrl = freezed,Object? stationName = freezed,Object? stationBrand = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_FuelEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,odometer: null == odometer ? _self.odometer : odometer // ignore: cast_nullable_to_non_nullable
as int,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as Decimal,pricePerLiter: null == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,fullTank: null == fullTank ? _self.fullTank : fullTank // ignore: cast_nullable_to_non_nullable
as bool,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FuelSource,receiptImageUrl: freezed == receiptImageUrl ? _self.receiptImageUrl : receiptImageUrl // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,stationBrand: freezed == stationBrand ? _self.stationBrand : stationBrand // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
