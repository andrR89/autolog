// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanned_receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScannedReceipt {

@DecimalJsonConverter() Decimal? get liters;@DecimalJsonConverter() Decimal? get pricePerLiter;@DecimalJsonConverter() Decimal? get totalCost; DateTime? get date;@FuelTypeConverter() FuelType? get fuelType;
/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannedReceiptCopyWith<ScannedReceipt> get copyWith => _$ScannedReceiptCopyWithImpl<ScannedReceipt>(this as ScannedReceipt, _$identity);

  /// Serializes this ScannedReceipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannedReceipt&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.date, date) || other.date == date)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liters,pricePerLiter,totalCost,date,fuelType);

@override
String toString() {
  return 'ScannedReceipt(liters: $liters, pricePerLiter: $pricePerLiter, totalCost: $totalCost, date: $date, fuelType: $fuelType)';
}


}

/// @nodoc
abstract mixin class $ScannedReceiptCopyWith<$Res>  {
  factory $ScannedReceiptCopyWith(ScannedReceipt value, $Res Function(ScannedReceipt) _then) = _$ScannedReceiptCopyWithImpl;
@useResult
$Res call({
@DecimalJsonConverter() Decimal? liters,@DecimalJsonConverter() Decimal? pricePerLiter,@DecimalJsonConverter() Decimal? totalCost, DateTime? date,@FuelTypeConverter() FuelType? fuelType
});




}
/// @nodoc
class _$ScannedReceiptCopyWithImpl<$Res>
    implements $ScannedReceiptCopyWith<$Res> {
  _$ScannedReceiptCopyWithImpl(this._self, this._then);

  final ScannedReceipt _self;
  final $Res Function(ScannedReceipt) _then;

/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liters = freezed,Object? pricePerLiter = freezed,Object? totalCost = freezed,Object? date = freezed,Object? fuelType = freezed,}) {
  return _then(_self.copyWith(
liters: freezed == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as Decimal?,pricePerLiter: freezed == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannedReceipt].
extension ScannedReceiptPatterns on ScannedReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannedReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannedReceipt value)  $default,){
final _that = this;
switch (_that) {
case _ScannedReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannedReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalJsonConverter()  Decimal? liters, @DecimalJsonConverter()  Decimal? pricePerLiter, @DecimalJsonConverter()  Decimal? totalCost,  DateTime? date, @FuelTypeConverter()  FuelType? fuelType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
return $default(_that.liters,_that.pricePerLiter,_that.totalCost,_that.date,_that.fuelType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalJsonConverter()  Decimal? liters, @DecimalJsonConverter()  Decimal? pricePerLiter, @DecimalJsonConverter()  Decimal? totalCost,  DateTime? date, @FuelTypeConverter()  FuelType? fuelType)  $default,) {final _that = this;
switch (_that) {
case _ScannedReceipt():
return $default(_that.liters,_that.pricePerLiter,_that.totalCost,_that.date,_that.fuelType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalJsonConverter()  Decimal? liters, @DecimalJsonConverter()  Decimal? pricePerLiter, @DecimalJsonConverter()  Decimal? totalCost,  DateTime? date, @FuelTypeConverter()  FuelType? fuelType)?  $default,) {final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
return $default(_that.liters,_that.pricePerLiter,_that.totalCost,_that.date,_that.fuelType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScannedReceipt implements ScannedReceipt {
  const _ScannedReceipt({@DecimalJsonConverter() this.liters, @DecimalJsonConverter() this.pricePerLiter, @DecimalJsonConverter() this.totalCost, this.date, @FuelTypeConverter() this.fuelType});
  factory _ScannedReceipt.fromJson(Map<String, dynamic> json) => _$ScannedReceiptFromJson(json);

@override@DecimalJsonConverter() final  Decimal? liters;
@override@DecimalJsonConverter() final  Decimal? pricePerLiter;
@override@DecimalJsonConverter() final  Decimal? totalCost;
@override final  DateTime? date;
@override@FuelTypeConverter() final  FuelType? fuelType;

/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannedReceiptCopyWith<_ScannedReceipt> get copyWith => __$ScannedReceiptCopyWithImpl<_ScannedReceipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScannedReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannedReceipt&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.pricePerLiter, pricePerLiter) || other.pricePerLiter == pricePerLiter)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.date, date) || other.date == date)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liters,pricePerLiter,totalCost,date,fuelType);

@override
String toString() {
  return 'ScannedReceipt(liters: $liters, pricePerLiter: $pricePerLiter, totalCost: $totalCost, date: $date, fuelType: $fuelType)';
}


}

/// @nodoc
abstract mixin class _$ScannedReceiptCopyWith<$Res> implements $ScannedReceiptCopyWith<$Res> {
  factory _$ScannedReceiptCopyWith(_ScannedReceipt value, $Res Function(_ScannedReceipt) _then) = __$ScannedReceiptCopyWithImpl;
@override @useResult
$Res call({
@DecimalJsonConverter() Decimal? liters,@DecimalJsonConverter() Decimal? pricePerLiter,@DecimalJsonConverter() Decimal? totalCost, DateTime? date,@FuelTypeConverter() FuelType? fuelType
});




}
/// @nodoc
class __$ScannedReceiptCopyWithImpl<$Res>
    implements _$ScannedReceiptCopyWith<$Res> {
  __$ScannedReceiptCopyWithImpl(this._self, this._then);

  final _ScannedReceipt _self;
  final $Res Function(_ScannedReceipt) _then;

/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liters = freezed,Object? pricePerLiter = freezed,Object? totalCost = freezed,Object? date = freezed,Object? fuelType = freezed,}) {
  return _then(_ScannedReceipt(
liters: freezed == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as Decimal?,pricePerLiter: freezed == pricePerLiter ? _self.pricePerLiter : pricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType?,
  ));
}


}

// dart format on
