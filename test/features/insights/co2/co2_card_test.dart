// Testes de widget para Co2InsightCard — Sprint 6.CC.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/insights/co2/widgets/co2_card.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Vehicle _vehicle() => Vehicle(
  id: 'v1',
  userId: 'u1',
  nickname: 'Civic',
  make: 'Honda',
  model: 'Civic',
  year: 2020,
  plate: 'ABC1234',
  fuelType: FuelType.gasolina,
  initialOdometer: 50000,
  createdAt: DateTime.utc(2025, 1, 1),
  updatedAt: DateTime.utc(2025, 1, 1),
  syncStatus: SyncStatus.synced,
);

/// Constrói uma [FuelEntry] com data no mês corrente para garantir
/// que o provider mensal retorne dados.
FuelEntry _entryNow({
  required String id,
  required String liters,
  required int odometer,
}) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, 10);
  return FuelEntry(
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
}

Widget _wrap({required List<FuelEntry> entries}) {
  return ProviderScope(
    overrides: [
      fuelEntriesByVehicleProvider(
        'v1',
      ).overrideWith((ref) => Stream.value(entries)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Co2InsightCard(vehicle: _vehicle())),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  group('Co2InsightCard', () {
    testWidgets('com abastecimentos no mês: renderiza total kg e ícone eco', (
      tester,
    ) async {
      final entries = [_entryNow(id: 'a', liters: '40', odometer: 50000)];

      await tester.pumpWidget(_wrap(entries: entries));
      await tester.pumpAndSettle();

      // Ícone eco deve estar visível
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);

      // kg CO₂ formatado (40 * 2.21 = 88.40)
      expect(find.textContaining('88,40 kg CO₂'), findsOneWidget);
    });

    testWidgets(
      'footnote "Considera apenas a queima do combustível" presente',
      (tester) async {
        final entries = [_entryNow(id: 'a', liters: '40', odometer: 50000)];

        await tester.pumpWidget(_wrap(entries: entries));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Considera apenas a queima'),
          findsOneWidget,
        );
      },
    );

    testWidgets('toggle Ano muda o período e re-renderiza', (tester) async {
      final entries = [_entryNow(id: 'a', liters: '40', odometer: 50000)];

      await tester.pumpWidget(_wrap(entries: entries));
      await tester.pumpAndSettle();

      // Toggle "Mês" deve estar visível inicialmente
      expect(find.text('Mês'), findsOneWidget);
      expect(find.text('Ano'), findsOneWidget);

      // Toca no toggle "Ano"
      await tester.tap(find.text('Ano'));
      await tester.pumpAndSettle();

      // Resultado do ano também deve exibir kg CO₂ (mesmo entry no mês corrente)
      expect(find.textContaining('kg CO₂'), findsOneWidget);
    });

    testWidgets(
      'sem abastecimentos: card não é renderizado (SizedBox.shrink)',
      (tester) async {
        await tester.pumpWidget(_wrap(entries: const []));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.eco_rounded), findsNothing);
        expect(find.textContaining('CO₂'), findsNothing);
      },
    );

    testWidgets(
      'gCO₂/km exibe "—" quando apenas 1 abastecimento (sem baseline km)',
      (tester) async {
        // 1 único abastecimento → totalKm = 0 → perKm null → "—"
        final entries = [_entryNow(id: 'a', liters: '40', odometer: 50000)];

        await tester.pumpWidget(_wrap(entries: entries));
        await tester.pumpAndSettle();

        expect(find.textContaining('gCO₂/km: —'), findsOneWidget);
      },
    );

    testWidgets(
      'gCO₂/km exibe valor quando 2+ abastecimentos com delta de odômetro',
      (tester) async {
        // 2 abastecimentos: odometer 50000 e 50500 → 500km
        // 40L gasolina * 2.21 = 88.40 kg → 88400g / 500km = 176.8 → 177 g/km
        final entries = [
          _entryNow(id: 'a', liters: '40', odometer: 50000),
          _entryNow(id: 'b', liters: '40', odometer: 50500),
        ];

        await tester.pumpWidget(_wrap(entries: entries));
        await tester.pumpAndSettle();

        // Deve mostrar um número para gCO₂/km (não "—")
        final perKmFinder = find.textContaining('gCO₂/km:');
        expect(perKmFinder, findsOneWidget);
        final text = tester.widget<Text>(perKmFinder).data ?? '';
        expect(text, isNot(contains('—')));
      },
    );

    testWidgets('equivalência em árvores é exibida quando trees > 0', (
      tester,
    ) async {
      // 40L gasolina = 88.4 kg / 21 = 4 árvores
      final entries = [_entryNow(id: 'a', liters: '40', odometer: 50000)];

      await tester.pumpWidget(_wrap(entries: entries));
      await tester.pumpAndSettle();

      expect(find.textContaining('Para compensar'), findsOneWidget);
      expect(find.textContaining('árvore'), findsOneWidget);
    });
  });
}
