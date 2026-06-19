// Regressão (Homologação 2026-06-18, achado 🟡):
//   O card da garagem mostrava o km inicial do veículo em vez do último
//   odômetro conhecido. Fiesta cadastrado com 10000 km mas com último
//   abastecimento a 11000 km exibia "10 000 km", inconsistente com o resto
//   do app (validação de lembrete usa 11000).

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle({int initialOdometer = 10000}) => Vehicle(
  id: 'v-1',
  userId: 'u-1',
  nickname: 'Meu Civic',
  fuelType: FuelType.flex,
  initialOdometer: initialOdometer,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  syncStatus: SyncStatus.synced,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required Vehicle vehicle,
  int? currentOdometer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VehicleCard(
          vehicle: vehicle,
          currentOdometer: currentOdometer,
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'currentOdometer != null → exibe o atual, não o inicial',
    (WidgetTester tester) async {
      await _pumpCard(
        tester,
        vehicle: _vehicle(initialOdometer: 10000),
        currentOdometer: 11000,
      );
      // 11 000 com narrow no-break space — não importa o tipo de separador,
      // o que importa é que 11000 está lá e 10000 não.
      expect(find.textContaining('11'), findsWidgets);
      expect(
        find.text('10 000'),
        findsNothing,
        reason: 'Não deveria mostrar o inicial quando há atual.',
      );
    },
  );

  testWidgets(
    'currentOdometer null → fallback pro inicial (sem abastecimentos)',
    (WidgetTester tester) async {
      await _pumpCard(
        tester,
        vehicle: _vehicle(initialOdometer: 10000),
        currentOdometer: null,
      );
      expect(find.textContaining('10'), findsWidgets);
    },
  );
}
