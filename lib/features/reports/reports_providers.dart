import 'package:autolog/features/expenses/expenses_list_screen.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/reports/monthly_consumption.dart';
import 'package:autolog/features/reports/monthly_price.dart';
import 'package:autolog/features/reports/monthly_spending.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider de gasto total (combustível + despesas) por mês para um veículo.
///
/// Combina [fuelEntriesByVehicleProvider] e [expensesByVehicleProvider],
/// propagando loading/error de qualquer um dos dois streams.
/// Retorna [AsyncValue] para que a UI possa tratar cada estado.
final monthlySpendingProvider =
    Provider.family<AsyncValue<List<MonthlyTotal>>, String>((ref, vehicleId) {
      final fuel = ref.watch(fuelEntriesByVehicleProvider(vehicleId));
      final exp = ref.watch(expensesByVehicleProvider(vehicleId));

      if (fuel.isLoading || exp.isLoading) return const AsyncValue.loading();
      if (fuel.hasError) {
        return AsyncValue.error(
          fuel.error!,
          fuel.stackTrace ?? StackTrace.empty,
        );
      }
      if (exp.hasError) {
        return AsyncValue.error(exp.error!, exp.stackTrace ?? StackTrace.empty);
      }

      return AsyncValue.data(
        computeMonthlySpending(fuelEntries: fuel.value!, expenses: exp.value!),
      );
    });

/// Provider de consumo médio (km/l ponderado por km) por mês para um veículo.
///
/// Inverte a lista DESC do repositório para ASC antes de passar para
/// [computeMonthlyConsumption], que exige ordem cronológica.
final monthlyConsumptionProvider =
    Provider.family<AsyncValue<List<MonthlyConsumption>>, String>((
      ref,
      vehicleId,
    ) {
      final fuel = ref.watch(fuelEntriesByVehicleProvider(vehicleId));

      if (fuel.isLoading) return const AsyncValue.loading();
      if (fuel.hasError) {
        return AsyncValue.error(
          fuel.error!,
          fuel.stackTrace ?? StackTrace.empty,
        );
      }

      // O repositório retorna DESC; a função espera ASC.
      final entriesAsc = fuel.value!.reversed.toList();
      return AsyncValue.data(computeMonthlyConsumption(entriesAsc));
    });

/// Provider de preço médio por litro (ponderado por litros) por mês.
///
/// Inverte a lista DESC do repositório para ASC antes de passar para
/// [computeMonthlyPrice].
final monthlyPriceProvider =
    Provider.family<AsyncValue<List<MonthlyPrice>>, String>((ref, vehicleId) {
      final fuel = ref.watch(fuelEntriesByVehicleProvider(vehicleId));

      if (fuel.isLoading) return const AsyncValue.loading();
      if (fuel.hasError) {
        return AsyncValue.error(
          fuel.error!,
          fuel.stackTrace ?? StackTrace.empty,
        );
      }

      // O repositório retorna DESC; a função espera ASC para agrupamento correto.
      final entriesAsc = fuel.value!.reversed.toList();
      return AsyncValue.data(computeMonthlyPrice(entriesAsc));
    });
