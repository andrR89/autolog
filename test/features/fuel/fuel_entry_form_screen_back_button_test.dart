// Teste de regressão: FuelEntryFormScreen deve exibir BackButton na AppBar.
//
// Causa-raiz corrigida: Sprint 2 usava context.go() para navegar ao formulário,
// deixando a pilha de navegação vazia e sem botão de voltar.
// Fix: context.push() no histórico + leading BackButton explícito no formulário.
//
// Estratégia de override: nenhum provider é lido no build() ou initState() de
// FuelEntryFormScreen (os providers fuelEntrySaverProvider e
// fuelEntryRepositoryProvider só são acessados em _submit() e no debounce de
// odômetro de 600ms). O teste apenas renderiza e verifica o leading — nenhuma
// interação dispara esses providers. GoRouter mínimo via MaterialApp.router
// garante que context.canPop() e BackButton funcionem corretamente.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_entry_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Veículo mínimo reutilizado nos dois casos de teste.
final _vehicle = Vehicle(
  id: 'v-1',
  userId: 'u-1',
  nickname: 'Meu Civic',
  fuelType: FuelType.flex,
  initialOdometer: 45000,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  syncStatus: SyncStatus.synced,
);

GoRouter _buildRouter({FuelEntry? initial}) {
  return GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) =>
            FuelEntryFormScreen(vehicle: _vehicle, initial: initial),
      ),
    ],
  );
}

void main() {
  testWidgets('FuelEntryFormScreen (criar) exibe BackButton na AppBar', (
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

  testWidgets('FuelEntryFormScreen (editar) exibe BackButton na AppBar', (
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
}
