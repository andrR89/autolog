// Testes unitários de AppleSignInService — Sprint 6.LL.
//
// Cobre MockAppleSignInService (todos os cenários) e a classe de resultado sealed.
// A RealAppleSignInService não é testável em unit test sem device iOS real;
// testamos via mock para garantir que o contrato de interface está correto.

import 'package:autolog/features/auth/apple_sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAppleSignInService', () {
    late MockAppleSignInService service;

    setUp(() {
      service = MockAppleSignInService();
    });

    // ------------------------------------------------------------------
    // isAvailable
    // ------------------------------------------------------------------

    group('isAvailable', () {
      test('retorna true por default', () async {
        expect(await service.isAvailable(), isTrue);
      });

      test('retorna false quando configurado assim', () async {
        service.availableResult = false;
        expect(await service.isAvailable(), isFalse);
      });
    });

    // ------------------------------------------------------------------
    // signIn — cenários de resultado
    // ------------------------------------------------------------------

    group('signIn — cancelled', () {
      test('retorna AppleSignInCancelled por default', () async {
        final result = await service.signIn();
        expect(result, isA<AppleSignInCancelled>());
      });

      test('retorna AppleSignInCancelled quando configurado', () async {
        service.resultToReturn = const AppleSignInCancelled();
        final result = await service.signIn();
        expect(result, isA<AppleSignInCancelled>());
      });
    });

    group('signIn — success', () {
      test('retorna AppleSignInSuccess com os dados fornecidos', () async {
        service.resultToReturn = const AppleSignInSuccess(
          userId: 'user-abc',
          identityToken: 'jwt-token-xyz',
          email: 'user@privaterelay.appleid.com',
          fullName: 'João Silva',
          authorizationCode: 'auth-code-123',
        );

        final result = await service.signIn();

        expect(result, isA<AppleSignInSuccess>());
        final success = result as AppleSignInSuccess;
        expect(success.userId, 'user-abc');
        expect(success.identityToken, 'jwt-token-xyz');
        expect(success.email, 'user@privaterelay.appleid.com');
        expect(success.fullName, 'João Silva');
        expect(success.authorizationCode, 'auth-code-123');
      });

      test('aceita email e fullName nulos (logins subsequentes)', () async {
        service.resultToReturn = const AppleSignInSuccess(
          userId: 'user-abc',
          identityToken: 'jwt-token-xyz',
        );

        final result = await service.signIn();

        expect(result, isA<AppleSignInSuccess>());
        final success = result as AppleSignInSuccess;
        expect(success.email, isNull);
        expect(success.fullName, isNull);
        expect(success.authorizationCode, isNull);
      });
    });

    group('signIn — error', () {
      test('retorna AppleSignInError com a mensagem configurada', () async {
        service.resultToReturn = const AppleSignInError(
          message: 'Falha na autorização com Apple. Tente novamente.',
        );

        final result = await service.signIn();

        expect(result, isA<AppleSignInError>());
        final error = result as AppleSignInError;
        expect(error.message, isNotEmpty);
        expect(error.message, contains('Apple'));
      });
    });

    // ------------------------------------------------------------------
    // Independência entre chamadas (estado não vaza)
    // ------------------------------------------------------------------

    test(
      'cada signIn retorna o resultToReturn atual sem estado residual',
      () async {
        service.resultToReturn = const AppleSignInCancelled();
        expect(await service.signIn(), isA<AppleSignInCancelled>());

        service.resultToReturn = const AppleSignInSuccess(
          userId: 'u1',
          identityToken: 'tok1',
        );
        expect(await service.signIn(), isA<AppleSignInSuccess>());

        service.resultToReturn = const AppleSignInError(message: 'Erro X');
        expect(await service.signIn(), isA<AppleSignInError>());
      },
    );
  });

  // ------------------------------------------------------------------
  // Sealed class — exhaustive pattern coverage
  // ------------------------------------------------------------------

  group('AppleSignInResult switch exhaustive', () {
    String describe(AppleSignInResult result) {
      return switch (result) {
        AppleSignInSuccess() => 'success',
        AppleSignInCancelled() => 'cancelled',
        AppleSignInError() => 'error',
      };
    }

    test('success é descrito corretamente', () {
      const r = AppleSignInSuccess(userId: 'u', identityToken: 't');
      expect(describe(r), 'success');
    });

    test('cancelled é descrito corretamente', () {
      expect(describe(const AppleSignInCancelled()), 'cancelled');
    });

    test('error é descrito corretamente', () {
      expect(describe(const AppleSignInError(message: 'e')), 'error');
    });
  });
}
