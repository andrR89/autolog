import 'dart:async';

import 'package:autolog/core/observability/analytics.dart';
import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/features/home_widget/home_widget_service.dart';
import 'package:autolog/features/notifications/notification_orchestrator.dart';
import 'package:autolog/features/reminders/reminder_trigger_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Orquestra criação, edição e exclusão de abastecimentos via [FuelEntryRepository].
///
/// Espelha o padrão de [VehicleSaver] (Sprint 1.3).
/// Recebe o repositório e um gerador de IDs injetáveis para facilitar testes.
/// O parâmetro [triggerService] é opcional: quando null, nenhum disparo de
/// lembrete por km ocorre (comportamento da Sprint 2.3 preservado).
/// O parâmetro [homeWidgetService] é opcional: quando fornecido, dispara
/// refresh do widget de tela inicial após save bem-sucedido (Sprint 6.BB).
class FuelEntrySaver {
  FuelEntrySaver(
    this._repo, {
    required String Function() generateId,
    ReminderTriggerService? triggerService,
    NotificationOrchestrator? notificationOrchestrator,
    HomeWidgetService? homeWidgetService,
    AppDatabase? db,
  }) : _generateId = generateId,
       _triggerService = triggerService,
       _notificationOrchestrator = notificationOrchestrator,
       _homeWidgetService = homeWidgetService,
       _db = db;

  final FuelEntryRepository _repo;
  final String Function() _generateId;
  final ReminderTriggerService? _triggerService;
  final NotificationOrchestrator? _notificationOrchestrator;
  final HomeWidgetService? _homeWidgetService;
  final AppDatabase? _db;

  /// Cria um abastecimento.
  ///
  /// - [source] indica a origem do registro: [FuelSource.manual] (default) ou
  ///   [FuelSource.aiScan] quando o formulário foi pré-preenchido pelo scan.
  /// - [receiptImageUrl] é null (sem upload de cupom no MVP).
  /// - O repositório define timestamps e sync_status.
  /// - [vehicle] é opcional: quando fornecido junto a [triggerService], dispara
  ///   verificação de lembretes por km após o save.
  Future<FuelEntry> create({
    required String vehicleId,
    required DateTime date,
    required int odometer,
    required Decimal liters,
    required Decimal pricePerLiter,
    required Decimal totalCost,
    required bool fullTank,
    required FuelType fuelType,
    FuelSource source = FuelSource.manual,
    Vehicle? vehicle,
    String? stationName,
    String? stationBrand,
  }) async {
    final now = DateTime.now().toUtc();
    final entry = FuelEntry(
      id: _generateId(),
      vehicleId: vehicleId,
      date: date,
      odometer: odometer,
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalCost: totalCost,
      fullTank: fullTank,
      fuelType: fuelType,
      source: source,
      receiptImageUrl: null,
      stationName: stationName,
      stationBrand: stationBrand,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    final saved = await _repo.create(entry);
    if (_triggerService != null && vehicle != null) {
      await _triggerService.onFuelEntryRecorded(vehicle, saved);
    }
    // 6.U: avalia notificação proativa (consumo piorando, CNH/fiscal vencendo).
    // Fire-and-forget — nunca bloqueia nem propaga erro pro caller.
    if (_notificationOrchestrator != null && vehicle != null) {
      unawaited(_notificationOrchestrator.evaluateAndNotify(
        vehicleId, vehicle.userId,
      ));
    }
    // 6.BB: atualiza widget de tela inicial após save bem-sucedido.
    // Fire-and-forget — widget é cosmético, nunca bloqueia.
    if (_homeWidgetService != null && _db != null && vehicle != null) {
      unawaited(_homeWidgetService.refresh(
        db: _db,
        userId: vehicle.userId,
      ));
    }
    await track(AnalyticsEvent.fuelEntryCreated, props: {
      'source': source.wire,
      'fuel_type': fuelType.wire,
      'full_tank': fullTank,
    });
    return saved;
  }

  /// Atualiza um abastecimento existente, preservando campos de identidade.
  ///
  /// Preserva: [FuelEntry.id], [FuelEntry.vehicleId], [FuelEntry.createdAt],
  /// [FuelEntry.source], [FuelEntry.receiptImageUrl].
  /// O repositório bumpa updated_at e sync_status.
  Future<FuelEntry> update(
    FuelEntry existing, {
    required DateTime date,
    required int odometer,
    required Decimal liters,
    required Decimal pricePerLiter,
    required Decimal totalCost,
    required bool fullTank,
    required FuelType fuelType,
    String? stationName,
    String? stationBrand,
  }) {
    final updated = existing.copyWith(
      date: date,
      odometer: odometer,
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalCost: totalCost,
      fullTank: fullTank,
      fuelType: fuelType,
      stationName: stationName,
      stationBrand: stationBrand,
      // Campos preservados explicitamente (copyWith não toca o que não passamos,
      // mas ser explícito documenta a intenção):
      // id, vehicleId, createdAt, source, receiptImageUrl → intocados.
    );
    return _repo.update(updated);
  }

  /// Soft delete via [FuelEntryRepository.softDelete]. Nunca hard delete.
  Future<void> delete(String id) {
    return _repo.softDelete(id);
  }
}

/// Provider Riverpod que expõe o [FuelEntrySaver] configurado para produção.
final fuelEntrySaverProvider = Provider<FuelEntrySaver>((ref) {
  final repo = ref.watch(fuelEntryRepositoryProvider);
  final triggerService = ref.watch(reminderTriggerServiceProvider);
  final notificationOrchestrator = ref.watch(notificationOrchestratorProvider);
  final homeWidgetService = ref.watch(homeWidgetServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return FuelEntrySaver(
    repo,
    generateId: () => const Uuid().v4(),
    triggerService: triggerService,
    notificationOrchestrator: notificationOrchestrator,
    homeWidgetService: homeWidgetService,
    db: db,
  );
});
