// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanned_crlv.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScannedCrlv {

 String? get plate; String? get renavam; String? get chassi; String? get color;@FuelTypeNullableConverter() FuelType? get fuelType; String? get make; String? get model; int? get year;
/// Create a copy of ScannedCrlv
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannedCrlvCopyWith<ScannedCrlv> get copyWith => _$ScannedCrlvCopyWithImpl<ScannedCrlv>(this as ScannedCrlv, _$identity);

  /// Serializes this ScannedCrlv to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannedCrlv&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.renavam, renavam) || other.renavam == renavam)&&(identical(other.chassi, chassi) || other.chassi == chassi)&&(identical(other.color, color) || other.color == color)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plate,renavam,chassi,color,fuelType,make,model,year);

@override
String toString() {
  return 'ScannedCrlv(plate: $plate, renavam: $renavam, chassi: $chassi, color: $color, fuelType: $fuelType, make: $make, model: $model, year: $year)';
}


}

/// @nodoc
abstract mixin class $ScannedCrlvCopyWith<$Res>  {
  factory $ScannedCrlvCopyWith(ScannedCrlv value, $Res Function(ScannedCrlv) _then) = _$ScannedCrlvCopyWithImpl;
@useResult
$Res call({
 String? plate, String? renavam, String? chassi, String? color,@FuelTypeNullableConverter() FuelType? fuelType, String? make, String? model, int? year
});




}
/// @nodoc
class _$ScannedCrlvCopyWithImpl<$Res>
    implements $ScannedCrlvCopyWith<$Res> {
  _$ScannedCrlvCopyWithImpl(this._self, this._then);

  final ScannedCrlv _self;
  final $Res Function(ScannedCrlv) _then;

/// Create a copy of ScannedCrlv
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plate = freezed,Object? renavam = freezed,Object? chassi = freezed,Object? color = freezed,Object? fuelType = freezed,Object? make = freezed,Object? model = freezed,Object? year = freezed,}) {
  return _then(_self.copyWith(
plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,renavam: freezed == renavam ? _self.renavam : renavam // ignore: cast_nullable_to_non_nullable
as String?,chassi: freezed == chassi ? _self.chassi : chassi // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType?,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannedCrlv].
extension ScannedCrlvPatterns on ScannedCrlv {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannedCrlv value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannedCrlv() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannedCrlv value)  $default,){
final _that = this;
switch (_that) {
case _ScannedCrlv():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannedCrlv value)?  $default,){
final _that = this;
switch (_that) {
case _ScannedCrlv() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? plate,  String? renavam,  String? chassi,  String? color, @FuelTypeNullableConverter()  FuelType? fuelType,  String? make,  String? model,  int? year)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannedCrlv() when $default != null:
return $default(_that.plate,_that.renavam,_that.chassi,_that.color,_that.fuelType,_that.make,_that.model,_that.year);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? plate,  String? renavam,  String? chassi,  String? color, @FuelTypeNullableConverter()  FuelType? fuelType,  String? make,  String? model,  int? year)  $default,) {final _that = this;
switch (_that) {
case _ScannedCrlv():
return $default(_that.plate,_that.renavam,_that.chassi,_that.color,_that.fuelType,_that.make,_that.model,_that.year);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? plate,  String? renavam,  String? chassi,  String? color, @FuelTypeNullableConverter()  FuelType? fuelType,  String? make,  String? model,  int? year)?  $default,) {final _that = this;
switch (_that) {
case _ScannedCrlv() when $default != null:
return $default(_that.plate,_that.renavam,_that.chassi,_that.color,_that.fuelType,_that.make,_that.model,_that.year);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScannedCrlv implements ScannedCrlv {
  const _ScannedCrlv({this.plate, this.renavam, this.chassi, this.color, @FuelTypeNullableConverter() this.fuelType, this.make, this.model, this.year});
  factory _ScannedCrlv.fromJson(Map<String, dynamic> json) => _$ScannedCrlvFromJson(json);

@override final  String? plate;
@override final  String? renavam;
@override final  String? chassi;
@override final  String? color;
@override@FuelTypeNullableConverter() final  FuelType? fuelType;
@override final  String? make;
@override final  String? model;
@override final  int? year;

/// Create a copy of ScannedCrlv
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannedCrlvCopyWith<_ScannedCrlv> get copyWith => __$ScannedCrlvCopyWithImpl<_ScannedCrlv>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScannedCrlvToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannedCrlv&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.renavam, renavam) || other.renavam == renavam)&&(identical(other.chassi, chassi) || other.chassi == chassi)&&(identical(other.color, color) || other.color == color)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plate,renavam,chassi,color,fuelType,make,model,year);

@override
String toString() {
  return 'ScannedCrlv(plate: $plate, renavam: $renavam, chassi: $chassi, color: $color, fuelType: $fuelType, make: $make, model: $model, year: $year)';
}


}

/// @nodoc
abstract mixin class _$ScannedCrlvCopyWith<$Res> implements $ScannedCrlvCopyWith<$Res> {
  factory _$ScannedCrlvCopyWith(_ScannedCrlv value, $Res Function(_ScannedCrlv) _then) = __$ScannedCrlvCopyWithImpl;
@override @useResult
$Res call({
 String? plate, String? renavam, String? chassi, String? color,@FuelTypeNullableConverter() FuelType? fuelType, String? make, String? model, int? year
});




}
/// @nodoc
class __$ScannedCrlvCopyWithImpl<$Res>
    implements _$ScannedCrlvCopyWith<$Res> {
  __$ScannedCrlvCopyWithImpl(this._self, this._then);

  final _ScannedCrlv _self;
  final $Res Function(_ScannedCrlv) _then;

/// Create a copy of ScannedCrlv
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plate = freezed,Object? renavam = freezed,Object? chassi = freezed,Object? color = freezed,Object? fuelType = freezed,Object? make = freezed,Object? model = freezed,Object? year = freezed,}) {
  return _then(_ScannedCrlv(
plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,renavam: freezed == renavam ? _self.renavam : renavam // ignore: cast_nullable_to_non_nullable
as String?,chassi: freezed == chassi ? _self.chassi : chassi // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType?,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
