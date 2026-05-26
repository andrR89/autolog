// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanned_expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScannedExpense {

@DecimalJsonConverter() Decimal? get amount; DateTime? get date;@ExpenseCategoryNullableConverter() ExpenseCategory? get category; String? get description; String? get documentType;
/// Create a copy of ScannedExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannedExpenseCopyWith<ScannedExpense> get copyWith => _$ScannedExpenseCopyWithImpl<ScannedExpense>(this as ScannedExpense, _$identity);

  /// Serializes this ScannedExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannedExpense&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.documentType, documentType) || other.documentType == documentType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,date,category,description,documentType);

@override
String toString() {
  return 'ScannedExpense(amount: $amount, date: $date, category: $category, description: $description, documentType: $documentType)';
}


}

/// @nodoc
abstract mixin class $ScannedExpenseCopyWith<$Res>  {
  factory $ScannedExpenseCopyWith(ScannedExpense value, $Res Function(ScannedExpense) _then) = _$ScannedExpenseCopyWithImpl;
@useResult
$Res call({
@DecimalJsonConverter() Decimal? amount, DateTime? date,@ExpenseCategoryNullableConverter() ExpenseCategory? category, String? description, String? documentType
});




}
/// @nodoc
class _$ScannedExpenseCopyWithImpl<$Res>
    implements $ScannedExpenseCopyWith<$Res> {
  _$ScannedExpenseCopyWithImpl(this._self, this._then);

  final ScannedExpense _self;
  final $Res Function(ScannedExpense) _then;

/// Create a copy of ScannedExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? date = freezed,Object? category = freezed,Object? description = freezed,Object? documentType = freezed,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,documentType: freezed == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannedExpense].
extension ScannedExpensePatterns on ScannedExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannedExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannedExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannedExpense value)  $default,){
final _that = this;
switch (_that) {
case _ScannedExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannedExpense value)?  $default,){
final _that = this;
switch (_that) {
case _ScannedExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalJsonConverter()  Decimal? amount,  DateTime? date, @ExpenseCategoryNullableConverter()  ExpenseCategory? category,  String? description,  String? documentType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannedExpense() when $default != null:
return $default(_that.amount,_that.date,_that.category,_that.description,_that.documentType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalJsonConverter()  Decimal? amount,  DateTime? date, @ExpenseCategoryNullableConverter()  ExpenseCategory? category,  String? description,  String? documentType)  $default,) {final _that = this;
switch (_that) {
case _ScannedExpense():
return $default(_that.amount,_that.date,_that.category,_that.description,_that.documentType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalJsonConverter()  Decimal? amount,  DateTime? date, @ExpenseCategoryNullableConverter()  ExpenseCategory? category,  String? description,  String? documentType)?  $default,) {final _that = this;
switch (_that) {
case _ScannedExpense() when $default != null:
return $default(_that.amount,_that.date,_that.category,_that.description,_that.documentType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScannedExpense implements ScannedExpense {
  const _ScannedExpense({@DecimalJsonConverter() this.amount, this.date, @ExpenseCategoryNullableConverter() this.category, this.description, this.documentType});
  factory _ScannedExpense.fromJson(Map<String, dynamic> json) => _$ScannedExpenseFromJson(json);

@override@DecimalJsonConverter() final  Decimal? amount;
@override final  DateTime? date;
@override@ExpenseCategoryNullableConverter() final  ExpenseCategory? category;
@override final  String? description;
@override final  String? documentType;

/// Create a copy of ScannedExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannedExpenseCopyWith<_ScannedExpense> get copyWith => __$ScannedExpenseCopyWithImpl<_ScannedExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScannedExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannedExpense&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.documentType, documentType) || other.documentType == documentType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,date,category,description,documentType);

@override
String toString() {
  return 'ScannedExpense(amount: $amount, date: $date, category: $category, description: $description, documentType: $documentType)';
}


}

/// @nodoc
abstract mixin class _$ScannedExpenseCopyWith<$Res> implements $ScannedExpenseCopyWith<$Res> {
  factory _$ScannedExpenseCopyWith(_ScannedExpense value, $Res Function(_ScannedExpense) _then) = __$ScannedExpenseCopyWithImpl;
@override @useResult
$Res call({
@DecimalJsonConverter() Decimal? amount, DateTime? date,@ExpenseCategoryNullableConverter() ExpenseCategory? category, String? description, String? documentType
});




}
/// @nodoc
class __$ScannedExpenseCopyWithImpl<$Res>
    implements _$ScannedExpenseCopyWith<$Res> {
  __$ScannedExpenseCopyWithImpl(this._self, this._then);

  final _ScannedExpense _self;
  final $Res Function(_ScannedExpense) _then;

/// Create a copy of ScannedExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? date = freezed,Object? category = freezed,Object? description = freezed,Object? documentType = freezed,}) {
  return _then(_ScannedExpense(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,documentType: freezed == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
