// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  date: DateTime.parse(json['date'] as String),
  category: const ExpenseCategoryConverter().fromJson(
    json['category'] as String,
  ),
  description: json['description'] as String,
  amount: const DecimalJsonConverter().fromJson(json['amount'] as String),
  odometer: (json['odometer'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'date': instance.date.toIso8601String(),
  'category': const ExpenseCategoryConverter().toJson(instance.category),
  'description': instance.description,
  'amount': const DecimalJsonConverter().toJson(instance.amount),
  'odometer': instance.odometer,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
};
