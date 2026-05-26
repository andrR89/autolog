import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.8 — validação bloqueante de odômetro (substitui 3.7).
/// Spec: docs/specs/sprint-3.8-blocking-validation.md
void main() {
  FuelEntry entry({
    required String id,
    required DateTime date,
    required int odometer,
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse('40'),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse('200'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('validateOdometerForEntry', () {
    test(
      'odômetro abaixo do inicial do veículo: bloqueia com mensagem PT-BR',
      () {
        final result = validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 23),
          odometer: 1200,
          initialOdometer: 1500,
          existing: const [],
        );
        expect(result, isNotNull);
        expect(result!.toLowerCase(), contains('inicial'));
        expect(result, contains('1500'));
      },
    );

    test('odômetro igual ao inicial, sem existing: ok', () {
      expect(
        validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 23),
          odometer: 1500,
          initialOdometer: 1500,
          existing: const [],
        ),
        isNull,
      );
    });

    test('odômetro acima do inicial, sem existing: ok', () {
      expect(
        validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 23),
          odometer: 1800,
          initialOdometer: 1500,
          existing: const [],
        ),
        isNull,
      );
    });

    test('anterior em data com odômetro MAIOR: bloqueia "anterior"', () {
      final existing = [
        entry(id: 'e1', date: DateTime.utc(2026, 5, 20), odometer: 46000),
      ];
      final result = validateOdometerForEntry(
        date: DateTime.utc(2026, 5, 22),
        odometer: 45000,
        initialOdometer: 1000,
        existing: existing,
      );
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('anterior'));
      expect(result, contains('46000'));
    });

    test('posterior em data com odômetro MENOR: bloqueia "posterior"', () {
      final existing = [
        entry(id: 'e1', date: DateTime.utc(2026, 5, 22), odometer: 46000),
      ];
      final result = validateOdometerForEntry(
        date: DateTime.utc(2026, 5, 20),
        odometer: 47000,
        initialOdometer: 1000,
        existing: existing,
      );
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('posterior'));
      expect(result, contains('46000'));
    });

    test('novo no meio cabe entre anterior e posterior: ok', () {
      final existing = [
        entry(id: 'e1', date: DateTime.utc(2026, 5, 20), odometer: 45000),
        entry(id: 'e2', date: DateTime.utc(2026, 5, 22), odometer: 46000),
      ];
      expect(
        validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 21),
          odometer: 45500,
          initialOdometer: 1000,
          existing: existing,
        ),
        isNull,
      );
    });

    test(
      'novo no meio com odômetro acima do posterior: bloqueia "posterior"',
      () {
        final existing = [
          entry(id: 'e1', date: DateTime.utc(2026, 5, 20), odometer: 45000),
          entry(id: 'e2', date: DateTime.utc(2026, 5, 22), odometer: 46000),
        ];
        final result = validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 21),
          odometer: 50000,
          initialOdometer: 1000,
          existing: existing,
        );
        expect(result, isNotNull);
        expect(result!.toLowerCase(), contains('posterior'));
        expect(result, contains('46000'));
      },
    );

    test(
      'novo no meio com odômetro abaixo do anterior: bloqueia "anterior"',
      () {
        final existing = [
          entry(id: 'e1', date: DateTime.utc(2026, 5, 20), odometer: 45000),
          entry(id: 'e2', date: DateTime.utc(2026, 5, 22), odometer: 46000),
        ];
        final result = validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 21),
          odometer: 44000,
          initialOdometer: 1000,
          existing: existing,
        );
        expect(result, isNotNull);
        expect(result!.toLowerCase(), contains('anterior'));
        expect(result, contains('45000'));
      },
    );

    test('mesma data, qualquer odômetro >= inicial: ok (sem check entre '
        'mesma-data — não temos hora)', () {
      final existing = [
        entry(id: 'e1', date: DateTime.utc(2026, 5, 22), odometer: 45000),
      ];
      // Mesmo dia, odômetro menor que o outro entry: permitido.
      expect(
        validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 22),
          odometer: 40000,
          initialOdometer: 1000,
          existing: existing,
        ),
        isNull,
      );
      // Mesmo dia, odômetro maior: também ok.
      expect(
        validateOdometerForEntry(
          date: DateTime.utc(2026, 5, 22),
          odometer: 50000,
          initialOdometer: 1000,
          existing: existing,
        ),
        isNull,
      );
    });

    test('edit mode: excludeId ignora a própria entry da comparação', () {
      // Cenário: edit-me existia em (22/05, 46000). Estamos editando-a pra
      // (24/05, 40000). Sem excludeId, a própria edit-me apareceria como
      // "anterior" (46000 > 40000) e bloquearia. Com excludeId, ignora.
      final existing = [
        entry(id: 'edit-me', date: DateTime.utc(2026, 5, 22), odometer: 46000),
      ];

      // Sanity check: sem excludeId, bloqueia.
      final blocked = validateOdometerForEntry(
        date: DateTime.utc(2026, 5, 24),
        odometer: 40000,
        initialOdometer: 1000,
        existing: existing,
      );
      expect(blocked, isNotNull);

      // Com excludeId: ignora a própria edit-me → ok.
      final allowed = validateOdometerForEntry(
        date: DateTime.utc(2026, 5, 24),
        odometer: 40000,
        initialOdometer: 1000,
        existing: existing,
        excludeId: 'edit-me',
      );
      expect(allowed, isNull);
    });

    test('inicial não é o pior quando existe anterior mais restritivo: '
        'mensagem prioriza o anterior', () {
      // initial=1500. Existing tem entry anterior com odometer 2000.
      // Novo (22/05, 1800): >= 1500 (passa inicial). Mas anterior 2000 > 1800 → bloqueia "anterior".
      final existing = [
        entry(id: 'e1', date: DateTime.utc(2026, 5, 20), odometer: 2000),
      ];
      final result = validateOdometerForEntry(
        date: DateTime.utc(2026, 5, 22),
        odometer: 1800,
        initialOdometer: 1500,
        existing: existing,
      );
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('anterior'));
      expect(result, contains('2000'));
    });
  });
}
