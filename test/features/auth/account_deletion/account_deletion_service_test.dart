// test/features/auth/account_deletion/account_deletion_service_test.dart
//
// Sprint 7.3 — LGPD: testes unitários do AccountDeletionService.
//
// Cobre:
//   - MockAccountDeletionService.deleteAccount() sucesso: callCount incrementa
//   - MockAccountDeletionService.deleteAccount() erro: lança AccountDeletionException
//   - AccountDeletionException.toString() formata corretamente
//   - Delay simulado não impede o sucesso
//   - Múltiplas chamadas incrementam callCount corretamente

import 'package:autolog/features/auth/account_deletion/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAccountDeletionService', () {
    test('deleteAccount() bem-sucedido incrementa callCount', () async {
      final svc = MockAccountDeletionService();

      expect(svc.callCount, 0);
      await svc.deleteAccount();
      expect(svc.callCount, 1);
    });

    test('deleteAccount() incrementa callCount a cada chamada', () async {
      final svc = MockAccountDeletionService();

      await svc.deleteAccount();
      await svc.deleteAccount();
      await svc.deleteAccount();

      expect(svc.callCount, 3);
    });

    test(
      'deleteAccount() com shouldThrow=true lança AccountDeletionException',
      () async {
        const errorMsg = 'Falha simulada ao deletar conta.';
        final svc = MockAccountDeletionService(
          shouldThrow: true,
          exceptionMessage: errorMsg,
        );

        expect(
          () async => svc.deleteAccount(),
          throwsA(
            isA<AccountDeletionException>().having(
              (e) => e.message,
              'message',
              errorMsg,
            ),
          ),
        );
      },
    );

    test(
      'deleteAccount() com shouldThrow=true ainda incrementa callCount',
      () async {
        final svc = MockAccountDeletionService(shouldThrow: true);

        try {
          await svc.deleteAccount();
        } on AccountDeletionException {
          // esperado
        }

        expect(svc.callCount, 1);
      },
    );

    test('deleteAccount() com delay completa com sucesso', () async {
      final svc = MockAccountDeletionService(delayMs: 50);

      final stopwatch = Stopwatch()..start();
      await svc.deleteAccount();
      stopwatch.stop();

      expect(svc.callCount, 1);
      // Garante que o delay foi respeitado (com margem de 10ms para CI)
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });

    test(
      'deleteAccount() com delay E shouldThrow lança antes de retornar',
      () async {
        final svc = MockAccountDeletionService(
          shouldThrow: true,
          exceptionMessage: 'Timeout de rede.',
          delayMs: 30,
        );

        expect(
          () async => svc.deleteAccount(),
          throwsA(
            isA<AccountDeletionException>().having(
              (e) => e.message,
              'message',
              'Timeout de rede.',
            ),
          ),
        );
      },
    );
  });

  group('AccountDeletionException', () {
    test('toString() inclui a mensagem formatada', () {
      const exception = AccountDeletionException('Conta não encontrada.');
      expect(
        exception.toString(),
        'AccountDeletionException: Conta não encontrada.',
      );
    });

    test('message está acessível', () {
      const exception = AccountDeletionException('Erro de rede.');
      expect(exception.message, 'Erro de rede.');
    });

    test('é uma Exception (pode ser usada em bloco catch)', () {
      const exception = AccountDeletionException('Teste.');
      expect(exception, isA<Exception>());
    });
  });
}
