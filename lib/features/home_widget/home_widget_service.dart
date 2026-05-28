// Serviço de atualização do widget de tela inicial (Sprint 6.BB).
//
// Padrão: abstract + Real + Mock, idêntico ao ProactiveNotificationService.
// O home_widget package faz a ponte Dart ↔ nativo (iOS WidgetKit / Android
// AppWidget). Erros são silenciosos — o widget é cosmético, nunca crítico.

import 'dart:async';

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Constantes compartilhadas
// ---------------------------------------------------------------------------

const _kAppGroupId = 'group.com.oddcar.autolog';
const _kIosWidgetName = 'AutoLogWidget';
const _kAndroidWidgetName = 'AutoLogWidgetProvider'; // TODO: Android Sprint futura

// ---------------------------------------------------------------------------
// Interface abstrata
// ---------------------------------------------------------------------------

abstract class HomeWidgetService {
  /// Busca o próximo lembrete ativo do usuário e atualiza o widget.
  ///
  /// Fire-and-forget: nunca lança exceção nem bloqueia o caller.
  /// [userId] pode ser null (usuário não autenticado) — neste caso a chamada
  /// é ignorada silenciosamente.
  Future<void> refresh({
    required AppDatabase db,
    required String? userId,
  });
}

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealHomeWidgetService implements HomeWidgetService {
  RealHomeWidgetService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  bool _groupConfigured = false;

  Future<void> _ensureGroupConfigured() async {
    if (_groupConfigured) return;
    await HomeWidget.setAppGroupId(_kAppGroupId);
    _groupConfigured = true;
  }

  @override
  Future<void> refresh({
    required AppDatabase db,
    required String? userId,
  }) async {
    if (userId == null) return;
    try {
      await _ensureGroupConfigured();
      final next = await _findNextReminder(db, userId);
      if (next == null) {
        await HomeWidget.saveWidgetData('headline', 'Tudo em dia');
        await HomeWidget.saveWidgetData('sub', 'Nenhum lembrete pendente');
      } else {
        await HomeWidget.saveWidgetData('headline', next.title);
        await HomeWidget.saveWidgetData('sub', _formatDue(next, _now()));
      }
      await HomeWidget.updateWidget(
        iOSName: _kIosWidgetName,
        androidName: _kAndroidWidgetName,
      );
    } catch (_) {
      // Silencioso — widget é cosmético.
    }
  }

  // Busca o próximo lembrete não-concluído, não-deletado, de todos os
  // veículos do usuário, ordenado por due_date ASC, LIMIT 1.
  // Inclui também lembretes sem due_date mas com due_km (exibe pelo título).
  Future<Reminder?> _findNextReminder(AppDatabase db, String userId) async {
    final now = _now();

    // Primeiro: lembretes com due_date futura — mais urgentes
    final byDate = await (db.select(db.reminders)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.isDone.equals(false) &
                t.dueDate.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
          ..limit(1))
        .get();

    if (byDate.isNotEmpty) {
      return _rowToReminder(byDate.first);
    }

    // Segundo: lembretes por km sem due_date — não têm prazo temporal mas
    // ainda são relevantes
    final byKm = await (db.select(db.reminders)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.isDone.equals(false) &
                t.dueDate.isNull() &
                t.dueKm.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();

    if (byKm.isNotEmpty) {
      return _rowToReminder(byKm.first);
    }

    return null;
  }

  Reminder _rowToReminder(ReminderRow row) {
    // Importa o mapper de domínio diretamente
    return Reminder(
      id: row.id,
      vehicleId: row.vehicleId,
      type: row.type,
      title: row.title,
      dueKm: row.dueKm,
      dueDate: row.dueDate,
      isDone: row.isDone,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: row.syncStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Formatação de data PT-BR
// ---------------------------------------------------------------------------

/// Formata a data de vencimento de um lembrete em PT-BR:
/// - "Hoje" se for no mesmo dia que [now]
/// - "Amanhã" se for no dia seguinte
/// - "DD/MM" para outras datas próximas
/// - "DD/MM/AAAA" se for em outro ano
/// - "por km" se só tem due_km
String formatReminderDue(Reminder reminder, DateTime now) {
  return _formatDue(reminder, now);
}

String _formatDue(Reminder reminder, DateTime now) {
  final dueDate = reminder.dueDate;
  if (dueDate == null) {
    if (reminder.dueKm != null) {
      return 'Vencimento por km';
    }
    return '';
  }

  final local = dueDate.toLocal();
  final nowLocal = now.toLocal();

  final localDay = DateTime(local.year, local.month, local.day);
  final nowDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

  final diff = localDay.difference(nowDay).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';

  if (local.year == nowLocal.year) {
    return DateFormat('dd/MM').format(local);
  }
  return DateFormat('dd/MM/yyyy').format(local);
}

// ---------------------------------------------------------------------------
// Mock para testes
// ---------------------------------------------------------------------------

class MockHomeWidgetService implements HomeWidgetService {
  int refreshCallCount = 0;
  String? lastUserId;

  @override
  Future<void> refresh({
    required AppDatabase db,
    required String? userId,
  }) async {
    refreshCallCount++;
    lastUserId = userId;
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return RealHomeWidgetService();
});
