// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reminder {

 String get id; String get vehicleId;@ReminderTypeConverter() ReminderType get type; String get title; int? get dueKm; DateTime? get dueDate; bool get isDone; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;@SyncStatusConverter() SyncStatus get syncStatus;// Recorrência (Sprint 6.MM) — ambos null = one-shot (comportamento original).
// intervalDays exige dueDate; intervalKm exige dueKm.
 int? get intervalDays; int? get intervalKm;// Id do lembrete anterior que gerou este (rastreabilidade).
 String? get parentReminderId;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.dueKm, dueKm) || other.dueKm == dueKm)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.parentReminderId, parentReminderId) || other.parentReminderId == parentReminderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,type,title,dueKm,dueDate,isDone,createdAt,updatedAt,deletedAt,syncStatus,intervalDays,intervalKm,parentReminderId);

@override
String toString() {
  return 'Reminder(id: $id, vehicleId: $vehicleId, type: $type, title: $title, dueKm: $dueKm, dueDate: $dueDate, isDone: $isDone, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus, intervalDays: $intervalDays, intervalKm: $intervalKm, parentReminderId: $parentReminderId)';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId,@ReminderTypeConverter() ReminderType type, String title, int? dueKm, DateTime? dueDate, bool isDone, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus, int? intervalDays, int? intervalKm, String? parentReminderId
});




}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? type = null,Object? title = null,Object? dueKm = freezed,Object? dueDate = freezed,Object? isDone = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,Object? intervalDays = freezed,Object? intervalKm = freezed,Object? parentReminderId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReminderType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dueKm: freezed == dueKm ? _self.dueKm : dueKm // ignore: cast_nullable_to_non_nullable
as int?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,intervalDays: freezed == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int?,intervalKm: freezed == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as int?,parentReminderId: freezed == parentReminderId ? _self.parentReminderId : parentReminderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId, @ReminderTypeConverter()  ReminderType type,  String title,  int? dueKm,  DateTime? dueDate,  bool isDone,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus,  int? intervalDays,  int? intervalKm,  String? parentReminderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.vehicleId,_that.type,_that.title,_that.dueKm,_that.dueDate,_that.isDone,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus,_that.intervalDays,_that.intervalKm,_that.parentReminderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId, @ReminderTypeConverter()  ReminderType type,  String title,  int? dueKm,  DateTime? dueDate,  bool isDone,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus,  int? intervalDays,  int? intervalKm,  String? parentReminderId)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.id,_that.vehicleId,_that.type,_that.title,_that.dueKm,_that.dueDate,_that.isDone,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus,_that.intervalDays,_that.intervalKm,_that.parentReminderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId, @ReminderTypeConverter()  ReminderType type,  String title,  int? dueKm,  DateTime? dueDate,  bool isDone,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus,  int? intervalDays,  int? intervalKm,  String? parentReminderId)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.vehicleId,_that.type,_that.title,_that.dueKm,_that.dueDate,_that.isDone,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus,_that.intervalDays,_that.intervalKm,_that.parentReminderId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reminder implements Reminder {
  const _Reminder({required this.id, required this.vehicleId, @ReminderTypeConverter() required this.type, required this.title, this.dueKm, this.dueDate, required this.isDone, required this.createdAt, required this.updatedAt, this.deletedAt, @SyncStatusConverter() required this.syncStatus, this.intervalDays, this.intervalKm, this.parentReminderId});
  factory _Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override@ReminderTypeConverter() final  ReminderType type;
@override final  String title;
@override final  int? dueKm;
@override final  DateTime? dueDate;
@override final  bool isDone;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override@SyncStatusConverter() final  SyncStatus syncStatus;
// Recorrência (Sprint 6.MM) — ambos null = one-shot (comportamento original).
// intervalDays exige dueDate; intervalKm exige dueKm.
@override final  int? intervalDays;
@override final  int? intervalKm;
// Id do lembrete anterior que gerou este (rastreabilidade).
@override final  String? parentReminderId;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.dueKm, dueKm) || other.dueKm == dueKm)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.intervalKm, intervalKm) || other.intervalKm == intervalKm)&&(identical(other.parentReminderId, parentReminderId) || other.parentReminderId == parentReminderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,type,title,dueKm,dueDate,isDone,createdAt,updatedAt,deletedAt,syncStatus,intervalDays,intervalKm,parentReminderId);

@override
String toString() {
  return 'Reminder(id: $id, vehicleId: $vehicleId, type: $type, title: $title, dueKm: $dueKm, dueDate: $dueDate, isDone: $isDone, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus, intervalDays: $intervalDays, intervalKm: $intervalKm, parentReminderId: $parentReminderId)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId,@ReminderTypeConverter() ReminderType type, String title, int? dueKm, DateTime? dueDate, bool isDone, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus, int? intervalDays, int? intervalKm, String? parentReminderId
});




}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? type = null,Object? title = null,Object? dueKm = freezed,Object? dueDate = freezed,Object? isDone = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,Object? intervalDays = freezed,Object? intervalKm = freezed,Object? parentReminderId = freezed,}) {
  return _then(_Reminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReminderType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dueKm: freezed == dueKm ? _self.dueKm : dueKm // ignore: cast_nullable_to_non_nullable
as int?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,intervalDays: freezed == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int?,intervalKm: freezed == intervalKm ? _self.intervalKm : intervalKm // ignore: cast_nullable_to_non_nullable
as int?,parentReminderId: freezed == parentReminderId ? _self.parentReminderId : parentReminderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
