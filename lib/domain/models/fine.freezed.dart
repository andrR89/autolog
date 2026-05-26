// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Fine {

 String get id; String get vehicleId; String? get autoNumber; DateTime get issuedAt; String get description;@DecimalJsonConverter() Decimal get amount; DateTime? get dueDate; bool get paid; int? get points; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;@SyncStatusConverter() SyncStatus get syncStatus;
/// Create a copy of Fine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FineCopyWith<Fine> get copyWith => _$FineCopyWithImpl<Fine>(this as Fine, _$identity);

  /// Serializes this Fine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Fine&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.autoNumber, autoNumber) || other.autoNumber == autoNumber)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.points, points) || other.points == points)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,autoNumber,issuedAt,description,amount,dueDate,paid,points,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Fine(id: $id, vehicleId: $vehicleId, autoNumber: $autoNumber, issuedAt: $issuedAt, description: $description, amount: $amount, dueDate: $dueDate, paid: $paid, points: $points, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $FineCopyWith<$Res>  {
  factory $FineCopyWith(Fine value, $Res Function(Fine) _then) = _$FineCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, String? autoNumber, DateTime issuedAt, String description,@DecimalJsonConverter() Decimal amount, DateTime? dueDate, bool paid, int? points, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class _$FineCopyWithImpl<$Res>
    implements $FineCopyWith<$Res> {
  _$FineCopyWithImpl(this._self, this._then);

  final Fine _self;
  final $Res Function(Fine) _then;

/// Create a copy of Fine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? autoNumber = freezed,Object? issuedAt = null,Object? description = null,Object? amount = null,Object? dueDate = freezed,Object? paid = null,Object? points = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,autoNumber: freezed == autoNumber ? _self.autoNumber : autoNumber // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Fine].
extension FinePatterns on Fine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Fine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Fine value)  $default,){
final _that = this;
switch (_that) {
case _Fine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Fine value)?  $default,){
final _that = this;
switch (_that) {
case _Fine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String? autoNumber,  DateTime issuedAt,  String description, @DecimalJsonConverter()  Decimal amount,  DateTime? dueDate,  bool paid,  int? points,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fine() when $default != null:
return $default(_that.id,_that.vehicleId,_that.autoNumber,_that.issuedAt,_that.description,_that.amount,_that.dueDate,_that.paid,_that.points,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  String? autoNumber,  DateTime issuedAt,  String description, @DecimalJsonConverter()  Decimal amount,  DateTime? dueDate,  bool paid,  int? points,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Fine():
return $default(_that.id,_that.vehicleId,_that.autoNumber,_that.issuedAt,_that.description,_that.amount,_that.dueDate,_that.paid,_that.points,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  String? autoNumber,  DateTime issuedAt,  String description, @DecimalJsonConverter()  Decimal amount,  DateTime? dueDate,  bool paid,  int? points,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt, @SyncStatusConverter()  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Fine() when $default != null:
return $default(_that.id,_that.vehicleId,_that.autoNumber,_that.issuedAt,_that.description,_that.amount,_that.dueDate,_that.paid,_that.points,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Fine implements Fine {
  const _Fine({required this.id, required this.vehicleId, this.autoNumber, required this.issuedAt, required this.description, @DecimalJsonConverter() required this.amount, this.dueDate, this.paid = false, this.points, required this.createdAt, required this.updatedAt, this.deletedAt, @SyncStatusConverter() required this.syncStatus});
  factory _Fine.fromJson(Map<String, dynamic> json) => _$FineFromJson(json);

@override final  String id;
@override final  String vehicleId;
@override final  String? autoNumber;
@override final  DateTime issuedAt;
@override final  String description;
@override@DecimalJsonConverter() final  Decimal amount;
@override final  DateTime? dueDate;
@override@JsonKey() final  bool paid;
@override final  int? points;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override@SyncStatusConverter() final  SyncStatus syncStatus;

/// Create a copy of Fine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FineCopyWith<_Fine> get copyWith => __$FineCopyWithImpl<_Fine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fine&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.autoNumber, autoNumber) || other.autoNumber == autoNumber)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.points, points) || other.points == points)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,autoNumber,issuedAt,description,amount,dueDate,paid,points,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Fine(id: $id, vehicleId: $vehicleId, autoNumber: $autoNumber, issuedAt: $issuedAt, description: $description, amount: $amount, dueDate: $dueDate, paid: $paid, points: $points, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$FineCopyWith<$Res> implements $FineCopyWith<$Res> {
  factory _$FineCopyWith(_Fine value, $Res Function(_Fine) _then) = __$FineCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, String? autoNumber, DateTime issuedAt, String description,@DecimalJsonConverter() Decimal amount, DateTime? dueDate, bool paid, int? points, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt,@SyncStatusConverter() SyncStatus syncStatus
});




}
/// @nodoc
class __$FineCopyWithImpl<$Res>
    implements _$FineCopyWith<$Res> {
  __$FineCopyWithImpl(this._self, this._then);

  final _Fine _self;
  final $Res Function(_Fine) _then;

/// Create a copy of Fine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? autoNumber = freezed,Object? issuedAt = null,Object? description = null,Object? amount = null,Object? dueDate = freezed,Object? paid = null,Object? points = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Fine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,autoNumber: freezed == autoNumber ? _self.autoNumber : autoNumber // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as bool,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
