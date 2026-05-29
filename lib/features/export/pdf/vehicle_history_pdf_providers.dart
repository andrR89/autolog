// lib/features/export/pdf/vehicle_history_pdf_providers.dart
//
// Sprint 6.Y — PDF Histórico do Veículo.
//
// Provider Riverpod do VehicleHistoryPdfService.
// Em testes, faça override com MockVehicleHistoryPdfService via ProviderScope.

import 'package:autolog/features/export/pdf/vehicle_history_pdf_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider principal do [VehicleHistoryPdfService].
///
/// Override-able em testes:
/// ```dart
/// ProviderScope(
///   overrides: [
///     vehicleHistoryPdfServiceProvider
///         .overrideWithValue(MockVehicleHistoryPdfService()),
///   ],
///   child: MyApp(),
/// )
/// ```
final vehicleHistoryPdfServiceProvider =
    Provider<VehicleHistoryPdfService>((ref) {
  return const RealVehicleHistoryPdfService();
});
