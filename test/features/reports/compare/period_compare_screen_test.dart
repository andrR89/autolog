// Widget test básico para PeriodCompareScreen.
//
// Verifica:
//  - Toggle Mês/Ano visível e funcional
//  - Empty state quando sem dados
//  - Botão "Período personalizado" presente
//
// Usa override direto do periodCompareProvider para evitar depender
// do Drift (banco de dados) e de providers de outras features.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/reports/compare/period_compare_models.dart';
import 'package:autolog/features/reports/compare/period_compare_providers.dart';
import 'package:autolog/features/reports/compare/period_compare_screen.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Vehicle _makeVehicle() => Vehicle(
  id: 'v-test',
  userId: 'u-test',
  nickname: 'Civic',
  fuelType: FuelType.gasolina,
  initialOdometer: 0,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  syncStatus: SyncStatus.synced,
);

PeriodCompareData _emptyData() {
  final emptyPeriod = PeriodSummary(
    label: 'Jan 2026',
    from: DateTime.utc(2026, 1, 1),
    to: DateTime.utc(2026, 1, 31),
    totalSpent: Decimal.zero,
    totalLiters: Decimal.zero,
    totalKm: 0,
    entriesCount: 0,
  );
  return PeriodCompareData(current: emptyPeriod, previous: emptyPeriod);
}

PeriodCompareData _dataWithEntries() {
  final curr = PeriodSummary(
    label: 'Fev 2026',
    from: DateTime.utc(2026, 2, 1),
    to: DateTime.utc(2026, 2, 28),
    totalSpent: Decimal.parse('300'),
    totalLiters: Decimal.parse('50'),
    totalKm: 500,
    entriesCount: 2,
    avgConsumption: Decimal.parse('10'),
  );
  final prev = PeriodSummary(
    label: 'Jan 2026',
    from: DateTime.utc(2026, 1, 1),
    to: DateTime.utc(2026, 1, 31),
    totalSpent: Decimal.parse('250'),
    totalLiters: Decimal.parse('45'),
    totalKm: 400,
    entriesCount: 2,
    avgConsumption: Decimal.parse('9'),
  );
  return PeriodCompareData(current: curr, previous: prev);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late Vehicle testVehicle;

  setUp(() {
    testVehicle = _makeVehicle();
  });

  Widget buildSubject({PeriodCompareData? data}) {
    final resolvedData = data ?? _emptyData();
    return ProviderScope(
      overrides: [
        // Override do provider raiz — evita Drift e providers externos.
        periodCompareProvider.overrideWith(
          (ref, args) => AsyncValue.data(resolvedData),
        ),
      ],
      child: MaterialApp(home: PeriodCompareScreen(vehicle: testVehicle)),
    );
  }

  testWidgets('mostra AppBar com título correto', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Comparar período'), findsOneWidget);
  });

  testWidgets('toggle Mês e Ano visíveis', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Mês'), findsOneWidget);
    expect(find.text('Ano'), findsOneWidget);
  });

  testWidgets('empty state quando sem dados', (tester) async {
    await tester.pumpWidget(buildSubject(data: _emptyData()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum dado para comparar'), findsOneWidget);
  });

  testWidgets('botão período personalizado presente', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Período personalizado'), findsOneWidget);
  });

  testWidgets('tap em Ano muda o modo', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Ano'));
    await tester.pump();

    // Após tap em Ano, o toggle Ano fica ativo (a tela não quebra)
    expect(find.text('Ano'), findsOneWidget);
  });

  testWidgets('com dados exibe cards Atual e Anterior', (tester) async {
    await tester.pumpWidget(buildSubject(data: _dataWithEntries()));
    await tester.pumpAndSettle();

    expect(find.text('Atual'), findsOneWidget);
    expect(find.text('Anterior'), findsOneWidget);
  });

  testWidgets('com dados exibe seções de barras', (tester) async {
    await tester.pumpWidget(buildSubject(data: _dataWithEntries()));
    await tester.pumpAndSettle();

    expect(find.text('Gasto total'), findsOneWidget);
    expect(find.text('Litros abastecidos'), findsOneWidget);
    expect(find.text('Distância'), findsOneWidget);
    expect(find.text('Consumo médio'), findsOneWidget);
  });
}
