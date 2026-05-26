// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_insights.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryInsights {

 List<DetectedPattern> get patterns; List<ProposedReminder> get proposedReminders;
/// Create a copy of HistoryInsights
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryInsightsCopyWith<HistoryInsights> get copyWith => _$HistoryInsightsCopyWithImpl<HistoryInsights>(this as HistoryInsights, _$identity);

  /// Serializes this HistoryInsights to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryInsights&&const DeepCollectionEquality().equals(other.patterns, patterns)&&const DeepCollectionEquality().equals(other.proposedReminders, proposedReminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(patterns),const DeepCollectionEquality().hash(proposedReminders));

@override
String toString() {
  return 'HistoryInsights(patterns: $patterns, proposedReminders: $proposedReminders)';
}


}

/// @nodoc
abstract mixin class $HistoryInsightsCopyWith<$Res>  {
  factory $HistoryInsightsCopyWith(HistoryInsights value, $Res Function(HistoryInsights) _then) = _$HistoryInsightsCopyWithImpl;
@useResult
$Res call({
 List<DetectedPattern> patterns, List<ProposedReminder> proposedReminders
});




}
/// @nodoc
class _$HistoryInsightsCopyWithImpl<$Res>
    implements $HistoryInsightsCopyWith<$Res> {
  _$HistoryInsightsCopyWithImpl(this._self, this._then);

  final HistoryInsights _self;
  final $Res Function(HistoryInsights) _then;

/// Create a copy of HistoryInsights
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? patterns = null,Object? proposedReminders = null,}) {
  return _then(_self.copyWith(
patterns: null == patterns ? _self.patterns : patterns // ignore: cast_nullable_to_non_nullable
as List<DetectedPattern>,proposedReminders: null == proposedReminders ? _self.proposedReminders : proposedReminders // ignore: cast_nullable_to_non_nullable
as List<ProposedReminder>,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryInsights].
extension HistoryInsightsPatterns on HistoryInsights {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryInsights value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryInsights() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryInsights value)  $default,){
final _that = this;
switch (_that) {
case _HistoryInsights():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryInsights value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryInsights() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DetectedPattern> patterns,  List<ProposedReminder> proposedReminders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryInsights() when $default != null:
return $default(_that.patterns,_that.proposedReminders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DetectedPattern> patterns,  List<ProposedReminder> proposedReminders)  $default,) {final _that = this;
switch (_that) {
case _HistoryInsights():
return $default(_that.patterns,_that.proposedReminders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DetectedPattern> patterns,  List<ProposedReminder> proposedReminders)?  $default,) {final _that = this;
switch (_that) {
case _HistoryInsights() when $default != null:
return $default(_that.patterns,_that.proposedReminders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryInsights implements HistoryInsights {
  const _HistoryInsights({required final  List<DetectedPattern> patterns, required final  List<ProposedReminder> proposedReminders}): _patterns = patterns,_proposedReminders = proposedReminders;
  factory _HistoryInsights.fromJson(Map<String, dynamic> json) => _$HistoryInsightsFromJson(json);

 final  List<DetectedPattern> _patterns;
@override List<DetectedPattern> get patterns {
  if (_patterns is EqualUnmodifiableListView) return _patterns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patterns);
}

 final  List<ProposedReminder> _proposedReminders;
@override List<ProposedReminder> get proposedReminders {
  if (_proposedReminders is EqualUnmodifiableListView) return _proposedReminders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_proposedReminders);
}


/// Create a copy of HistoryInsights
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryInsightsCopyWith<_HistoryInsights> get copyWith => __$HistoryInsightsCopyWithImpl<_HistoryInsights>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryInsightsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryInsights&&const DeepCollectionEquality().equals(other._patterns, _patterns)&&const DeepCollectionEquality().equals(other._proposedReminders, _proposedReminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_patterns),const DeepCollectionEquality().hash(_proposedReminders));

@override
String toString() {
  return 'HistoryInsights(patterns: $patterns, proposedReminders: $proposedReminders)';
}


}

/// @nodoc
abstract mixin class _$HistoryInsightsCopyWith<$Res> implements $HistoryInsightsCopyWith<$Res> {
  factory _$HistoryInsightsCopyWith(_HistoryInsights value, $Res Function(_HistoryInsights) _then) = __$HistoryInsightsCopyWithImpl;
@override @useResult
$Res call({
 List<DetectedPattern> patterns, List<ProposedReminder> proposedReminders
});




}
/// @nodoc
class __$HistoryInsightsCopyWithImpl<$Res>
    implements _$HistoryInsightsCopyWith<$Res> {
  __$HistoryInsightsCopyWithImpl(this._self, this._then);

  final _HistoryInsights _self;
  final $Res Function(_HistoryInsights) _then;

/// Create a copy of HistoryInsights
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? patterns = null,Object? proposedReminders = null,}) {
  return _then(_HistoryInsights(
patterns: null == patterns ? _self._patterns : patterns // ignore: cast_nullable_to_non_nullable
as List<DetectedPattern>,proposedReminders: null == proposedReminders ? _self._proposedReminders : proposedReminders // ignore: cast_nullable_to_non_nullable
as List<ProposedReminder>,
  ));
}


}


/// @nodoc
mixin _$DetectedPattern {

/// Categoria do padrão (ex: "ipva", "manutencao_periodica").
 String get category;/// Cadência: 'yearly' | 'monthly' | 'every_N_km' | 'unknown'.
 String get cadence;/// Próxima ocorrência estimada (null se cadência for por km ou desconhecida).
 DateTime? get nextDue;/// Confiança do modelo (0.0–1.0). Default 0.0.
 double get confidence;/// Justificativa textual do modelo (opcional).
 String? get rationale;
/// Create a copy of DetectedPattern
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectedPatternCopyWith<DetectedPattern> get copyWith => _$DetectedPatternCopyWithImpl<DetectedPattern>(this as DetectedPattern, _$identity);

  /// Serializes this DetectedPattern to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectedPattern&&(identical(other.category, category) || other.category == category)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&(identical(other.nextDue, nextDue) || other.nextDue == nextDue)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rationale, rationale) || other.rationale == rationale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,cadence,nextDue,confidence,rationale);

@override
String toString() {
  return 'DetectedPattern(category: $category, cadence: $cadence, nextDue: $nextDue, confidence: $confidence, rationale: $rationale)';
}


}

/// @nodoc
abstract mixin class $DetectedPatternCopyWith<$Res>  {
  factory $DetectedPatternCopyWith(DetectedPattern value, $Res Function(DetectedPattern) _then) = _$DetectedPatternCopyWithImpl;
@useResult
$Res call({
 String category, String cadence, DateTime? nextDue, double confidence, String? rationale
});




}
/// @nodoc
class _$DetectedPatternCopyWithImpl<$Res>
    implements $DetectedPatternCopyWith<$Res> {
  _$DetectedPatternCopyWithImpl(this._self, this._then);

  final DetectedPattern _self;
  final $Res Function(DetectedPattern) _then;

/// Create a copy of DetectedPattern
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? cadence = null,Object? nextDue = freezed,Object? confidence = null,Object? rationale = freezed,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as String,nextDue: freezed == nextDue ? _self.nextDue : nextDue // ignore: cast_nullable_to_non_nullable
as DateTime?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rationale: freezed == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DetectedPattern].
extension DetectedPatternPatterns on DetectedPattern {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetectedPattern value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetectedPattern() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetectedPattern value)  $default,){
final _that = this;
switch (_that) {
case _DetectedPattern():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetectedPattern value)?  $default,){
final _that = this;
switch (_that) {
case _DetectedPattern() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  String cadence,  DateTime? nextDue,  double confidence,  String? rationale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetectedPattern() when $default != null:
return $default(_that.category,_that.cadence,_that.nextDue,_that.confidence,_that.rationale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  String cadence,  DateTime? nextDue,  double confidence,  String? rationale)  $default,) {final _that = this;
switch (_that) {
case _DetectedPattern():
return $default(_that.category,_that.cadence,_that.nextDue,_that.confidence,_that.rationale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  String cadence,  DateTime? nextDue,  double confidence,  String? rationale)?  $default,) {final _that = this;
switch (_that) {
case _DetectedPattern() when $default != null:
return $default(_that.category,_that.cadence,_that.nextDue,_that.confidence,_that.rationale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetectedPattern implements DetectedPattern {
  const _DetectedPattern({required this.category, required this.cadence, this.nextDue, this.confidence = 0.0, this.rationale});
  factory _DetectedPattern.fromJson(Map<String, dynamic> json) => _$DetectedPatternFromJson(json);

/// Categoria do padrão (ex: "ipva", "manutencao_periodica").
@override final  String category;
/// Cadência: 'yearly' | 'monthly' | 'every_N_km' | 'unknown'.
@override final  String cadence;
/// Próxima ocorrência estimada (null se cadência for por km ou desconhecida).
@override final  DateTime? nextDue;
/// Confiança do modelo (0.0–1.0). Default 0.0.
@override@JsonKey() final  double confidence;
/// Justificativa textual do modelo (opcional).
@override final  String? rationale;

/// Create a copy of DetectedPattern
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectedPatternCopyWith<_DetectedPattern> get copyWith => __$DetectedPatternCopyWithImpl<_DetectedPattern>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectedPatternToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetectedPattern&&(identical(other.category, category) || other.category == category)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&(identical(other.nextDue, nextDue) || other.nextDue == nextDue)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rationale, rationale) || other.rationale == rationale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,cadence,nextDue,confidence,rationale);

@override
String toString() {
  return 'DetectedPattern(category: $category, cadence: $cadence, nextDue: $nextDue, confidence: $confidence, rationale: $rationale)';
}


}

/// @nodoc
abstract mixin class _$DetectedPatternCopyWith<$Res> implements $DetectedPatternCopyWith<$Res> {
  factory _$DetectedPatternCopyWith(_DetectedPattern value, $Res Function(_DetectedPattern) _then) = __$DetectedPatternCopyWithImpl;
@override @useResult
$Res call({
 String category, String cadence, DateTime? nextDue, double confidence, String? rationale
});




}
/// @nodoc
class __$DetectedPatternCopyWithImpl<$Res>
    implements _$DetectedPatternCopyWith<$Res> {
  __$DetectedPatternCopyWithImpl(this._self, this._then);

  final _DetectedPattern _self;
  final $Res Function(_DetectedPattern) _then;

/// Create a copy of DetectedPattern
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? cadence = null,Object? nextDue = freezed,Object? confidence = null,Object? rationale = freezed,}) {
  return _then(_DetectedPattern(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as String,nextDue: freezed == nextDue ? _self.nextDue : nextDue // ignore: cast_nullable_to_non_nullable
as DateTime?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,rationale: freezed == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProposedReminder {

/// Título do lembrete proposto.
 String get title;/// Data de vencimento estimada (null para lembretes por km).
 DateTime? get dueDate;/// Quilometragem de vencimento estimada (null para lembretes por data).
 int? get dueKm;/// Justificativa textual. Default string vazia.
 String get rationale;
/// Create a copy of ProposedReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProposedReminderCopyWith<ProposedReminder> get copyWith => _$ProposedReminderCopyWithImpl<ProposedReminder>(this as ProposedReminder, _$identity);

  /// Serializes this ProposedReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProposedReminder&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueKm, dueKm) || other.dueKm == dueKm)&&(identical(other.rationale, rationale) || other.rationale == rationale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dueDate,dueKm,rationale);

@override
String toString() {
  return 'ProposedReminder(title: $title, dueDate: $dueDate, dueKm: $dueKm, rationale: $rationale)';
}


}

/// @nodoc
abstract mixin class $ProposedReminderCopyWith<$Res>  {
  factory $ProposedReminderCopyWith(ProposedReminder value, $Res Function(ProposedReminder) _then) = _$ProposedReminderCopyWithImpl;
@useResult
$Res call({
 String title, DateTime? dueDate, int? dueKm, String rationale
});




}
/// @nodoc
class _$ProposedReminderCopyWithImpl<$Res>
    implements $ProposedReminderCopyWith<$Res> {
  _$ProposedReminderCopyWithImpl(this._self, this._then);

  final ProposedReminder _self;
  final $Res Function(ProposedReminder) _then;

/// Create a copy of ProposedReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? dueDate = freezed,Object? dueKm = freezed,Object? rationale = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueKm: freezed == dueKm ? _self.dueKm : dueKm // ignore: cast_nullable_to_non_nullable
as int?,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProposedReminder].
extension ProposedReminderPatterns on ProposedReminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProposedReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProposedReminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProposedReminder value)  $default,){
final _that = this;
switch (_that) {
case _ProposedReminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProposedReminder value)?  $default,){
final _that = this;
switch (_that) {
case _ProposedReminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  DateTime? dueDate,  int? dueKm,  String rationale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProposedReminder() when $default != null:
return $default(_that.title,_that.dueDate,_that.dueKm,_that.rationale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  DateTime? dueDate,  int? dueKm,  String rationale)  $default,) {final _that = this;
switch (_that) {
case _ProposedReminder():
return $default(_that.title,_that.dueDate,_that.dueKm,_that.rationale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  DateTime? dueDate,  int? dueKm,  String rationale)?  $default,) {final _that = this;
switch (_that) {
case _ProposedReminder() when $default != null:
return $default(_that.title,_that.dueDate,_that.dueKm,_that.rationale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProposedReminder implements ProposedReminder {
  const _ProposedReminder({required this.title, this.dueDate, this.dueKm, this.rationale = ''});
  factory _ProposedReminder.fromJson(Map<String, dynamic> json) => _$ProposedReminderFromJson(json);

/// Título do lembrete proposto.
@override final  String title;
/// Data de vencimento estimada (null para lembretes por km).
@override final  DateTime? dueDate;
/// Quilometragem de vencimento estimada (null para lembretes por data).
@override final  int? dueKm;
/// Justificativa textual. Default string vazia.
@override@JsonKey() final  String rationale;

/// Create a copy of ProposedReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProposedReminderCopyWith<_ProposedReminder> get copyWith => __$ProposedReminderCopyWithImpl<_ProposedReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProposedReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProposedReminder&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueKm, dueKm) || other.dueKm == dueKm)&&(identical(other.rationale, rationale) || other.rationale == rationale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dueDate,dueKm,rationale);

@override
String toString() {
  return 'ProposedReminder(title: $title, dueDate: $dueDate, dueKm: $dueKm, rationale: $rationale)';
}


}

/// @nodoc
abstract mixin class _$ProposedReminderCopyWith<$Res> implements $ProposedReminderCopyWith<$Res> {
  factory _$ProposedReminderCopyWith(_ProposedReminder value, $Res Function(_ProposedReminder) _then) = __$ProposedReminderCopyWithImpl;
@override @useResult
$Res call({
 String title, DateTime? dueDate, int? dueKm, String rationale
});




}
/// @nodoc
class __$ProposedReminderCopyWithImpl<$Res>
    implements _$ProposedReminderCopyWith<$Res> {
  __$ProposedReminderCopyWithImpl(this._self, this._then);

  final _ProposedReminder _self;
  final $Res Function(_ProposedReminder) _then;

/// Create a copy of ProposedReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? dueDate = freezed,Object? dueKm = freezed,Object? rationale = null,}) {
  return _then(_ProposedReminder(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueKm: freezed == dueKm ? _self.dueKm : dueKm // ignore: cast_nullable_to_non_nullable
as int?,rationale: null == rationale ? _self.rationale : rationale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
