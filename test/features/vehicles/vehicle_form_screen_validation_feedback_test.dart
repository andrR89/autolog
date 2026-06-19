// Teste de regressão: VehicleFormScreen NUNCA pode falhar silenciosamente ao
// submeter um formulário inválido.
//
// Bug original (Homologação 2026-06-18, achado crítico do Bloco 2.3):
//   O usuário preenche apenas o "Apelido" e toca "Adicionar veículo".
//   O form tem outro campo obrigatório ("Odômetro inicial") *abaixo da
//   viewport*. `Form.validate()` retorna false, `_submit()` retorna
//   silenciosamente, e o usuário não vê NENHUM feedback porque o erro
//   renderiza fora da tela.
//
// Esperado:
//   1. Snackbar PT-BR amigável aparece ("Verifique os campos obrigatórios.")
//   2. O form NÃO navega (continua na mesma tela)
//   3. O save NÃO é chamado (não precisa de override de provider porque
//      validate() falha antes de ler o saver)
//
// Estratégia: como `_submit` retorna em `validate()`, não há leitura de
// providers — basta `MaterialApp.router` + `ProviderScope` mínimos
// (mesmo padrão de `vehicle_form_screen_back_button_test.dart`).

import 'package:autolog/features/vehicles/vehicle_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => const VehicleFormScreen(initial: null),
      ),
    ],
  );
}

Future<void> _pumpForm(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: _buildRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tocar "Adicionar veículo" com odômetro vazio mostra SnackBar PT-BR',
    (WidgetTester tester) async {
      await _pumpForm(tester);

      // Preenche somente o Apelido (apelido satisfaz seu próprio validator,
      // mas o Odômetro inicial — abaixo da viewport — segue vazio).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apelido'),
        'Meu Carro',
      );

      // Toca o botão "Adicionar veículo" (rótulo do _SaveActionBar).
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar veículo'));
      await tester.pump(); // dispara o submit
      await tester.pump(const Duration(milliseconds: 100)); // anima snackbar

      // Snackbar global PT-BR deve estar visível — feedback explícito de
      // que a validação falhou, mesmo que o erro do campo esteja fora da
      // viewport.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason:
            'Form inválido sem feedback global = silent failure (root cause '
            'do bug crítico de 18/06).',
      );
      expect(
        find.textContaining(
          RegExp('(verifique|preencha|obrigatóri)', caseSensitive: false),
        ),
        findsWidgets,
        reason:
            'Snackbar deve ter texto PT-BR amigável indicando que faltam '
            'campos obrigatórios.',
      );
    },
  );

  testWidgets(
    'submit inválido NÃO navega: VehicleFormScreen continua montada',
    (WidgetTester tester) async {
      await _pumpForm(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apelido'),
        'Meu Carro',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar veículo'));
      await tester.pumpAndSettle();

      // Form continua na tela — validate falhou, submit retornou cedo,
      // sem navegação.
      expect(find.byType(VehicleFormScreen), findsOneWidget);
    },
  );

  testWidgets(
    'submit inválido faz auto-scroll trazendo o primeiro campo com erro pra viewport',
    (WidgetTester tester) async {
      await _pumpForm(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apelido'),
        'Meu Carro',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar veículo'));
      await tester.pumpAndSettle();

      // Após o scroll, o campo de Odômetro inicial — primeiro inválido —
      // deve estar visível. `findsOneWidget` verifica que o widget existe
      // E está hit-testable (não fora da viewport).
      final odometerField = find.widgetWithText(
        TextFormField,
        'Odômetro inicial (km)',
      );
      expect(odometerField, findsOneWidget);
      // ensureVisible deve ser no-op se já estiver visível pós-fix.
      // Antes do fix, este campo nem renderiza no viewport inicial.
      final renderBox = tester.renderObject<RenderBox>(odometerField);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final fieldTopLeft = renderBox.localToGlobal(Offset.zero);
      expect(
        fieldTopLeft.dy < screenSize.height,
        true,
        reason:
            'Após validate() falhar, o form deve scrollar até trazer o '
            'primeiro campo com erro pra dentro da viewport.',
      );
    },
  );
}
