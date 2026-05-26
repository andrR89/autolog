// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fipe_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FipeBrand {

 String get code; String get name;
/// Create a copy of FipeBrand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FipeBrandCopyWith<FipeBrand> get copyWith => _$FipeBrandCopyWithImpl<FipeBrand>(this as FipeBrand, _$identity);

  /// Serializes this FipeBrand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FipeBrand&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeBrand(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $FipeBrandCopyWith<$Res>  {
  factory $FipeBrandCopyWith(FipeBrand value, $Res Function(FipeBrand) _then) = _$FipeBrandCopyWithImpl;
@useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class _$FipeBrandCopyWithImpl<$Res>
    implements $FipeBrandCopyWith<$Res> {
  _$FipeBrandCopyWithImpl(this._self, this._then);

  final FipeBrand _self;
  final $Res Function(FipeBrand) _then;

/// Create a copy of FipeBrand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FipeBrand].
extension FipeBrandPatterns on FipeBrand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FipeBrand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FipeBrand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FipeBrand value)  $default,){
final _that = this;
switch (_that) {
case _FipeBrand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FipeBrand value)?  $default,){
final _that = this;
switch (_that) {
case _FipeBrand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FipeBrand() when $default != null:
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _FipeBrand():
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _FipeBrand() when $default != null:
return $default(_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FipeBrand implements FipeBrand {
  const _FipeBrand({required this.code, required this.name});
  factory _FipeBrand.fromJson(Map<String, dynamic> json) => _$FipeBrandFromJson(json);

@override final  String code;
@override final  String name;

/// Create a copy of FipeBrand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FipeBrandCopyWith<_FipeBrand> get copyWith => __$FipeBrandCopyWithImpl<_FipeBrand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FipeBrandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FipeBrand&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeBrand(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FipeBrandCopyWith<$Res> implements $FipeBrandCopyWith<$Res> {
  factory _$FipeBrandCopyWith(_FipeBrand value, $Res Function(_FipeBrand) _then) = __$FipeBrandCopyWithImpl;
@override @useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class __$FipeBrandCopyWithImpl<$Res>
    implements _$FipeBrandCopyWith<$Res> {
  __$FipeBrandCopyWithImpl(this._self, this._then);

  final _FipeBrand _self;
  final $Res Function(_FipeBrand) _then;

/// Create a copy of FipeBrand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,}) {
  return _then(_FipeBrand(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FipeModel {

 String get code; String get name;
/// Create a copy of FipeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FipeModelCopyWith<FipeModel> get copyWith => _$FipeModelCopyWithImpl<FipeModel>(this as FipeModel, _$identity);

  /// Serializes this FipeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FipeModel&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeModel(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $FipeModelCopyWith<$Res>  {
  factory $FipeModelCopyWith(FipeModel value, $Res Function(FipeModel) _then) = _$FipeModelCopyWithImpl;
@useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class _$FipeModelCopyWithImpl<$Res>
    implements $FipeModelCopyWith<$Res> {
  _$FipeModelCopyWithImpl(this._self, this._then);

  final FipeModel _self;
  final $Res Function(FipeModel) _then;

/// Create a copy of FipeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FipeModel].
extension FipeModelPatterns on FipeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FipeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FipeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FipeModel value)  $default,){
final _that = this;
switch (_that) {
case _FipeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FipeModel value)?  $default,){
final _that = this;
switch (_that) {
case _FipeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FipeModel() when $default != null:
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _FipeModel():
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _FipeModel() when $default != null:
return $default(_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FipeModel implements FipeModel {
  const _FipeModel({required this.code, required this.name});
  factory _FipeModel.fromJson(Map<String, dynamic> json) => _$FipeModelFromJson(json);

@override final  String code;
@override final  String name;

/// Create a copy of FipeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FipeModelCopyWith<_FipeModel> get copyWith => __$FipeModelCopyWithImpl<_FipeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FipeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FipeModel&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeModel(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FipeModelCopyWith<$Res> implements $FipeModelCopyWith<$Res> {
  factory _$FipeModelCopyWith(_FipeModel value, $Res Function(_FipeModel) _then) = __$FipeModelCopyWithImpl;
@override @useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class __$FipeModelCopyWithImpl<$Res>
    implements _$FipeModelCopyWith<$Res> {
  __$FipeModelCopyWithImpl(this._self, this._then);

  final _FipeModel _self;
  final $Res Function(_FipeModel) _then;

/// Create a copy of FipeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,}) {
  return _then(_FipeModel(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FipeYear {

 String get code; String get name;
/// Create a copy of FipeYear
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FipeYearCopyWith<FipeYear> get copyWith => _$FipeYearCopyWithImpl<FipeYear>(this as FipeYear, _$identity);

  /// Serializes this FipeYear to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FipeYear&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeYear(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $FipeYearCopyWith<$Res>  {
  factory $FipeYearCopyWith(FipeYear value, $Res Function(FipeYear) _then) = _$FipeYearCopyWithImpl;
@useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class _$FipeYearCopyWithImpl<$Res>
    implements $FipeYearCopyWith<$Res> {
  _$FipeYearCopyWithImpl(this._self, this._then);

  final FipeYear _self;
  final $Res Function(FipeYear) _then;

/// Create a copy of FipeYear
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FipeYear].
extension FipeYearPatterns on FipeYear {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FipeYear value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FipeYear() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FipeYear value)  $default,){
final _that = this;
switch (_that) {
case _FipeYear():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FipeYear value)?  $default,){
final _that = this;
switch (_that) {
case _FipeYear() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FipeYear() when $default != null:
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _FipeYear():
return $default(_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _FipeYear() when $default != null:
return $default(_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FipeYear implements FipeYear {
  const _FipeYear({required this.code, required this.name});
  factory _FipeYear.fromJson(Map<String, dynamic> json) => _$FipeYearFromJson(json);

@override final  String code;
@override final  String name;

/// Create a copy of FipeYear
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FipeYearCopyWith<_FipeYear> get copyWith => __$FipeYearCopyWithImpl<_FipeYear>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FipeYearToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FipeYear&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name);

@override
String toString() {
  return 'FipeYear(code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FipeYearCopyWith<$Res> implements $FipeYearCopyWith<$Res> {
  factory _$FipeYearCopyWith(_FipeYear value, $Res Function(_FipeYear) _then) = __$FipeYearCopyWithImpl;
@override @useResult
$Res call({
 String code, String name
});




}
/// @nodoc
class __$FipeYearCopyWithImpl<$Res>
    implements _$FipeYearCopyWith<$Res> {
  __$FipeYearCopyWithImpl(this._self, this._then);

  final _FipeYear _self;
  final $Res Function(_FipeYear) _then;

/// Create a copy of FipeYear
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,}) {
  return _then(_FipeYear(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FipeVehicleDetails {

// ignore: invalid_annotation_target
@JsonKey(fromJson: _strOrDash) String get brand;// ignore: invalid_annotation_target
@JsonKey(fromJson: _strOrDash) String get model;// ignore: invalid_annotation_target
@JsonKey(name: 'modelYear', fromJson: _intOrZero) int get modelYear;// ignore: invalid_annotation_target
@JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) String get fipeCode;// ignore: invalid_annotation_target
@JsonKey(fromJson: _strOrEmpty) String get fuel;// ignore: invalid_annotation_target
@JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter() Decimal get priceValue;// ignore: invalid_annotation_target
@JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth) String get referenceMonth;
/// Create a copy of FipeVehicleDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FipeVehicleDetailsCopyWith<FipeVehicleDetails> get copyWith => _$FipeVehicleDetailsCopyWithImpl<FipeVehicleDetails>(this as FipeVehicleDetails, _$identity);

  /// Serializes this FipeVehicleDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FipeVehicleDetails&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.modelYear, modelYear) || other.modelYear == modelYear)&&(identical(other.fipeCode, fipeCode) || other.fipeCode == fipeCode)&&(identical(other.fuel, fuel) || other.fuel == fuel)&&(identical(other.priceValue, priceValue) || other.priceValue == priceValue)&&(identical(other.referenceMonth, referenceMonth) || other.referenceMonth == referenceMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,model,modelYear,fipeCode,fuel,priceValue,referenceMonth);

@override
String toString() {
  return 'FipeVehicleDetails(brand: $brand, model: $model, modelYear: $modelYear, fipeCode: $fipeCode, fuel: $fuel, priceValue: $priceValue, referenceMonth: $referenceMonth)';
}


}

/// @nodoc
abstract mixin class $FipeVehicleDetailsCopyWith<$Res>  {
  factory $FipeVehicleDetailsCopyWith(FipeVehicleDetails value, $Res Function(FipeVehicleDetails) _then) = _$FipeVehicleDetailsCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _strOrDash) String brand,@JsonKey(fromJson: _strOrDash) String model,@JsonKey(name: 'modelYear', fromJson: _intOrZero) int modelYear,@JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) String fipeCode,@JsonKey(fromJson: _strOrEmpty) String fuel,@JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter() Decimal priceValue,@JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth) String referenceMonth
});




}
/// @nodoc
class _$FipeVehicleDetailsCopyWithImpl<$Res>
    implements $FipeVehicleDetailsCopyWith<$Res> {
  _$FipeVehicleDetailsCopyWithImpl(this._self, this._then);

  final FipeVehicleDetails _self;
  final $Res Function(FipeVehicleDetails) _then;

/// Create a copy of FipeVehicleDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brand = null,Object? model = null,Object? modelYear = null,Object? fipeCode = null,Object? fuel = null,Object? priceValue = null,Object? referenceMonth = null,}) {
  return _then(_self.copyWith(
brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,modelYear: null == modelYear ? _self.modelYear : modelYear // ignore: cast_nullable_to_non_nullable
as int,fipeCode: null == fipeCode ? _self.fipeCode : fipeCode // ignore: cast_nullable_to_non_nullable
as String,fuel: null == fuel ? _self.fuel : fuel // ignore: cast_nullable_to_non_nullable
as String,priceValue: null == priceValue ? _self.priceValue : priceValue // ignore: cast_nullable_to_non_nullable
as Decimal,referenceMonth: null == referenceMonth ? _self.referenceMonth : referenceMonth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FipeVehicleDetails].
extension FipeVehicleDetailsPatterns on FipeVehicleDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FipeVehicleDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FipeVehicleDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FipeVehicleDetails value)  $default,){
final _that = this;
switch (_that) {
case _FipeVehicleDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FipeVehicleDetails value)?  $default,){
final _that = this;
switch (_that) {
case _FipeVehicleDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _strOrDash)  String brand, @JsonKey(fromJson: _strOrDash)  String model, @JsonKey(name: 'modelYear', fromJson: _intOrZero)  int modelYear, @JsonKey(name: 'fipeCode', fromJson: _strOrEmpty)  String fipeCode, @JsonKey(fromJson: _strOrEmpty)  String fuel, @JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter()  Decimal priceValue, @JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth)  String referenceMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FipeVehicleDetails() when $default != null:
return $default(_that.brand,_that.model,_that.modelYear,_that.fipeCode,_that.fuel,_that.priceValue,_that.referenceMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _strOrDash)  String brand, @JsonKey(fromJson: _strOrDash)  String model, @JsonKey(name: 'modelYear', fromJson: _intOrZero)  int modelYear, @JsonKey(name: 'fipeCode', fromJson: _strOrEmpty)  String fipeCode, @JsonKey(fromJson: _strOrEmpty)  String fuel, @JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter()  Decimal priceValue, @JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth)  String referenceMonth)  $default,) {final _that = this;
switch (_that) {
case _FipeVehicleDetails():
return $default(_that.brand,_that.model,_that.modelYear,_that.fipeCode,_that.fuel,_that.priceValue,_that.referenceMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _strOrDash)  String brand, @JsonKey(fromJson: _strOrDash)  String model, @JsonKey(name: 'modelYear', fromJson: _intOrZero)  int modelYear, @JsonKey(name: 'fipeCode', fromJson: _strOrEmpty)  String fipeCode, @JsonKey(fromJson: _strOrEmpty)  String fuel, @JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter()  Decimal priceValue, @JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth)  String referenceMonth)?  $default,) {final _that = this;
switch (_that) {
case _FipeVehicleDetails() when $default != null:
return $default(_that.brand,_that.model,_that.modelYear,_that.fipeCode,_that.fuel,_that.priceValue,_that.referenceMonth);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _FipeVehicleDetails implements FipeVehicleDetails {
  const _FipeVehicleDetails({@JsonKey(fromJson: _strOrDash) required this.brand, @JsonKey(fromJson: _strOrDash) required this.model, @JsonKey(name: 'modelYear', fromJson: _intOrZero) required this.modelYear, @JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) required this.fipeCode, @JsonKey(fromJson: _strOrEmpty) required this.fuel, @JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter() required this.priceValue, @JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth) required this.referenceMonth});
  factory _FipeVehicleDetails.fromJson(Map<String, dynamic> json) => _$FipeVehicleDetailsFromJson(json);

// ignore: invalid_annotation_target
@override@JsonKey(fromJson: _strOrDash) final  String brand;
// ignore: invalid_annotation_target
@override@JsonKey(fromJson: _strOrDash) final  String model;
// ignore: invalid_annotation_target
@override@JsonKey(name: 'modelYear', fromJson: _intOrZero) final  int modelYear;
// ignore: invalid_annotation_target
@override@JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) final  String fipeCode;
// ignore: invalid_annotation_target
@override@JsonKey(fromJson: _strOrEmpty) final  String fuel;
// ignore: invalid_annotation_target
@override@JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter() final  Decimal priceValue;
// ignore: invalid_annotation_target
@override@JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth) final  String referenceMonth;

/// Create a copy of FipeVehicleDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FipeVehicleDetailsCopyWith<_FipeVehicleDetails> get copyWith => __$FipeVehicleDetailsCopyWithImpl<_FipeVehicleDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FipeVehicleDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FipeVehicleDetails&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.modelYear, modelYear) || other.modelYear == modelYear)&&(identical(other.fipeCode, fipeCode) || other.fipeCode == fipeCode)&&(identical(other.fuel, fuel) || other.fuel == fuel)&&(identical(other.priceValue, priceValue) || other.priceValue == priceValue)&&(identical(other.referenceMonth, referenceMonth) || other.referenceMonth == referenceMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,model,modelYear,fipeCode,fuel,priceValue,referenceMonth);

@override
String toString() {
  return 'FipeVehicleDetails(brand: $brand, model: $model, modelYear: $modelYear, fipeCode: $fipeCode, fuel: $fuel, priceValue: $priceValue, referenceMonth: $referenceMonth)';
}


}

/// @nodoc
abstract mixin class _$FipeVehicleDetailsCopyWith<$Res> implements $FipeVehicleDetailsCopyWith<$Res> {
  factory _$FipeVehicleDetailsCopyWith(_FipeVehicleDetails value, $Res Function(_FipeVehicleDetails) _then) = __$FipeVehicleDetailsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _strOrDash) String brand,@JsonKey(fromJson: _strOrDash) String model,@JsonKey(name: 'modelYear', fromJson: _intOrZero) int modelYear,@JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) String fipeCode,@JsonKey(fromJson: _strOrEmpty) String fuel,@JsonKey(name: 'price', fromJson: _priceFromJson)@_DecimalToStringConverter() Decimal priceValue,@JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth) String referenceMonth
});




}
/// @nodoc
class __$FipeVehicleDetailsCopyWithImpl<$Res>
    implements _$FipeVehicleDetailsCopyWith<$Res> {
  __$FipeVehicleDetailsCopyWithImpl(this._self, this._then);

  final _FipeVehicleDetails _self;
  final $Res Function(_FipeVehicleDetails) _then;

/// Create a copy of FipeVehicleDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brand = null,Object? model = null,Object? modelYear = null,Object? fipeCode = null,Object? fuel = null,Object? priceValue = null,Object? referenceMonth = null,}) {
  return _then(_FipeVehicleDetails(
brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,modelYear: null == modelYear ? _self.modelYear : modelYear // ignore: cast_nullable_to_non_nullable
as int,fipeCode: null == fipeCode ? _self.fipeCode : fipeCode // ignore: cast_nullable_to_non_nullable
as String,fuel: null == fuel ? _self.fuel : fuel // ignore: cast_nullable_to_non_nullable
as String,priceValue: null == priceValue ? _self.priceValue : priceValue // ignore: cast_nullable_to_non_nullable
as Decimal,referenceMonth: null == referenceMonth ? _self.referenceMonth : referenceMonth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
