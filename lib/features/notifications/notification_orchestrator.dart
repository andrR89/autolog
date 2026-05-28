// Orquestrador de notificações proativas (Sprint 6.U).
//
// Junta os 4 repos necessários, chama o `evaluateNotifications` puro e
// agenda via `ProactiveNotificationService`. Sempre fire-and-forget — nunca
// lança nem bloqueia o caller (UI / saver).

import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart' as fdomain;
import 'package:autolog/domain/repositories/user_profile_repository.dart' as udomain;
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:autolog/features/notifications/notification_evaluator.dart';
import 'package:autolog/features/notifications/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationOrchestrator {
  NotificationOrchestrator({
    required this.fuelRepo,
    required this.profileRepo,
    required this.vehicleRepo,
    required this.notifService,
    required this.userSettingsRepo,
  });

  final fdomain.FuelEntryRepository fuelRepo;
  final udomain.UserProfileRepository profileRepo;
  final vdomain.VehicleRepository vehicleRepo;
  final ProactiveNotificationService notifService;
  final UserSettingsRepository userSettingsRepo;

  /// Roda a análise pra um veículo + user e agenda uma notificação se cabível.
  /// Fire-and-forget: nunca lança, captura todos os erros silenciosamente.
  Future<void> evaluateAndNotify(String vehicleId, String userId) async {
    try {
      final vehicle = await vehicleRepo.getById(vehicleId);
      if (vehicle == null) return;
      final entries = await fuelRepo.listByVehicle(vehicleId);
      final profile = await profileRepo.getById(userId);
      final log = await notifService.recentLog(vehicleId);
      final prefs = await userSettingsRepo.getNotifPrefs(userId);

      final proposal = evaluateNotifications(
        fuelEntries: entries,
        userProfile: profile,
        recentLog: log,
        now: DateTime.now(),
        vehicleId: vehicleId,
        vehicleUf: vehicle.uf,
        vehiclePlate: vehicle.plate,
        preferences: prefs,
      );
      if (proposal != null) {
        await notifService.schedule(proposal, vehicleId: vehicleId);
      }
    } catch (_) {
      // Fire-and-forget — nunca bloqueia o caller.
    }
  }
}

final notificationOrchestratorProvider =
    Provider<NotificationOrchestrator>((ref) {
  return NotificationOrchestrator(
    fuelRepo: ref.watch(fuelEntryRepositoryProvider),
    profileRepo: ref.watch(userProfileRepositoryProvider),
    vehicleRepo: ref.watch(vehicleRepositoryProvider),
    notifService: ref.watch(notificationServiceProvider),
    userSettingsRepo: ref.watch(userSettingsRepositoryProvider),
  );
});
