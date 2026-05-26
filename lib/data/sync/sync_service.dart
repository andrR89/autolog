import 'package:autolog/data/sync/expense_sync_service.dart';
import 'package:autolog/data/sync/fine_sync_service.dart';
import 'package:autolog/data/sync/fuel_entry_sync_service.dart';
import 'package:autolog/data/sync/insurance_sync_service.dart';
import 'package:autolog/data/sync/reminder_sync_service.dart';
import 'package:autolog/data/sync/user_profile_sync_service.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// GlobalSyncResult
// ---------------------------------------------------------------------------

/// Resultado agregado de [GlobalSyncService.sync], cobrindo todas as entidades.
class GlobalSyncResult {
  const GlobalSyncResult({
    required this.totalPushed,
    required this.totalPulled,
    required this.totalPushFailures,
    required this.errors,
  });

  /// Total de rows enviados ao remoto com sucesso (soma das 4 entidades).
  final int totalPushed;

  /// Total de rows aplicados do remoto localmente (soma das 4 entidades).
  final int totalPulled;

  /// Total de push failures (soma das 4 entidades).
  final int totalPushFailures;

  /// Erros por entidade: exceção lançada pelo service OU pullError não-null.
  /// Chaves canônicas: 'vehicles', 'user_profile', 'fuel', 'expenses',
  /// 'reminders', 'fines', 'insurances'.
  final Map<String, Object> errors;

  /// True se houve qualquer push failure ou erro de entidade.
  bool get hasFailures => totalPushFailures > 0 || errors.isNotEmpty;
}

// ---------------------------------------------------------------------------
// GlobalSyncService
// ---------------------------------------------------------------------------

/// Orquestra a sincronização de todas as entidades do AutoLog.
///
/// Ordem de execução: **vehicles → user_profile → fuel → expenses → reminders
/// → fines → insurances** (serial, 7 etapas).
/// Vehicles primeiro porque os outros fazem innerJoin(vehicles) na façade
/// pra resolver o user_id; se um vehicle remoto novo não foi puxado, suas
/// entries filhas ficam invisíveis.
///
/// Exceção num service NÃO interrompe os outros — é capturada e colocada
/// em [GlobalSyncResult.errors] com a chave canônica da entidade.
/// [SyncResult.pullError] não-null também vira entrada em errors.
class GlobalSyncService {
  GlobalSyncService({
    required VehicleSyncService vehicle,
    required UserProfileSyncService userProfile,
    required FuelEntrySyncService fuel,
    required ExpenseSyncService expense,
    required ReminderSyncService reminder,
    required FineSyncService fine,
    required InsuranceSyncService insurance,
  }) : _vehicle = vehicle,
       _userProfile = userProfile,
       _fuel = fuel,
       _expense = expense,
       _reminder = reminder,
       _fine = fine,
       _insurance = insurance;

  final VehicleSyncService _vehicle;
  final UserProfileSyncService _userProfile;
  final FuelEntrySyncService _fuel;
  final ExpenseSyncService _expense;
  final ReminderSyncService _reminder;
  final FineSyncService _fine;
  final InsuranceSyncService _insurance;

  /// Executa vehicles → user_profile → fuel → expenses → reminders → fines
  /// → insurances para o [userId].
  ///
  /// Nunca lança — falhas ficam em [GlobalSyncResult.errors].
  Future<GlobalSyncResult> sync(String userId) async {
    int totalPushed = 0;
    int totalPulled = 0;
    int totalPushFailures = 0;
    final errors = <String, Object>{};

    // 1. Vehicles (primeiro — FK para as demais entidades).
    await _runOne(
      key: 'vehicles',
      call: () => _vehicle.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 2. User profile (PK = userId, sem JOIN).
    await _runOne(
      key: 'user_profile',
      call: () => _userProfile.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 3. Fuel entries.
    await _runOne(
      key: 'fuel',
      call: () => _fuel.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 4. Expenses.
    await _runOne(
      key: 'expenses',
      call: () => _expense.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 5. Reminders.
    await _runOne(
      key: 'reminders',
      call: () => _reminder.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 6. Fines.
    await _runOne(
      key: 'fines',
      call: () => _fine.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    // 7. Insurances.
    await _runOne(
      key: 'insurances',
      call: () => _insurance.sync(userId),
      onResult: (r) {
        totalPushed += r.pushed;
        totalPulled += r.pulled;
        totalPushFailures += r.pushFailures;
      },
      errors: errors,
    );

    return GlobalSyncResult(
      totalPushed: totalPushed,
      totalPulled: totalPulled,
      totalPushFailures: totalPushFailures,
      errors: errors,
    );
  }

  /// Executa um service individual, capturando exceções e pullErrors.
  Future<void> _runOne({
    required String key,
    required Future<SyncResult> Function() call,
    required void Function(SyncResult) onResult,
    required Map<String, Object> errors,
  }) async {
    try {
      final result = await call();
      onResult(result);
      // pullError não-null também vira entrada em errors.
      if (result.pullError != null) {
        errors[key] = result.pullError!;
      }
    } catch (e) {
      errors[key] = e;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final globalSyncServiceProvider = Provider<GlobalSyncService>((ref) {
  return GlobalSyncService(
    vehicle: ref.watch(vehicleSyncServiceProvider),
    userProfile: ref.watch(userProfileSyncServiceProvider),
    fuel: ref.watch(fuelEntrySyncServiceProvider),
    expense: ref.watch(expenseSyncServiceProvider),
    reminder: ref.watch(reminderSyncServiceProvider),
    fine: ref.watch(fineSyncServiceProvider),
    insurance: ref.watch(insuranceSyncServiceProvider),
  );
});
