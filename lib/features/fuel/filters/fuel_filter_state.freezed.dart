// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FuelFilterState {

/// Tipo de combustível exato. null = todos.
/// Valores canônicos: "gasolina", "etanol", "diesel", "gnv".
 String? get fuelType;/// Substring case-insensitive em stationName. null = sem filtro.
 String? get stationQuery;/// Período inclusivo. null = todos.
 DateTimeRange? get period;/// Busca livre em notes/station/fuelType. null = sem filtro.
 String? get textQuery;/// Critério de ordenação. Default: dateDesc.
 FuelSortBy get sortBy;/// Quando true, exibe apenas abastecimentos com tanque cheio.
 bool get onlyFullTank;
/// Create a copy of FuelFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelFilterStateCopyWith<FuelFilterState> get copyWith => _$FuelFilterStateCopyWithImpl<FuelFilterState>(this as FuelFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelFilterState&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.stationQuery, stationQuery) || other.stationQuery == stationQuery)&&(identical(other.period, period) || other.period == period)&&(identical(other.textQuery, textQuery) || other.textQuery == textQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.onlyFullTank, onlyFullTank) || other.onlyFullTank == onlyFullTank));
}


@override
int get hashCode => Object.hash(runtimeType,fuelType,stationQuery,period,textQuery,sortBy,onlyFullTank);

@override
String toString() {
  return 'FuelFilterState(fuelType: $fuelType, stationQuery: $stationQuery, period: $period, textQuery: $textQuery, sortBy: $sortBy, onlyFullTank: $onlyFullTank)';
}


}

/// @nodoc
abstract mixin class $FuelFilterStateCopyWith<$Res>  {
  factory $FuelFilterStateCopyWith(FuelFilterState value, $Res Function(FuelFilterState) _then) = _$FuelFilterStateCopyWithImpl;
@useResult
$Res call({
 String? fuelType, String? stationQuery, DateTimeRange? period, String? textQuery, FuelSortBy sortBy, bool onlyFullTank
});




}
/// @nodoc
class _$FuelFilterStateCopyWithImpl<$Res>
    implements $FuelFilterStateCopyWith<$Res> {
  _$FuelFilterStateCopyWithImpl(this._self, this._then);

  final FuelFilterState _self;
  final $Res Function(FuelFilterState) _then;

/// Create a copy of FuelFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fuelType = freezed,Object? stationQuery = freezed,Object? period = freezed,Object? textQuery = freezed,Object? sortBy = null,Object? onlyFullTank = null,}) {
  return _then(_self.copyWith(
fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String?,stationQuery: freezed == stationQuery ? _self.stationQuery : stationQuery // ignore: cast_nullable_to_non_nullable
as String?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateTimeRange?,textQuery: freezed == textQuery ? _self.textQuery : textQuery // ignore: cast_nullable_to_non_nullable
as String?,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as FuelSortBy,onlyFullTank: null == onlyFullTank ? _self.onlyFullTank : onlyFullTank // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FuelFilterState].
extension FuelFilterStatePatterns on FuelFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FuelFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FuelFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FuelFilterState value)  $default,){
final _that = this;
switch (_that) {
case _FuelFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FuelFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _FuelFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? fuelType,  String? stationQuery,  DateTimeRange? period,  String? textQuery,  FuelSortBy sortBy,  bool onlyFullTank)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelFilterState() when $default != null:
return $default(_that.fuelType,_that.stationQuery,_that.period,_that.textQuery,_that.sortBy,_that.onlyFullTank);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? fuelType,  String? stationQuery,  DateTimeRange? period,  String? textQuery,  FuelSortBy sortBy,  bool onlyFullTank)  $default,) {final _that = this;
switch (_that) {
case _FuelFilterState():
return $default(_that.fuelType,_that.stationQuery,_that.period,_that.textQuery,_that.sortBy,_that.onlyFullTank);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? fuelType,  String? stationQuery,  DateTimeRange? period,  String? textQuery,  FuelSortBy sortBy,  bool onlyFullTank)?  $default,) {final _that = this;
switch (_that) {
case _FuelFilterState() when $default != null:
return $default(_that.fuelType,_that.stationQuery,_that.period,_that.textQuery,_that.sortBy,_that.onlyFullTank);case _:
  return null;

}
}

}

/// @nodoc


class _FuelFilterState extends FuelFilterState {
   _FuelFilterState({this.fuelType, this.stationQuery, this.period, this.textQuery, this.sortBy = FuelSortBy.dateDesc, this.onlyFullTank = false}): super._();
  

/// Tipo de combustível exato. null = todos.
/// Valores canônicos: "gasolina", "etanol", "diesel", "gnv".
@override final  String? fuelType;
/// Substring case-insensitive em stationName. null = sem filtro.
@override final  String? stationQuery;
/// Período inclusivo. null = todos.
@override final  DateTimeRange? period;
/// Busca livre em notes/station/fuelType. null = sem filtro.
@override final  String? textQuery;
/// Critério de ordenação. Default: dateDesc.
@override@JsonKey() final  FuelSortBy sortBy;
/// Quando true, exibe apenas abastecimentos com tanque cheio.
@override@JsonKey() final  bool onlyFullTank;

/// Create a copy of FuelFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelFilterStateCopyWith<_FuelFilterState> get copyWith => __$FuelFilterStateCopyWithImpl<_FuelFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelFilterState&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.stationQuery, stationQuery) || other.stationQuery == stationQuery)&&(identical(other.period, period) || other.period == period)&&(identical(other.textQuery, textQuery) || other.textQuery == textQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.onlyFullTank, onlyFullTank) || other.onlyFullTank == onlyFullTank));
}


@override
int get hashCode => Object.hash(runtimeType,fuelType,stationQuery,period,textQuery,sortBy,onlyFullTank);

@override
String toString() {
  return 'FuelFilterState(fuelType: $fuelType, stationQuery: $stationQuery, period: $period, textQuery: $textQuery, sortBy: $sortBy, onlyFullTank: $onlyFullTank)';
}


}

/// @nodoc
abstract mixin class _$FuelFilterStateCopyWith<$Res> implements $FuelFilterStateCopyWith<$Res> {
  factory _$FuelFilterStateCopyWith(_FuelFilterState value, $Res Function(_FuelFilterState) _then) = __$FuelFilterStateCopyWithImpl;
@override @useResult
$Res call({
 String? fuelType, String? stationQuery, DateTimeRange? period, String? textQuery, FuelSortBy sortBy, bool onlyFullTank
});




}
/// @nodoc
class __$FuelFilterStateCopyWithImpl<$Res>
    implements _$FuelFilterStateCopyWith<$Res> {
  __$FuelFilterStateCopyWithImpl(this._self, this._then);

  final _FuelFilterState _self;
  final $Res Function(_FuelFilterState) _then;

/// Create a copy of FuelFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fuelType = freezed,Object? stationQuery = freezed,Object? period = freezed,Object? textQuery = freezed,Object? sortBy = null,Object? onlyFullTank = null,}) {
  return _then(_FuelFilterState(
fuelType: freezed == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String?,stationQuery: freezed == stationQuery ? _self.stationQuery : stationQuery // ignore: cast_nullable_to_non_nullable
as String?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateTimeRange?,textQuery: freezed == textQuery ? _self.textQuery : textQuery // ignore: cast_nullable_to_non_nullable
as String?,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as FuelSortBy,onlyFullTank: null == onlyFullTank ? _self.onlyFullTank : onlyFullTank // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
