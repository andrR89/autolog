import 'package:autolog/domain/models/fuel_entry.dart';

/// Retorna null se [dueKm] é válido como alvo (maior que o odômetro atual
/// do veículo), ou uma mensagem PT-BR explicando.
String? validateDueKm({
  required int dueKm,
  required int vehicleInitialOdometer,
  required List<FuelEntry> entries,
}) {
  int currentMax = vehicleInitialOdometer;
  for (final e in entries) {
    if (e.deletedAt != null) continue;
    if (e.odometer > currentMax) currentMax = e.odometer;
  }
  if (dueKm <= currentMax) {
    return 'Quilometragem alvo deve ser maior que a atual ($currentMax km).';
  }
  return null;
}
