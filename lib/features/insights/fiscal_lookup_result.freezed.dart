// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fiscal_lookup_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FiscalEntry {

 int get month;// 1..12
 int? get day;// null se desconhecido
// ignore: invalid_annotation_target
@JsonKey(name: 'source') String? get sourceCitation;
/// Create a copy of FiscalEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FiscalEntryCopyWith<FiscalEntry> get copyWith => _$FiscalEntryCopyWithImpl<FiscalEntry>(this as FiscalEntry, _$identity);

  /// Serializes this FiscalEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FiscalEntry&&(identical(other.month, month) || other.month == month)&&(identical(other.day, day) || other.day == day)&&(identical(other.sourceCitation, sourceCitation) || other.sourceCitation == sourceCitation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,day,sourceCitation);

@override
String toString() {
  return 'FiscalEntry(month: $month, day: $day, sourceCitation: $sourceCitation)';
}


}

/// @nodoc
abstract mixin class $FiscalEntryCopyWith<$Res>  {
  factory $FiscalEntryCopyWith(FiscalEntry value, $Res Function(FiscalEntry) _then) = _$FiscalEntryCopyWithImpl;
@useResult
$Res call({
 int month, int? day,@JsonKey(name: 'source') String? sourceCitation
});




}
/// @nodoc
class _$FiscalEntryCopyWithImpl<$Res>
    implements $FiscalEntryCopyWith<$Res> {
  _$FiscalEntryCopyWithImpl(this._self, this._then);

  final FiscalEntry _self;
  final $Res Function(FiscalEntry) _then;

/// Create a copy of FiscalEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? day = freezed,Object? sourceCitation = freezed,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int?,sourceCitation: freezed == sourceCitation ? _self.sourceCitation : sourceCitation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FiscalEntry].
extension FiscalEntryPatterns on FiscalEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FiscalEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FiscalEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FiscalEntry value)  $default,){
final _that = this;
switch (_that) {
case _FiscalEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FiscalEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FiscalEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int month,  int? day, @JsonKey(name: 'source')  String? sourceCitation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FiscalEntry() when $default != null:
return $default(_that.month,_that.day,_that.sourceCitation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int month,  int? day, @JsonKey(name: 'source')  String? sourceCitation)  $default,) {final _that = this;
switch (_that) {
case _FiscalEntry():
return $default(_that.month,_that.day,_that.sourceCitation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int month,  int? day, @JsonKey(name: 'source')  String? sourceCitation)?  $default,) {final _that = this;
switch (_that) {
case _FiscalEntry() when $default != null:
return $default(_that.month,_that.day,_that.sourceCitation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FiscalEntry implements FiscalEntry {
  const _FiscalEntry({required this.month, this.day, @JsonKey(name: 'source') this.sourceCitation});
  factory _FiscalEntry.fromJson(Map<String, dynamic> json) => _$FiscalEntryFromJson(json);

@override final  int month;
// 1..12
@override final  int? day;
// null se desconhecido
// ignore: invalid_annotation_target
@override@JsonKey(name: 'source') final  String? sourceCitation;

/// Create a copy of FiscalEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FiscalEntryCopyWith<_FiscalEntry> get copyWith => __$FiscalEntryCopyWithImpl<_FiscalEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FiscalEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FiscalEntry&&(identical(other.month, month) || other.month == month)&&(identical(other.day, day) || other.day == day)&&(identical(other.sourceCitation, sourceCitation) || other.sourceCitation == sourceCitation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,day,sourceCitation);

@override
String toString() {
  return 'FiscalEntry(month: $month, day: $day, sourceCitation: $sourceCitation)';
}


}

/// @nodoc
abstract mixin class _$FiscalEntryCopyWith<$Res> implements $FiscalEntryCopyWith<$Res> {
  factory _$FiscalEntryCopyWith(_FiscalEntry value, $Res Function(_FiscalEntry) _then) = __$FiscalEntryCopyWithImpl;
@override @useResult
$Res call({
 int month, int? day,@JsonKey(name: 'source') String? sourceCitation
});




}
/// @nodoc
class __$FiscalEntryCopyWithImpl<$Res>
    implements _$FiscalEntryCopyWith<$Res> {
  __$FiscalEntryCopyWithImpl(this._self, this._then);

  final _FiscalEntry _self;
  final $Res Function(_FiscalEntry) _then;

/// Create a copy of FiscalEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? day = freezed,Object? sourceCitation = freezed,}) {
  return _then(_FiscalEntry(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int?,sourceCitation: freezed == sourceCitation ? _self.sourceCitation : sourceCitation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FiscalLookupResult {

 FiscalEntry get ipva; FiscalEntry get licensing; FiscalLookupSource get source;
/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FiscalLookupResultCopyWith<FiscalLookupResult> get copyWith => _$FiscalLookupResultCopyWithImpl<FiscalLookupResult>(this as FiscalLookupResult, _$identity);

  /// Serializes this FiscalLookupResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FiscalLookupResult&&(identical(other.ipva, ipva) || other.ipva == ipva)&&(identical(other.licensing, licensing) || other.licensing == licensing)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ipva,licensing,source);

@override
String toString() {
  return 'FiscalLookupResult(ipva: $ipva, licensing: $licensing, source: $source)';
}


}

/// @nodoc
abstract mixin class $FiscalLookupResultCopyWith<$Res>  {
  factory $FiscalLookupResultCopyWith(FiscalLookupResult value, $Res Function(FiscalLookupResult) _then) = _$FiscalLookupResultCopyWithImpl;
@useResult
$Res call({
 FiscalEntry ipva, FiscalEntry licensing, FiscalLookupSource source
});


$FiscalEntryCopyWith<$Res> get ipva;$FiscalEntryCopyWith<$Res> get licensing;

}
/// @nodoc
class _$FiscalLookupResultCopyWithImpl<$Res>
    implements $FiscalLookupResultCopyWith<$Res> {
  _$FiscalLookupResultCopyWithImpl(this._self, this._then);

  final FiscalLookupResult _self;
  final $Res Function(FiscalLookupResult) _then;

/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ipva = null,Object? licensing = null,Object? source = null,}) {
  return _then(_self.copyWith(
ipva: null == ipva ? _self.ipva : ipva // ignore: cast_nullable_to_non_nullable
as FiscalEntry,licensing: null == licensing ? _self.licensing : licensing // ignore: cast_nullable_to_non_nullable
as FiscalEntry,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FiscalLookupSource,
  ));
}
/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FiscalEntryCopyWith<$Res> get ipva {
  
  return $FiscalEntryCopyWith<$Res>(_self.ipva, (value) {
    return _then(_self.copyWith(ipva: value));
  });
}/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FiscalEntryCopyWith<$Res> get licensing {
  
  return $FiscalEntryCopyWith<$Res>(_self.licensing, (value) {
    return _then(_self.copyWith(licensing: value));
  });
}
}


/// Adds pattern-matching-related methods to [FiscalLookupResult].
extension FiscalLookupResultPatterns on FiscalLookupResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FiscalLookupResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FiscalLookupResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FiscalLookupResult value)  $default,){
final _that = this;
switch (_that) {
case _FiscalLookupResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FiscalLookupResult value)?  $default,){
final _that = this;
switch (_that) {
case _FiscalLookupResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FiscalEntry ipva,  FiscalEntry licensing,  FiscalLookupSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FiscalLookupResult() when $default != null:
return $default(_that.ipva,_that.licensing,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FiscalEntry ipva,  FiscalEntry licensing,  FiscalLookupSource source)  $default,) {final _that = this;
switch (_that) {
case _FiscalLookupResult():
return $default(_that.ipva,_that.licensing,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FiscalEntry ipva,  FiscalEntry licensing,  FiscalLookupSource source)?  $default,) {final _that = this;
switch (_that) {
case _FiscalLookupResult() when $default != null:
return $default(_that.ipva,_that.licensing,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FiscalLookupResult implements FiscalLookupResult {
  const _FiscalLookupResult({required this.ipva, required this.licensing, this.source = FiscalLookupSource.localFallback});
  factory _FiscalLookupResult.fromJson(Map<String, dynamic> json) => _$FiscalLookupResultFromJson(json);

@override final  FiscalEntry ipva;
@override final  FiscalEntry licensing;
@override@JsonKey() final  FiscalLookupSource source;

/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FiscalLookupResultCopyWith<_FiscalLookupResult> get copyWith => __$FiscalLookupResultCopyWithImpl<_FiscalLookupResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FiscalLookupResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FiscalLookupResult&&(identical(other.ipva, ipva) || other.ipva == ipva)&&(identical(other.licensing, licensing) || other.licensing == licensing)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ipva,licensing,source);

@override
String toString() {
  return 'FiscalLookupResult(ipva: $ipva, licensing: $licensing, source: $source)';
}


}

/// @nodoc
abstract mixin class _$FiscalLookupResultCopyWith<$Res> implements $FiscalLookupResultCopyWith<$Res> {
  factory _$FiscalLookupResultCopyWith(_FiscalLookupResult value, $Res Function(_FiscalLookupResult) _then) = __$FiscalLookupResultCopyWithImpl;
@override @useResult
$Res call({
 FiscalEntry ipva, FiscalEntry licensing, FiscalLookupSource source
});


@override $FiscalEntryCopyWith<$Res> get ipva;@override $FiscalEntryCopyWith<$Res> get licensing;

}
/// @nodoc
class __$FiscalLookupResultCopyWithImpl<$Res>
    implements _$FiscalLookupResultCopyWith<$Res> {
  __$FiscalLookupResultCopyWithImpl(this._self, this._then);

  final _FiscalLookupResult _self;
  final $Res Function(_FiscalLookupResult) _then;

/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ipva = null,Object? licensing = null,Object? source = null,}) {
  return _then(_FiscalLookupResult(
ipva: null == ipva ? _self.ipva : ipva // ignore: cast_nullable_to_non_nullable
as FiscalEntry,licensing: null == licensing ? _self.licensing : licensing // ignore: cast_nullable_to_non_nullable
as FiscalEntry,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as FiscalLookupSource,
  ));
}

/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FiscalEntryCopyWith<$Res> get ipva {
  
  return $FiscalEntryCopyWith<$Res>(_self.ipva, (value) {
    return _then(_self.copyWith(ipva: value));
  });
}/// Create a copy of FiscalLookupResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FiscalEntryCopyWith<$Res> get licensing {
  
  return $FiscalEntryCopyWith<$Res>(_self.licensing, (value) {
    return _then(_self.copyWith(licensing: value));
  });
}
}

// dart format on
