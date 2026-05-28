import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/notifications/notification_evaluator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.U — detector puro de notificações.
/// Spec: docs/specs/sprint-6.U-proactive-notifications.md

FuelEntry _f({
  required String id,
  required int odometer,
  required String liters,
  required DateTime date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse(liters) * Decimal.parse('5'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

UserProfile _profile({DateTime? cnhExpires}) => UserProfile(
      userId: 'u1',
      cnhExpiresAt: cnhExpires,
      createdAt: DateTime.utc(2026, 1),
      updatedAt: DateTime.utc(2026, 1),
      syncStatus: SyncStatus.synced,
    );

NotificationLogRow _log({
  required String category,
  required DateTime sentAt,
}) =>
    NotificationLogRow(
      id: 'l_${category}_${sentAt.millisecondsSinceEpoch}',
      vehicleId: 'v1',
      category: category,
      sentAt: sentAt,
      title: 'x',
      body: 'y',
    );

void main() {
  final now = DateTime.utc(2026, 5, 26);

  group('evaluateNotifications', () {
    test('sem dados → null', () {
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: null,
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('consumo estável → null', () {
      // 2 janelas com consumo praticamente igual
      final r = evaluateNotifications(
        fuelEntries: [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 500, liters: '50',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5505, liters: '50',
              date: now.subtract(const Duration(days: 30))),
        ],
        userProfile: null,
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('consumo piorou >10% → proposta consumption_drop', () {
      // Anterior: 12 km/L → atual: 10 km/L (-16%)
      final r = evaluateNotifications(
        fuelEntries: [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50',
              date: now.subtract(const Duration(days: 30))),
        ],
        userProfile: null,
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNotNull);
      expect(r!.category, 'consumption_drop');
    });

    test('CNH vence em 20 dias → proposta cnh', () {
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: _profile(cnhExpires: now.add(const Duration(days: 20))),
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNotNull);
      expect(r!.category, 'cnh');
    });

    test('CNH vence em 5 dias → null (passou da janela 7-30)', () {
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: _profile(cnhExpires: now.add(const Duration(days: 5))),
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('CNH vence em 60 dias → null (fora da janela)', () {
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: _profile(cnhExpires: now.add(const Duration(days: 60))),
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('IPVA vence em 20 dias → proposta fiscal', () {
      // UF SP, placa final 4 → IPVA fev (mês 2). Pra forçar 20 dias da now:
      // chutar combinação que dê resultado dentro da janela. Mais simples:
      // criar a partir de `now` = jan/2026 (próximo IPVA SP em mar/2026 final 4 = mês 2).
      // Estratégia simples: testar com qualquer plate+uf que coloque o vencimento
      // dentro da janela. Aqui vou usar uf 'SP' + plate 'ABC1234' → mês 2 (fev).
      // Pra now=26/05/2026, IPVA do ano fica 26/02/2026 (passado!), próximo é
      // 26/02/2027 — fora da janela. Então usamos current year + 1.
      // O evaluator deve usar `year = now.year` ou `year = next` se o do current
      // já passou.
      // Pra simplificar este teste, mockamos uma situação com UF e plate que
      // garante o dueDate dentro da janela. Usando UF 'XX' (default) +
      // plate '0' → fiscal default mês para final 0. Vou ajustar a estratégia:
      // o evaluator escolhe o próximo dueDate futuro mais próximo dentre IPVA
      // e Licenciamento; se cair em 7-30 dias, notifica.

      // Configuração: now = 2026-05-26. Ipiva default p/ último dígito 5 = mês 3
      // (default {0:1,1:1,2:2,3:2,4:3,5:3,...}). 2026-03 já passou. Próximo
      // dueDate cai em 2027-03 — fora da janela.
      // Pra forçar dentro da janela, escolho plate '0' (mês 1 default), now =
      // 2025-12-13 → IPVA 2026-01-01 fica 19 dias. Vou ajustar o `now`.

      final nowLocal = DateTime.utc(2025, 12, 13);
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: null,
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: 'XX',  // usa default calendar
        vehiclePlate: 'ABC1230', // final 0 → mês 1 default
      );
      expect(r, isNotNull);
      expect(r!.category, 'fiscal');
    });

    test('prioriza fiscal > cnh > consumo', () {
      final nowLocal = DateTime.utc(2025, 12, 13);
      final r = evaluateNotifications(
        // Consumo piorou (presente)
        fuelEntries: [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: nowLocal.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50',
              date: nowLocal.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: nowLocal.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50',
              date: nowLocal.subtract(const Duration(days: 30))),
        ],
        // CNH urgente
        userProfile: _profile(cnhExpires: nowLocal.add(const Duration(days: 20))),
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        // Fiscal urgente
        vehicleUf: 'XX',
        vehiclePlate: 'ABC1230',
      );
      expect(r, isNotNull);
      expect(r!.category, 'fiscal');
    });

    test('já notificou consumption_drop há 3 dias → null (dedupe 7d)', () {
      final r = evaluateNotifications(
        fuelEntries: [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50',
              date: now.subtract(const Duration(days: 30))),
        ],
        userProfile: null,
        recentLog: [
          _log(category: 'consumption_drop',
              sentAt: now.subtract(const Duration(days: 3))),
        ],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('recap_ready: dia 2 do mês com 4 entries no anterior → proposta', () {
      final nowLocal = DateTime.utc(2026, 6, 2);
      final r = evaluateNotifications(
        fuelEntries: [
          for (var d = 1; d <= 4; d++)
            _f(id: 'e$d', odometer: 100 + d * 100, liters: '40',
                date: DateTime.utc(2026, 5, 5 + d)),
        ],
        userProfile: null,
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNotNull);
      expect(r!.category, 'recap_ready');
      expect(r.title.toLowerCase().contains('maio'), isTrue);
    });

    test('recap_ready: dia 5 do mês já fora da janela → null', () {
      final nowLocal = DateTime.utc(2026, 6, 5);
      final r = evaluateNotifications(
        fuelEntries: [
          for (var d = 1; d <= 4; d++)
            _f(id: 'e$d', odometer: 100 + d * 100, liters: '40',
                date: DateTime.utc(2026, 5, 5 + d)),
        ],
        userProfile: null,
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('recap_ready: dia 2 mas só 2 entries no anterior → null', () {
      final nowLocal = DateTime.utc(2026, 6, 2);
      final r = evaluateNotifications(
        fuelEntries: [
          _f(id: 'e1', odometer: 100, liters: '40',
              date: DateTime.utc(2026, 5, 10)),
          _f(id: 'e2', odometer: 200, liters: '40',
              date: DateTime.utc(2026, 5, 20)),
        ],
        userProfile: null,
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNull);
    });

    test('já notificou há 8 dias → renotifica', () {
      final r = evaluateNotifications(
        fuelEntries: [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50',
              date: now.subtract(const Duration(days: 30))),
        ],
        userProfile: null,
        recentLog: [
          _log(category: 'consumption_drop',
              sentAt: now.subtract(const Duration(days: 8))),
        ],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
      );
      expect(r, isNotNull);
      expect(r!.category, 'consumption_drop');
    });
  });

  group('prefs filtram categorias', () {
    // Entradas com consumo piorando >10% (usado em vários testes abaixo).
    List<FuelEntry> consumptionDropEntries() => [
          _f(id: 'p1', odometer: 0, liters: '50',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50',
              date: now.subtract(const Duration(days: 30))),
        ];

    test('consumption_drop desligada → consumo piora mas não notifica', () {
      const prefs = NotificationPreferences(consumptionDrop: false);
      final r = evaluateNotifications(
        fuelEntries: consumptionDropEntries(),
        userProfile: null,
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
        preferences: prefs,
      );
      expect(r, isNull);
    });

    test('cnh desligada → CNH vence em 20 dias mas não notifica', () {
      const prefs = NotificationPreferences(cnh: false);
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: _profile(cnhExpires: now.add(const Duration(days: 20))),
        recentLog: const [],
        now: now,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
        preferences: prefs,
      );
      expect(r, isNull);
    });

    test('fiscal desligada → fiscal urgente é pulado, cnh notificada', () {
      // nowLocal onde fiscal seria ativado; CNH também urgente.
      final nowLocal = DateTime.utc(2025, 12, 13);
      const prefs = NotificationPreferences(fiscal: false);
      final r = evaluateNotifications(
        fuelEntries: const [],
        userProfile: _profile(cnhExpires: nowLocal.add(const Duration(days: 20))),
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: 'XX',
        vehiclePlate: 'ABC1230', // final 0 → fiscal acionaria
        preferences: prefs,
      );
      // Fiscal pulado → deve notificar CNH.
      expect(r, isNotNull);
      expect(r!.category, 'cnh');
    });

    test('recap_ready desligada → dia 2 do mês com entries suficientes mas não notifica', () {
      final nowLocal = DateTime.utc(2026, 6, 2);
      const prefs = NotificationPreferences(recapReady: false);
      final r = evaluateNotifications(
        fuelEntries: [
          for (var d = 1; d <= 4; d++)
            _f(id: 'e$d', odometer: 100 + d * 100, liters: '40',
                date: DateTime.utc(2026, 5, 5 + d)),
        ],
        userProfile: null,
        recentLog: const [],
        now: nowLocal,
        vehicleId: 'v1',
        vehicleUf: null,
        vehiclePlate: null,
        preferences: prefs,
      );
      expect(r, isNull);
    });
  });
}
