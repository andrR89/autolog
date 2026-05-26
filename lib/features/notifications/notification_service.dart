// Service de notificações locais proativas (Sprint 6.U).
//
// Encapsula `flutter_local_notifications` + persiste cada notificação enviada
// na tabela `notifications_log` (local-only) pra suportar dedupe no evaluator.

import 'package:autolog/data/local/database.dart';
import 'package:autolog/features/notifications/notification_evaluator.dart';
import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ProactiveNotificationService {
  /// Pede permissão (iOS sempre, Android 13+). Retorna `true` se ok ou se
  /// não foi necessário (Android < 13). Nunca lança.
  Future<bool> ensurePermissionGranted();

  /// Mostra notificação imediata + registra em `notifications_log`.
  Future<void> schedule(
    NotificationProposal proposal, {
    required String vehicleId,
  });

  /// Histórico recente (últimos 30 dias) por veículo — usado pelo evaluator
  /// pra fazer dedupe de 7 dias por categoria.
  Future<List<NotificationLogRow>> recentLog(String vehicleId);
}

class RealProactiveNotificationService implements ProactiveNotificationService {
  RealProactiveNotificationService(
    this._plugin,
    this._db, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FlutterLocalNotificationsPlugin _plugin;
  final AppDatabase _db;
  final DateTime Function() _now;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(init);
    _initialized = true;
  }

  @override
  Future<bool> ensurePermissionGranted() async {
    try {
      await _ensureInitialized();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
        alert: true, badge: true, sound: true,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await android?.requestNotificationsPermission();
      return iosGranted ?? androidGranted ?? true;
    } catch (_) {
      // Se o plugin não estiver disponível (testes etc), seguimos silencioso.
      return false;
    }
  }

  @override
  Future<void> schedule(
    NotificationProposal proposal, {
    required String vehicleId,
  }) async {
    final now = _now();
    final id = (now.millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;
    try {
      await _ensureInitialized();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'autolog_proactive',
          'Avisos do AutoLog',
          channelDescription: 'Lembretes sobre veículos e gastos',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(id, proposal.title, proposal.body, details);
    } catch (_) {
      // Falha do plugin (ex: simulator sem entitlement) não bloqueia o log.
    }
    // Sempre registra no log local — isso garante dedupe consistente mesmo
    // em ambientes onde o plugin falhou.
    await _db.into(_db.notificationsLog).insert(
          NotificationsLogCompanion.insert(
            id: 'log_$id',
            vehicleId: vehicleId,
            category: proposal.category,
            sentAt: now,
            title: proposal.title,
            body: proposal.body,
          ),
        );
  }

  @override
  Future<List<NotificationLogRow>> recentLog(String vehicleId) async {
    final cutoff = _now().subtract(const Duration(days: 30));
    final q = _db.select(_db.notificationsLog)
      ..where((t) =>
          t.vehicleId.equals(vehicleId) & t.sentAt.isBiggerThanValue(cutoff));
    return q.get();
  }
}

final notificationPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final notificationServiceProvider =
    Provider<ProactiveNotificationService>((ref) {
  return RealProactiveNotificationService(
    ref.watch(notificationPluginProvider),
    ref.watch(appDatabaseProvider),
  );
});

