// lib/features/export/csv_export_providers.dart
//
// Sprint 6.II — Export CSV / Backup.
//
// Provider Riverpod do CsvExportService.
// Por default retorna RealCsvExportService wired com os repos Drift.
// Em testes, faça override com MockCsvExportService via ProviderScope.overrides.

import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/features/export/csv_export_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider principal do [CsvExportService].
///
/// Override-able em testes:
/// ```dart
/// ProviderScope(
///   overrides: [
///     csvExportServiceProvider.overrideWithValue(MockCsvExportService()),
///   ],
///   child: MyApp(),
/// )
/// ```
final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  final fuelRepo = ref.watch(fuelEntryRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return RealCsvExportService(fuelRepo: fuelRepo, expenseRepo: expenseRepo);
});
