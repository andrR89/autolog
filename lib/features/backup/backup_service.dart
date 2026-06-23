// Service de backup/restore JSON local.
//
// Estratégia de merge no restore (last-write-wins por updated_at):
//   - Existe local com updated_at >= incoming → skip
//   - Existe local com updated_at <  incoming → update
//   - Não existe local → insert
//
// Por que last-write-wins: o user pode ter restaurado de um backup velho
// num device que ainda continua sendo usado — não queremos sobrescrever
// edits novos. Se o backup é mais novo que o local, vence; senão, vence
// o local (assume-se que o app local tem dado mais fresco).

import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/repositories/expense_repository.dart' as exp;
import 'package:autolog/domain/repositories/fine_repository.dart' as fin;
import 'package:autolog/domain/repositories/fuel_entry_repository.dart' as fe;
import 'package:autolog/domain/repositories/insurance_repository.dart' as ins;
import 'package:autolog/domain/repositories/reminder_repository.dart' as rem;
import 'package:autolog/domain/repositories/user_profile_repository.dart'
    as up;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as veh;
import 'package:autolog/features/backup/backup_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupService {
  BackupService({
    required veh.VehicleRepository vehicles,
    required fe.FuelEntryRepository fuel,
    required exp.ExpenseRepository expenses,
    required rem.ReminderRepository reminders,
    required fin.FineRepository fines,
    required ins.InsuranceRepository insurances,
    required up.UserProfileRepository userProfile,
    required String appVersion,
  })  : _vehicles = vehicles,
        _fuel = fuel,
        _expenses = expenses,
        _reminders = reminders,
        _fines = fines,
        _insurances = insurances,
        _userProfile = userProfile,
        _appVersion = appVersion;

  final veh.VehicleRepository _vehicles;
  final fe.FuelEntryRepository _fuel;
  final exp.ExpenseRepository _expenses;
  final rem.ReminderRepository _reminders;
  final fin.FineRepository _fines;
  final ins.InsuranceRepository _insurances;
  final up.UserProfileRepository _userProfile;
  final String _appVersion;

  /// Coleta tudo do user atual e devolve um [BackupBundle].
  Future<BackupBundle> exportAll(String userId) async {
    final vehicles = await _vehicles.listByUser(userId);
    final profile = await _userProfile.getById(userId);

    final fuelEntries = <Object>[];
    final expenses = <Object>[];
    final reminders = <Object>[];
    final fines = <Object>[];
    final insurances = <Object>[];

    for (final v in vehicles) {
      fuelEntries.addAll(await _fuel.listByVehicle(v.id));
      expenses.addAll(await _expenses.listByVehicle(v.id));
      reminders.addAll(await _reminders.listByVehicle(v.id));
      fines.addAll(await _fines.listByVehicle(v.id));
      insurances.addAll(await _insurances.listByVehicle(v.id));
    }

    return BackupBundle(
      version: kBackupSchemaVersion,
      exportedAt: DateTime.now().toUtc(),
      appVersion: _appVersion,
      userId: userId,
      vehicles: vehicles,
      fuelEntries: fuelEntries.cast(),
      expenses: expenses.cast(),
      reminders: reminders.cast(),
      fines: fines.cast(),
      insurances: insurances.cast(),
      userProfile: profile,
    );
  }

  /// Aplica o [bundle] no DB local. Faz merge por id + updated_at.
  /// Retorna estatísticas pra mostrar pro user.
  Future<RestoreStats> importBundle(BackupBundle bundle) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    // 1. Vehicles primeiro — fuel_entries/expenses/etc dependem deles.
    for (final v in bundle.vehicles) {
      final existing = await _vehicles.getById(v.id);
      if (existing == null) {
        await _vehicles.create(v);
        inserted++;
      } else if (v.updatedAt.isAfter(existing.updatedAt)) {
        await _vehicles.update(v);
        updated++;
      } else {
        skipped++;
      }
    }

    // 2. User profile (singleton por user).
    if (bundle.userProfile != null) {
      final existing = await _userProfile.getById(bundle.userProfile!.userId);
      if (existing == null) {
        await _userProfile.update(bundle.userProfile!);
        inserted++;
      } else if (bundle.userProfile!.updatedAt.isAfter(existing.updatedAt)) {
        await _userProfile.update(bundle.userProfile!);
        updated++;
      } else {
        skipped++;
      }
    }

    // 3. Demais entidades — todas seguem o mesmo padrão get/create/update.
    for (final f in bundle.fuelEntries) {
      final existing = await _fuel.getById(f.id);
      if (existing == null) {
        await _fuel.create(f);
        inserted++;
      } else if (f.updatedAt.isAfter(existing.updatedAt)) {
        await _fuel.update(f);
        updated++;
      } else {
        skipped++;
      }
    }

    for (final e in bundle.expenses) {
      final existing = await _expenses.getById(e.id);
      if (existing == null) {
        await _expenses.create(e);
        inserted++;
      } else if (e.updatedAt.isAfter(existing.updatedAt)) {
        await _expenses.update(e);
        updated++;
      } else {
        skipped++;
      }
    }

    for (final r in bundle.reminders) {
      final existing = await _reminders.getById(r.id);
      if (existing == null) {
        await _reminders.create(r);
        inserted++;
      } else if (r.updatedAt.isAfter(existing.updatedAt)) {
        await _reminders.update(r);
        updated++;
      } else {
        skipped++;
      }
    }

    for (final f in bundle.fines) {
      final existing = await _fines.getById(f.id);
      if (existing == null) {
        await _fines.create(f);
        inserted++;
      } else if (f.updatedAt.isAfter(existing.updatedAt)) {
        await _fines.update(f);
        updated++;
      } else {
        skipped++;
      }
    }

    for (final i in bundle.insurances) {
      final existing = await _insurances.getById(i.id);
      if (existing == null) {
        await _insurances.create(i);
        inserted++;
      } else if (i.updatedAt.isAfter(existing.updatedAt)) {
        await _insurances.update(i);
        updated++;
      } else {
        skipped++;
      }
    }

    final total = bundle.vehicles.length +
        (bundle.userProfile == null ? 0 : 1) +
        bundle.fuelEntries.length +
        bundle.expenses.length +
        bundle.reminders.length +
        bundle.fines.length +
        bundle.insurances.length;

    return RestoreStats(
      totalIncoming: total,
      toInsert: inserted,
      toUpdate: updated,
      toSkip: skipped,
    );
  }
}

/// Provider que monta o BackupService.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    vehicles: ref.watch(vehicleRepositoryProvider),
    fuel: ref.watch(fuelEntryRepositoryProvider),
    expenses: ref.watch(expenseRepositoryProvider),
    reminders: ref.watch(reminderRepositoryProvider),
    fines: ref.watch(fineRepositoryProvider),
    insurances: ref.watch(insuranceRepositoryProvider),
    userProfile: ref.watch(userProfileRepositoryProvider),
    // app version — chumbado por enquanto. Quando integrar package_info_plus
    // (futuro), trocar pra Future<String> assíncrono.
    appVersion: '1.0.0',
  );
});
