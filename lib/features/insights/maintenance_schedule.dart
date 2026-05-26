import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_schedule.freezed.dart';
part 'maintenance_schedule.g.dart';

/// Calendário de manutenção sugerido pela IA para um veículo.
///
/// Retornado pelo [MaintenanceSuggestionService] após chamada à Edge Function
/// `suggest-maintenance`. A lista pode ser vazia se a IA não gerou itens válidos.
@freezed
abstract class MaintenanceSchedule with _$MaintenanceSchedule {
  const factory MaintenanceSchedule({
    required List<MaintenanceItem> items,
  }) = _MaintenanceSchedule;

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);
}

/// Um item de manutenção típico para o veículo.
///
/// [cadenceType] pode ser:
///   - `'km'` → manutenção a cada [everyKm] km.
///   - `'months'` → manutenção a cada [everyMonths] meses.
///   - `'km_or_months'` → o que vier primeiro.
@freezed
abstract class MaintenanceItem with _$MaintenanceItem {
  const factory MaintenanceItem({
    /// Descrição da manutenção, ex: "Troca de óleo".
    required String task,

    /// Tipo de cadência: 'km' | 'months' | 'km_or_months'.
    required String cadenceType,

    /// Intervalo em km (null se cadência não for por km).
    int? everyKm,

    /// Intervalo em meses (null se cadência não for por meses).
    int? everyMonths,

    /// Observações adicionais (opcional).
    String? notes,
  }) = _MaintenanceItem;

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceItemFromJson(json);
}
