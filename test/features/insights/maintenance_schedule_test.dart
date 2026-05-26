import 'package:autolog/features/insights/maintenance_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.M — parse defensivo do MaintenanceSchedule.
/// Spec: docs/specs/sprint-6.M-maintenance-suggestions.md
void main() {
  group('MaintenanceSchedule.fromJson', () {
    test('JSON completo com vários itens', () {
      final r = MaintenanceSchedule.fromJson({
        'items': [
          {
            'task': 'Troca de óleo',
            'cadence_type': 'km_or_months',
            'every_km': 10000,
            'every_months': 12,
            'notes': 'Use óleo sintético 5W30.',
          },
          {
            'task': 'Filtro de ar',
            'cadence_type': 'km',
            'every_km': 20000,
            'every_months': null,
          },
        ],
      });
      expect(r.items.length, 2);
      expect(r.items.first.task, 'Troca de óleo');
      expect(r.items.first.cadenceType, 'km_or_months');
      expect(r.items.first.everyKm, 10000);
      expect(r.items.first.everyMonths, 12);
      expect(r.items[1].cadenceType, 'km');
      expect(r.items[1].everyMonths, isNull);
    });

    test('items vazio → schedule vazio', () {
      final r = MaintenanceSchedule.fromJson({'items': <dynamic>[]});
      expect(r.items, isEmpty);
    });

    test('JSON sem chave items → falha (campo required)', () {
      expect(() => MaintenanceSchedule.fromJson(<String, dynamic>{}),
          throwsA(isA<Object>()));
    });

    test('chaves extras ignoradas', () {
      final r = MaintenanceSchedule.fromJson({
        'items': <dynamic>[],
        'foo': 'bar',
      });
      expect(r.items, isEmpty);
    });

    test('item com campos opcionais ausentes', () {
      final r = MaintenanceSchedule.fromJson({
        'items': [
          {'task': 'Trocar velas', 'cadence_type': 'km'},
        ],
      });
      expect(r.items.first.task, 'Trocar velas');
      expect(r.items.first.everyKm, isNull);
      expect(r.items.first.notes, isNull);
    });

    test('roundtrip toJson/fromJson', () {
      const original = MaintenanceSchedule(items: [
        MaintenanceItem(
          task: 'Correia dentada',
          cadenceType: 'km',
          everyKm: 60000,
          notes: 'Verificar tensor junto.',
        ),
      ]);
      final back = MaintenanceSchedule.fromJson(original.toJson());
      expect(back, original);
    });
  });

  group('MaintenanceItem cadências', () {
    test('km only', () {
      final r = MaintenanceItem.fromJson({
        'task': 'X', 'cadence_type': 'km', 'every_km': 5000,
      });
      expect(r.cadenceType, 'km');
      expect(r.everyKm, 5000);
      expect(r.everyMonths, isNull);
    });

    test('months only', () {
      final r = MaintenanceItem.fromJson({
        'task': 'X', 'cadence_type': 'months', 'every_months': 6,
      });
      expect(r.cadenceType, 'months');
      expect(r.everyMonths, 6);
      expect(r.everyKm, isNull);
    });

    test('km_or_months', () {
      final r = MaintenanceItem.fromJson({
        'task': 'X', 'cadence_type': 'km_or_months',
        'every_km': 10000, 'every_months': 12,
      });
      expect(r.cadenceType, 'km_or_months');
      expect(r.everyKm, 10000);
      expect(r.everyMonths, 12);
    });
  });
}
