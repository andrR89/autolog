// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScannedExpense _$ScannedExpenseFromJson(Map<String, dynamic> json) =>
    _ScannedExpense(
      amount: _$JsonConverterFromJson<String, Decimal>(
        json['amount'],
        const DecimalJsonConverter().fromJson,
      ),
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      category: const ExpenseCategoryNullableConverter().fromJson(
        json['category'] as String?,
      ),
      description: json['description'] as String?,
      documentType: json['document_type'] as String?,
    );

Map<String, dynamic> _$ScannedExpenseToJson(_ScannedExpense instance) =>
    <String, dynamic>{
      'amount': _$JsonConverterToJson<String, Decimal>(
        instance.amount,
        const DecimalJsonConverter().toJson,
      ),
      'date': instance.date?.toIso8601String(),
      'category': const ExpenseCategoryNullableConverter().toJson(
        instance.category,
      ),
      'description': instance.description,
      'document_type': instance.documentType,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
