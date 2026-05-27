// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiscal_lookup_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FiscalEntry _$FiscalEntryFromJson(Map<String, dynamic> json) => _FiscalEntry(
  month: (json['month'] as num).toInt(),
  day: (json['day'] as num?)?.toInt(),
  sourceCitation: json['source'] as String?,
);

Map<String, dynamic> _$FiscalEntryToJson(_FiscalEntry instance) =>
    <String, dynamic>{
      'month': instance.month,
      'day': instance.day,
      'source': instance.sourceCitation,
    };

_FiscalLookupResult _$FiscalLookupResultFromJson(Map<String, dynamic> json) =>
    _FiscalLookupResult(
      ipva: FiscalEntry.fromJson(json['ipva'] as Map<String, dynamic>),
      licensing: FiscalEntry.fromJson(
        json['licensing'] as Map<String, dynamic>,
      ),
      source:
          $enumDecodeNullable(_$FiscalLookupSourceEnumMap, json['source']) ??
          FiscalLookupSource.localFallback,
    );

Map<String, dynamic> _$FiscalLookupResultToJson(_FiscalLookupResult instance) =>
    <String, dynamic>{
      'ipva': instance.ipva.toJson(),
      'licensing': instance.licensing.toJson(),
      'source': _$FiscalLookupSourceEnumMap[instance.source]!,
    };

const _$FiscalLookupSourceEnumMap = {
  FiscalLookupSource.ai: 'ai',
  FiscalLookupSource.localFallback: 'localFallback',
  FiscalLookupSource.cache: 'cache',
};
