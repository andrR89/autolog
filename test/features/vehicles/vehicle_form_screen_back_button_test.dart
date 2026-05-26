// Teste de regressão: VehicleFormScreen deve exibir BackButton na AppBar.
//
// Causa-raiz corrigida: Sprint 2 usava context.go() para navegar ao formulário,
// deixando a pilha de navegação vazia e sem botão de voltar.
// Fix: context.push() na lista + leading BackButton explícito no formulário.
//
// Estratégia de override: nenhum provider é lido no build() ou initState() de
// VehicleFormScreen — os providers (vehicleSaverProvider, currentUserIdProvider)
// só são acessados em _submit(), que não é acionado aqui. Portanto, não é
// necessário sobrescrever providers; basta fornecer um MaterialApp.router com
// GoRouter mínimo para que context.canPop() e BackButton funcionem corretamente.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/vehicle_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter({Vehicle? initial}) {
  return GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => VehicleFormScreen(initial: initial),
      ),
    ],
  );
}

void main() {
  testWidgets('VehicleFormScreen (criar) exibe BackButton na AppBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: _buildRouter(initial: null)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('VehicleFormScreen (editar) exibe BackButton na AppBar', (
    WidgetTester tester,
  ) async {
    final vehicle = Vehicle(
      id: 'v-1',
      userId: 'u-1',
      nickname: 'Meu Civic',
      fuelType: FuelType.flex,
      initialOdometer: 45000,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      syncStatus: SyncStatus.synced,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: _buildRouter(initial: vehicle)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
  });
}
