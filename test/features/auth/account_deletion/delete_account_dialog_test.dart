// test/features/auth/account_deletion/delete_account_dialog_test.dart
//
// Sprint 7.3 — LGPD: testes de widget do fluxo de confirmação de exclusão.
//
// Cobre:
//   - Botão "Excluir minha conta" abre o AlertDialog (etapa 1)
//   - Botão "Cancelar" fecha sem chamar o serviço
//   - "Continuar" avança para etapa 2 (campo de digitação)
//   - Botão final desabilitado até o usuário digitar "EXCLUIR" corretamente
//   - Digitação incorreta mantém o botão desabilitado
//   - Digitação correta de "EXCLUIR" habilita o botão final
//   - Sucesso → serviço chamado 1 vez
//   - Falha → SnackBar com mensagem de erro exibida

import 'package:autolog/features/auth/account_deletion/account_deletion_service.dart';
import 'package:autolog/features/auth/account_deletion/widgets/delete_account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: monta a widget dentro de um ProviderScope com mock injetado
// ---------------------------------------------------------------------------

Widget _buildTestApp({required AccountDeletionService service}) {
  return ProviderScope(
    overrides: [accountDeletionServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: DeleteAccountSection(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DeleteAccountSection — fluxo de UI', () {
    testWidgets('card é renderizado com texto correto', (tester) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      expect(find.text('Excluir conta'), findsOneWidget);
      expect(find.textContaining('Apaga permanentemente'), findsOneWidget);
      expect(find.text('Excluir minha conta'), findsOneWidget);
    });

    testWidgets(
      'toque em "Excluir minha conta" abre AlertDialog com lista de dados',
      (tester) async {
        final svc = MockAccountDeletionService();
        await tester.pumpWidget(_buildTestApp(service: svc));

        await tester.tap(find.text('Excluir minha conta'));
        await tester.pumpAndSettle();

        // Verifica que o diálogo abre com conteúdo da etapa 1
        // 'Excluir conta' aparece no card e no título do diálogo — findsWidgets
        expect(find.text('Excluir conta'), findsWidgets);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Continuar'), findsOneWidget);
        // Verifica alguns dos dados listados no diálogo
        expect(find.textContaining('veículos cadastrados'), findsOneWidget);
        // 'abastecimentos' aparece no card E no diálogo — usar findsWidgets
        expect(find.textContaining('abastecimentos'), findsWidgets);
      },
    );

    testWidgets('"Cancelar" na etapa 1 fecha o diálogo sem chamar o serviço', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(svc.callCount, 0);
      // Diálogo foi fechado
      expect(find.text('Continuar'), findsNothing);
    });

    testWidgets('"Continuar" avança para etapa 2 com campo de texto', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Etapa 2: campo de texto visível
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Excluir definitivamente'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets(
      'botão "Excluir definitivamente" começa desabilitado (campo vazio)',
      (tester) async {
        final svc = MockAccountDeletionService();
        await tester.pumpWidget(_buildTestApp(service: svc));

        await tester.tap(find.text('Excluir minha conta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Botão desabilitado: onPressed é null
        final button = tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Excluir definitivamente'),
            matching: find.byType(TextButton),
          ),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('digitação incorreta mantém o botão desabilitado', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Texto que não corresponde à palavra de confirmação
      await tester.enterText(find.byType(TextField), 'CANCELAR');
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Excluir definitivamente'),
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('digitação de "EXCLUIR" habilita o botão final', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Excluir definitivamente'),
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('fluxo completo de sucesso chama o serviço exatamente 1 vez', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      // Etapa 1
      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();

      // Avança para etapa 2
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Digita a palavra de confirmação
      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();

      // Confirma
      await tester.tap(find.text('Excluir definitivamente'));
      await tester.pumpAndSettle();

      expect(svc.callCount, 1);
    });

    testWidgets('"Cancelar" na etapa 2 fecha o diálogo sem chamar o serviço', (
      tester,
    ) async {
      final svc = MockAccountDeletionService();
      await tester.pumpWidget(_buildTestApp(service: svc));

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Cancela na etapa 2
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(svc.callCount, 0);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('falha no serviço exibe SnackBar com mensagem de erro', (
      tester,
    ) async {
      const errorMsg = 'Não foi possível conectar ao servidor.';
      final svc = MockAccountDeletionService(
        shouldThrow: true,
        exceptionMessage: errorMsg,
      );
      await tester.pumpWidget(_buildTestApp(service: svc));

      // Fluxo completo
      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      await tester.tap(find.text('Excluir definitivamente'));
      await tester.pumpAndSettle();

      // SnackBar deve aparecer com a mensagem de erro
      expect(find.text(errorMsg), findsOneWidget);
    });
  });
}
