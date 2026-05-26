import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/json_converters.dart';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_receipt.freezed.dart';
part 'scanned_receipt.g.dart';

/// Dados extraídos pela IA a partir de um cupom de abastecimento.
///
/// Todos os campos são nullable: a IA pode falhar em extrair campos individuais.
/// O usuário revisa e confirma antes de salvar (Regra de Ouro #3).
@freezed
abstract class ScannedReceipt with _$ScannedReceipt {
  const factory ScannedReceipt({
    @DecimalJsonConverter() Decimal? liters,
    @DecimalJsonConverter() Decimal? pricePerLiter,
    @DecimalJsonConverter() Decimal? totalCost,
    DateTime? date,
    @FuelTypeConverter() FuelType? fuelType,
  }) = _ScannedReceipt;

  factory ScannedReceipt.fromJson(Map<String, dynamic> json) =>
      _$ScannedReceiptFromJson(json);
}
