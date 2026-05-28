// Testes para HomeWidgetService (Sprint 6.BB).
//
// Não testa o real HomeWidget package (depende de bindings nativos).
// Foco: MockHomeWidgetService call count, helper formatReminderDue.

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/home_widget/home_widget_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Helper: data base pra comparações
  // -------------------------------------------------------------------------

  final now = DateTime(2026, 5, 27, 10, 0, 0);

  Reminder makeReminder({DateTime? dueDate, int? dueKm}) {
    return Reminder(
      id: 'r1',
      vehicleId: 'v1',
      type: ReminderType.porData,
      title: 'Revisão',
      dueDate: dueDate,
      dueKm: dueKm,
      isDone: false,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    );
  }

  // -------------------------------------------------------------------------
  // Grupo 1: MockHomeWidgetService — call count e userId capturado
  // -------------------------------------------------------------------------

  group('MockHomeWidgetService', () {
    late AppDatabase db;
    late MockHomeWidgetService svc;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      svc = MockHomeWidgetService();
    });

    tearDown(() => db.close());

    test('refresh incrementa call count', () async {
      await svc.refresh(db: db, userId: 'user-1');
      expect(svc.refreshCallCount, 1);
    });

    test('refresh múltiplo acumula call count', () async {
      await svc.refresh(db: db, userId: 'user-1');
      await svc.refresh(db: db, userId: 'user-2');
      await svc.refresh(db: db, userId: 'user-1');
      expect(svc.refreshCallCount, 3);
    });

    test('refresh captura userId', () async {
      await svc.refresh(db: db, userId: 'user-xyz');
      expect(svc.lastUserId, 'user-xyz');
    });

    test('refresh com userId null ainda registra chamada', () async {
      await svc.refresh(db: db, userId: null);
      expect(svc.refreshCallCount, 1);
      expect(svc.lastUserId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Grupo 2: formatReminderDue — casos de data PT-BR
  // -------------------------------------------------------------------------

  group('formatReminderDue', () {
    test('retorna "Hoje" para data de hoje', () {
      final reminder = makeReminder(dueDate: DateTime(2026, 5, 27, 14, 0));
      expect(formatReminderDue(reminder, now), 'Hoje');
    });

    test('retorna "Amanhã" para data de amanhã', () {
      final reminder = makeReminder(dueDate: DateTime(2026, 5, 28, 8, 0));
      expect(formatReminderDue(reminder, now), 'Amanhã');
    });

    test('retorna "Ontem" para data de ontem', () {
      final reminder = makeReminder(dueDate: DateTime(2026, 5, 26, 8, 0));
      expect(formatReminderDue(reminder, now), 'Ontem');
    });

    test('retorna DD/MM para datas no mesmo ano', () {
      final reminder = makeReminder(dueDate: DateTime(2026, 7, 15));
      expect(formatReminderDue(reminder, now), '15/07');
    });

    test('retorna DD/MM/AAAA para datas em ano diferente', () {
      final reminder = makeReminder(dueDate: DateTime(2027, 3, 10));
      expect(formatReminderDue(reminder, now), '10/03/2027');
    });

    test('retorna "Vencimento por km" quando só tem dueKm', () {
      final reminder = makeReminder(dueKm: 150000);
      expect(formatReminderDue(reminder, now), 'Vencimento por km');
    });

    test('retorna string vazia quando sem data e sem km', () {
      final reminder = makeReminder();
      expect(formatReminderDue(reminder, now), '');
    });
  });
}
