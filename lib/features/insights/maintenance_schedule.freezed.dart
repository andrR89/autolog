// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceSchedule {

 List<MaintenanceItem> get items;
/// Create a copy of MaintenanceSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceScheduleCopyWith<MaintenanceSchedule> get copyWith => _$MaintenanceScheduleCopyWithImpl<MaintenanceSchedule>(this as MaintenanceSchedule, _$identity);

  /// Serializes this MaintenanceSchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceSchedule&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'MaintenanceSchedule(items: $items)';
}


}

/// @nodoc
abstract mixin class $MaintenanceScheduleCopyWith<$Res>  {
  factory $MaintenanceScheduleCopyWith(MaintenanceSchedule value, $Res Function(MaintenanceSchedule) _then) = _$MaintenanceScheduleCopyWithImpl;
@useResult
$Res call({
 List<MaintenanceItem> items
});




}
/// @nodoc
class _$MaintenanceScheduleCopyWithImpl<$Res>
    implements $MaintenanceScheduleCopyWith<$Res> {
  _$MaintenanceScheduleCopyWithImpl(this._self, this._then);

  final MaintenanceSchedule _self;
  final $Res Function(MaintenanceSchedule) _then;

/// Create a copy of MaintenanceSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MaintenanceItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceSchedule].
extension MaintenanceSchedulePatterns on MaintenanceSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceSchedule value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MaintenanceItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceSchedule() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MaintenanceItem> items)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceSchedule():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MaintenanceItem> items)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceSchedule() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceSchedule implements MaintenanceSchedule {
  const _MaintenanceSchedule({required final  List<MaintenanceItem> items}): _items = items;
  factory _MaintenanceSchedule.fromJson(Map<String, dynamic> json) => _$MaintenanceScheduleFromJson(json);

 final  List<MaintenanceItem> _items;
@override List<MaintenanceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MaintenanceSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceScheduleCopyWith<_MaintenanceSchedule> get copyWith => __$MaintenanceScheduleCopyWithImpl<_MaintenanceSchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceSchedule&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'MaintenanceSchedule(items: $items)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceScheduleCopyWith<$Res> implements $MaintenanceScheduleCopyWith<$Res> {
  factory _$MaintenanceScheduleCopyWith(_MaintenanceSchedule value, $Res Function(_MaintenanceSchedule) _then) = __$MaintenanceScheduleCopyWithImpl;
@override @useResult
$Res call({
 List<MaintenanceItem> items
});




}
/// @nodoc
class __$MaintenanceScheduleCopyWithImpl<$Res>
    implements _$MaintenanceScheduleCopyWith<$Res> {
  __$MaintenanceScheduleCopyWithImpl(this._self, this._then);

  final _MaintenanceSchedule _self;
  final $Res Function(_MaintenanceSchedule) _then;

/// Create a copy of MaintenanceSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_MaintenanceSchedule(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MaintenanceItem>,
  ));
}


}


/// @nodoc
mixin _$MaintenanceItem {

/// Descrição da manutenção, ex: "Troca de óleo".
 String get task;/// Tipo de cadência: 'km' | 'months' | 'km_or_months'.
 String get cadenceType;/// Intervalo em km (null se cadência não for por km).
 int? get everyKm;/// Intervalo em meses (null se cadência não for por meses).
 int? get everyMonths;/// Observações adicionais (opcional).
 String? get notes;
/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceItemCopyWith<MaintenanceItem> get copyWith => _$MaintenanceItemCopyWithImpl<MaintenanceItem>(this as MaintenanceItem, _$identity);

  /// Serializes this MaintenanceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceItem&&(identical(other.task, task) || other.task == task)&&(identical(other.cadenceType, cadenceType) || other.cadenceType == cadenceType)&&(identical(other.everyKm, everyKm) || other.everyKm == everyKm)&&(identical(other.everyMonths, everyMonths) || other.everyMonths == everyMonths)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,task,cadenceType,everyKm,everyMonths,notes);

@override
String toString() {
  return 'MaintenanceItem(task: $task, cadenceType: $cadenceType, everyKm: $everyKm, everyMonths: $everyMonths, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MaintenanceItemCopyWith<$Res>  {
  factory $MaintenanceItemCopyWith(MaintenanceItem value, $Res Function(MaintenanceItem) _then) = _$MaintenanceItemCopyWithImpl;
@useResult
$Res call({
 String task, String cadenceType, int? everyKm, int? everyMonths, String? notes
});




}
/// @nodoc
class _$MaintenanceItemCopyWithImpl<$Res>
    implements $MaintenanceItemCopyWith<$Res> {
  _$MaintenanceItemCopyWithImpl(this._self, this._then);

  final MaintenanceItem _self;
  final $Res Function(MaintenanceItem) _then;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? task = null,Object? cadenceType = null,Object? everyKm = freezed,Object? everyMonths = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,cadenceType: null == cadenceType ? _self.cadenceType : cadenceType // ignore: cast_nullable_to_non_nullable
as String,everyKm: freezed == everyKm ? _self.everyKm : everyKm // ignore: cast_nullable_to_non_nullable
as int?,everyMonths: freezed == everyMonths ? _self.everyMonths : everyMonths // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceItem].
extension MaintenanceItemPatterns on MaintenanceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceItem value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceItem value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String task,  String cadenceType,  int? everyKm,  int? everyMonths,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
return $default(_that.task,_that.cadenceType,_that.everyKm,_that.everyMonths,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String task,  String cadenceType,  int? everyKm,  int? everyMonths,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceItem():
return $default(_that.task,_that.cadenceType,_that.everyKm,_that.everyMonths,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String task,  String cadenceType,  int? everyKm,  int? everyMonths,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceItem() when $default != null:
return $default(_that.task,_that.cadenceType,_that.everyKm,_that.everyMonths,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MaintenanceItem implements MaintenanceItem {
  const _MaintenanceItem({required this.task, required this.cadenceType, this.everyKm, this.everyMonths, this.notes});
  factory _MaintenanceItem.fromJson(Map<String, dynamic> json) => _$MaintenanceItemFromJson(json);

/// Descrição da manutenção, ex: "Troca de óleo".
@override final  String task;
/// Tipo de cadência: 'km' | 'months' | 'km_or_months'.
@override final  String cadenceType;
/// Intervalo em km (null se cadência não for por km).
@override final  int? everyKm;
/// Intervalo em meses (null se cadência não for por meses).
@override final  int? everyMonths;
/// Observações adicionais (opcional).
@override final  String? notes;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceItemCopyWith<_MaintenanceItem> get copyWith => __$MaintenanceItemCopyWithImpl<_MaintenanceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaintenanceItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceItem&&(identical(other.task, task) || other.task == task)&&(identical(other.cadenceType, cadenceType) || other.cadenceType == cadenceType)&&(identical(other.everyKm, everyKm) || other.everyKm == everyKm)&&(identical(other.everyMonths, everyMonths) || other.everyMonths == everyMonths)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,task,cadenceType,everyKm,everyMonths,notes);

@override
String toString() {
  return 'MaintenanceItem(task: $task, cadenceType: $cadenceType, everyKm: $everyKm, everyMonths: $everyMonths, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceItemCopyWith<$Res> implements $MaintenanceItemCopyWith<$Res> {
  factory _$MaintenanceItemCopyWith(_MaintenanceItem value, $Res Function(_MaintenanceItem) _then) = __$MaintenanceItemCopyWithImpl;
@override @useResult
$Res call({
 String task, String cadenceType, int? everyKm, int? everyMonths, String? notes
});




}
/// @nodoc
class __$MaintenanceItemCopyWithImpl<$Res>
    implements _$MaintenanceItemCopyWith<$Res> {
  __$MaintenanceItemCopyWithImpl(this._self, this._then);

  final _MaintenanceItem _self;
  final $Res Function(_MaintenanceItem) _then;

/// Create a copy of MaintenanceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? task = null,Object? cadenceType = null,Object? everyKm = freezed,Object? everyMonths = freezed,Object? notes = freezed,}) {
  return _then(_MaintenanceItem(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,cadenceType: null == cadenceType ? _self.cadenceType : cadenceType // ignore: cast_nullable_to_non_nullable
as String,everyKm: freezed == everyKm ? _self.everyKm : everyKm // ignore: cast_nullable_to_non_nullable
as int?,everyMonths: freezed == everyMonths ? _self.everyMonths : everyMonths // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
