import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_crlv.freezed.dart';
part 'scanned_crlv.g.dart';

/// Dados extraídos pela IA a partir de um CRLV-e (foto ou PDF).
///
/// Todos os campos são nullable: a IA pode falhar em extrair campos individuais.
/// O usuário revisa e confirma antes de salvar (Regra de Ouro #3).
@freezed
abstract class ScannedCrlv with _$ScannedCrlv {
  const factory ScannedCrlv({
    String? plate,
    String? renavam,
    String? chassi,
    String? color,
    @FuelTypeNullableConverter() FuelType? fuelType,
    String? make,
    String? model,
    int? year,
  }) = _ScannedCrlv;

  factory ScannedCrlv.fromJson(Map<String, dynamic> json) =>
      _$ScannedCrlvFromJson(json);
}
