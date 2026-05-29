import 'package:autolog/features/expenses/expenses_list_screen.dart'
    show expensesByVehicleProvider;
import 'package:autolog/features/fuel/fuel_history_screen.dart'
    show fuelEntriesByVehicleProvider;
import 'package:autolog/features/reports/compare/period_compare_calculator.dart';
import 'package:autolog/features/reports/compare/period_compare_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Tipos públicos de modo e args
// ---------------------------------------------------------------------------

enum PeriodCompareMode { month, year, custom }

/// Parâmetros do provider: vehicleId + modo + ranges (from/to do período atual
/// e anterior). Para modos [month] e [year] os ranges são calculados
/// automaticamente se não fornecidos.
class PeriodCompareArgs {
  const PeriodCompareArgs({
    required this.vehicleId,
    this.mode = PeriodCompareMode.month,
    DateTime? currentFrom,
    DateTime? currentTo,
    DateTime? previousFrom,
    DateTime? previousTo,
    DateTime? now,
  }) : _currentFrom = currentFrom,
       _currentTo = currentTo,
       _previousFrom = previousFrom,
       _previousTo = previousTo,
       _now = now;

  final String vehicleId;
  final PeriodCompareMode mode;

  // Ranges explícitos (usado em [custom] e em testes).
  final DateTime? _currentFrom;
  final DateTime? _currentTo;
  final DateTime? _previousFrom;
  final DateTime? _previousTo;
  final DateTime? _now;

  /// Resolve os ranges levando em conta o modo.
  ({
    DateTime currentFrom,
    DateTime currentTo,
    DateTime previousFrom,
    DateTime previousTo,
  })
  resolvedRanges() {
    final now = _now ?? DateTime.now();

    switch (mode) {
      case PeriodCompareMode.month:
        final r = defaultMonthRange(now);
        return (
          currentFrom: r.$1.$1,
          currentTo: r.$1.$2,
          previousFrom: r.$2.$1,
          previousTo: r.$2.$2,
        );

      case PeriodCompareMode.year:
        final r = defaultYearRange(now);
        return (
          currentFrom: r.$1.$1,
          currentTo: r.$1.$2,
          previousFrom: r.$2.$1,
          previousTo: r.$2.$2,
        );

      case PeriodCompareMode.custom:
        assert(
          _currentFrom != null &&
              _currentTo != null &&
              _previousFrom != null &&
              _previousTo != null,
          'Ranges explícitos são obrigatórios em modo custom.',
        );
        return (
          currentFrom: _currentFrom!,
          currentTo: _currentTo!,
          previousFrom: _previousFrom!,
          previousTo: _previousTo!,
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodCompareArgs &&
          other.vehicleId == vehicleId &&
          other.mode == mode &&
          other._currentFrom == _currentFrom &&
          other._currentTo == _currentTo &&
          other._previousFrom == _previousFrom &&
          other._previousTo == _previousTo;

  @override
  int get hashCode => Object.hash(
    vehicleId,
    mode,
    _currentFrom,
    _currentTo,
    _previousFrom,
    _previousTo,
  );
}

// ---------------------------------------------------------------------------
// Provider principal
// ---------------------------------------------------------------------------

/// Provider que combina fuel entries + expenses e computa [PeriodCompareData].
///
/// Retorna [AsyncValue] para tratar loading/error nos dois streams.
final periodCompareProvider =
    Provider.family<AsyncValue<PeriodCompareData>, PeriodCompareArgs>((
      ref,
      args,
    ) {
      final fuelAsync = ref.watch(fuelEntriesByVehicleProvider(args.vehicleId));
      final expAsync = ref.watch(expensesByVehicleProvider(args.vehicleId));

      if (fuelAsync.isLoading || expAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (fuelAsync.hasError) {
        return AsyncValue.error(
          fuelAsync.error!,
          fuelAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (expAsync.hasError) {
        return AsyncValue.error(
          expAsync.error!,
          expAsync.stackTrace ?? StackTrace.empty,
        );
      }

      final ranges = args.resolvedRanges();

      return AsyncValue.data(
        computePeriodCompare(
          entries: fuelAsync.value!,
          expenses: expAsync.value!,
          currentFrom: ranges.currentFrom,
          currentTo: ranges.currentTo,
          previousFrom: ranges.previousFrom,
          previousTo: ranges.previousTo,
        ),
      );
    });
