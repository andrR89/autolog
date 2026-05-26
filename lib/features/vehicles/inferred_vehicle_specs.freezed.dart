// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inferred_vehicle_specs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InferredVehicleSpecs {

 int? get engineDisplacementCc;@DecimalNullableJsonConverter() Decimal? get tankCapacityL; int? get horsepower; double get confidence;
/// Create a copy of InferredVehicleSpecs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InferredVehicleSpecsCopyWith<InferredVehicleSpecs> get copyWith => _$InferredVehicleSpecsCopyWithImpl<InferredVehicleSpecs>(this as InferredVehicleSpecs, _$identity);

  /// Serializes this InferredVehicleSpecs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InferredVehicleSpecs&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.horsepower, horsepower) || other.horsepower == horsepower)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,engineDisplacementCc,tankCapacityL,horsepower,confidence);

@override
String toString() {
  return 'InferredVehicleSpecs(engineDisplacementCc: $engineDisplacementCc, tankCapacityL: $tankCapacityL, horsepower: $horsepower, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $InferredVehicleSpecsCopyWith<$Res>  {
  factory $InferredVehicleSpecsCopyWith(InferredVehicleSpecs value, $Res Function(InferredVehicleSpecs) _then) = _$InferredVehicleSpecsCopyWithImpl;
@useResult
$Res call({
 int? engineDisplacementCc,@DecimalNullableJsonConverter() Decimal? tankCapacityL, int? horsepower, double confidence
});




}
/// @nodoc
class _$InferredVehicleSpecsCopyWithImpl<$Res>
    implements $InferredVehicleSpecsCopyWith<$Res> {
  _$InferredVehicleSpecsCopyWithImpl(this._self, this._then);

  final InferredVehicleSpecs _self;
  final $Res Function(InferredVehicleSpecs) _then;

/// Create a copy of InferredVehicleSpecs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? engineDisplacementCc = freezed,Object? tankCapacityL = freezed,Object? horsepower = freezed,Object? confidence = null,}) {
  return _then(_self.copyWith(
engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as Decimal?,horsepower: freezed == horsepower ? _self.horsepower : horsepower // ignore: cast_nullable_to_non_nullable
as int?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [InferredVehicleSpecs].
extension InferredVehicleSpecsPatterns on InferredVehicleSpecs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InferredVehicleSpecs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InferredVehicleSpecs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InferredVehicleSpecs value)  $default,){
final _that = this;
switch (_that) {
case _InferredVehicleSpecs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InferredVehicleSpecs value)?  $default,){
final _that = this;
switch (_that) {
case _InferredVehicleSpecs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InferredVehicleSpecs() when $default != null:
return $default(_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _InferredVehicleSpecs():
return $default(_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? engineDisplacementCc, @DecimalNullableJsonConverter()  Decimal? tankCapacityL,  int? horsepower,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _InferredVehicleSpecs() when $default != null:
return $default(_that.engineDisplacementCc,_that.tankCapacityL,_that.horsepower,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InferredVehicleSpecs implements InferredVehicleSpecs {
  const _InferredVehicleSpecs({this.engineDisplacementCc, @DecimalNullableJsonConverter() this.tankCapacityL, this.horsepower, this.confidence = 0.0});
  factory _InferredVehicleSpecs.fromJson(Map<String, dynamic> json) => _$InferredVehicleSpecsFromJson(json);

@override final  int? engineDisplacementCc;
@override@DecimalNullableJsonConverter() final  Decimal? tankCapacityL;
@override final  int? horsepower;
@override@JsonKey() final  double confidence;

/// Create a copy of InferredVehicleSpecs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InferredVehicleSpecsCopyWith<_InferredVehicleSpecs> get copyWith => __$InferredVehicleSpecsCopyWithImpl<_InferredVehicleSpecs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InferredVehicleSpecsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InferredVehicleSpecs&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.horsepower, horsepower) || other.horsepower == horsepower)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,engineDisplacementCc,tankCapacityL,horsepower,confidence);

@override
String toString() {
  return 'InferredVehicleSpecs(engineDisplacementCc: $engineDisplacementCc, tankCapacityL: $tankCapacityL, horsepower: $horsepower, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$InferredVehicleSpecsCopyWith<$Res> implements $InferredVehicleSpecsCopyWith<$Res> {
  factory _$InferredVehicleSpecsCopyWith(_InferredVehicleSpecs value, $Res Function(_InferredVehicleSpecs) _then) = __$InferredVehicleSpecsCopyWithImpl;
@override @useResult
$Res call({
 int? engineDisplacementCc,@DecimalNullableJsonConverter() Decimal? tankCapacityL, int? horsepower, double confidence
});




}
/// @nodoc
class __$InferredVehicleSpecsCopyWithImpl<$Res>
    implements _$InferredVehicleSpecsCopyWith<$Res> {
  __$InferredVehicleSpecsCopyWithImpl(this._self, this._then);

  final _InferredVehicleSpecs _self;
  final $Res Function(_InferredVehicleSpecs) _then;

/// Create a copy of InferredVehicleSpecs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? engineDisplacementCc = freezed,Object? tankCapacityL = freezed,Object? horsepower = freezed,Object? confidence = null,}) {
  return _then(_InferredVehicleSpecs(
engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as Decimal?,horsepower: freezed == horsepower ? _self.horsepower : horsepower // ignore: cast_nullable_to_non_nullable
as int?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
