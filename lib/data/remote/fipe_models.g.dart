// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fipe_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FipeBrand _$FipeBrandFromJson(Map<String, dynamic> json) =>
    _FipeBrand(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$FipeBrandToJson(_FipeBrand instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

_FipeModel _$FipeModelFromJson(Map<String, dynamic> json) =>
    _FipeModel(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$FipeModelToJson(_FipeModel instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

_FipeYear _$FipeYearFromJson(Map<String, dynamic> json) =>
    _FipeYear(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$FipeYearToJson(_FipeYear instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
};

_FipeVehicleDetails _$FipeVehicleDetailsFromJson(Map<String, dynamic> json) =>
    _FipeVehicleDetails(
      brand: _strOrDash(json['brand']),
      model: _strOrDash(json['model']),
      modelYear: _intOrZero(json['modelYear']),
      fipeCode: _strOrEmpty(json['fipeCode']),
      fuel: _strOrEmpty(json['fuel']),
      priceValue: _priceFromJson(json['price']),
      referenceMonth: _normalizeReferenceMonth(json['referenceMonth']),
    );

Map<String, dynamic> _$FipeVehicleDetailsToJson(_FipeVehicleDetails instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'model': instance.model,
      'modelYear': instance.modelYear,
      'fipeCode': instance.fipeCode,
      'fuel': instance.fuel,
      'price': const _DecimalToStringConverter().toJson(instance.priceValue),
      'referenceMonth': instance.referenceMonth,
    };
