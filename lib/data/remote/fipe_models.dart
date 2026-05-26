import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fipe_models.freezed.dart';
part 'fipe_models.g.dart';

// ---------------------------------------------------------------------------
// Mapeamento PT-BR de mês → número (API parallelum retorna "janeiro de 2026")
// ---------------------------------------------------------------------------

const _ptBrMonths = {
  'janeiro': '01',
  'fevereiro': '02',
  'março': '03',
  'abril': '04',
  'maio': '05',
  'junho': '06',
  'julho': '07',
  'agosto': '08',
  'setembro': '09',
  'outubro': '10',
  'novembro': '11',
  'dezembro': '12',
};

/// Normaliza "janeiro de 2026" → "2026-01".
/// Se o formato não for reconhecido, retorna a string original.
/// Defensivo: aceita null/non-string da API → retorna vazio (regressão 6.I).
String _normalizeReferenceMonth(Object? raw) {
  if (raw is! String) return '';
  // Formato esperado: "mês de YYYY"
  final parts = raw.trim().toLowerCase().split(' de ');
  if (parts.length == 2) {
    final month = _ptBrMonths[parts[0].trim()];
    final year = parts[1].trim();
    if (month != null) {
      return '$year-$month';
    }
  }
  return raw;
}

// --- helpers defensivos (regressão 26/05/2026): API parallelum às vezes ---
// --- retorna campos String/num como null e o cast `as T` crashava o app. ---

/// String com fallback "—" pra campos visíveis (brand/model).
String _strOrDash(Object? v) => v is String && v.isNotEmpty ? v : '—';

/// String com fallback "" pra códigos opcionais (fipeCode/fuel).
String _strOrEmpty(Object? v) => v is String ? v : '';

/// Int com fallback 0; aceita num, string parseável, ou null.
int _intOrZero(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Parse defensivo do priceValue: aceita String formatada "R$ 78.420,00"
/// ou número numérico (int/double).
Decimal _priceFromJson(dynamic json) {
  if (json is num) {
    return Decimal.parse(json.toString());
  }
  if (json is String) {
    // Remove "R$" prefix e espaços
    var cleaned = json.replaceAll(r'R$', '').trim();
    // Remove separador de milhar (ponto em PT-BR) e converte vírgula decimal
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return Decimal.parse(cleaned);
  }
  throw FormatException('Não foi possível converter priceValue: $json');
}

/// Converte Decimal → String para serialização JSON do cache.
class _DecimalToStringConverter implements JsonConverter<Decimal, String> {
  const _DecimalToStringConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  @override
  String toJson(Decimal object) => object.toString();
}

// ---------------------------------------------------------------------------
// Modelos FIPE — simples
// ---------------------------------------------------------------------------

@freezed
abstract class FipeBrand with _$FipeBrand {
  const factory FipeBrand({
    required String code,
    required String name,
  }) = _FipeBrand;

  factory FipeBrand.fromJson(Map<String, dynamic> json) =>
      _$FipeBrandFromJson(json);
}

@freezed
abstract class FipeModel with _$FipeModel {
  const factory FipeModel({
    required String code,
    required String name,
  }) = _FipeModel;

  factory FipeModel.fromJson(Map<String, dynamic> json) =>
      _$FipeModelFromJson(json);
}

@freezed
abstract class FipeYear with _$FipeYear {
  const factory FipeYear({
    required String code,
    required String name,
  }) = _FipeYear;

  factory FipeYear.fromJson(Map<String, dynamic> json) =>
      _$FipeYearFromJson(json);
}

// ---------------------------------------------------------------------------
// FipeVehicleDetails — parse defensivo com fromJson customizado
// ---------------------------------------------------------------------------

@freezed
abstract class FipeVehicleDetails with _$FipeVehicleDetails {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory FipeVehicleDetails({
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _strOrDash) required String brand,
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _strOrDash) required String model,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'modelYear', fromJson: _intOrZero) required int modelYear,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'fipeCode', fromJson: _strOrEmpty) required String fipeCode,
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _strOrEmpty) required String fuel,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'price', fromJson: _priceFromJson)
    @_DecimalToStringConverter()
    required Decimal priceValue,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'referenceMonth', fromJson: _normalizeReferenceMonth)
    required String referenceMonth,
  }) = _FipeVehicleDetails;

  factory FipeVehicleDetails.fromJson(Map<String, dynamic> json) =>
      _$FipeVehicleDetailsFromJson(json);
}
