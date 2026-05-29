// Testes unitários de AppleSignInRepository — Sprint 6.LL.
//
// Cobre:
//  - Sucesso: chama signInWithIdToken com o identityToken correto.
//  - Cancelamento: lança AppleSignInException com mensagem de cancelamento.
//  - Erro do serviço: lança AppleSignInException com a mensagem do erro.
//  - Erro do Supabase (AuthException): traduz para AppleSignInException PT-BR.
//
// O SupabaseClient é mockado via FakeSupabaseClient para evitar chamadas reais.

import 'package:autolog/features/auth/apple_sign_in_repository.dart';
import 'package:autolog/features/auth/apple_sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Fakes / stubs
// ============================================================================

/// Fake de [AppleSignInService] para testes do repositório.
class _FakeAppleSignInService implements AppleSignInService {
  _FakeAppleSignInService(this._result);

  final AppleSignInResult _result;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AppleSignInResult> signIn() async => _result;
}

/// Stub de [GoTrueClient] que captura a última chamada a [signInWithIdToken].
class _FakeGoTrueClient extends Fake implements GoTrueClient {
  String? capturedIdToken;
  OAuthProvider? capturedProvider;

  // Configura se deve lançar AuthException na próxima chamada
  AuthException? exceptionToThrow;

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    capturedProvider = provider;
    capturedIdToken = idToken;
    // Retorna AuthResponse vazio — suficiente para o repositório não falhar
    return AuthResponse();
  }
}

/// Stub mínimo de [SupabaseClient] que expõe o [_FakeGoTrueClient].
class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this.fakeAuth);

  final _FakeGoTrueClient fakeAuth;

  @override
  GoTrueClient get auth => fakeAuth;
}

// ============================================================================
// Helpers de fábrica
// ============================================================================

AppleSignInRepository _makeRepo({
  required AppleSignInResult serviceResult,
  _FakeGoTrueClient? fakeAuth,
}) {
  final auth = fakeAuth ?? _FakeGoTrueClient();
  return AppleSignInRepository(
    service: _FakeAppleSignInService(serviceResult),
    supabaseClient: _FakeSupabaseClient(auth),
  );
}

// ============================================================================
// Testes
// ============================================================================

void main() {
  group('AppleSignInRepository.signInWithApple', () {
    // ------------------------------------------------------------------
    // Cenário: sucesso
    // ------------------------------------------------------------------

    test(
      'passa identityToken correto ao Supabase em caso de sucesso',
      () async {
        const fakeToken = 'eyJhbGciOiJSUzI1NiJ9.payload.sig';
        const fakeUserId = 'apple-user-001';
        final fakeAuth = _FakeGoTrueClient();

        final repo = AppleSignInRepository(
          service: _FakeAppleSignInService(
            const AppleSignInSuccess(
              userId: fakeUserId,
              identityToken: fakeToken,
              email: 'user@privaterelay.appleid.com',
            ),
          ),
          supabaseClient: _FakeSupabaseClient(fakeAuth),
        );

        await repo.signInWithApple();

        expect(fakeAuth.capturedIdToken, fakeToken);
        expect(fakeAuth.capturedProvider, OAuthProvider.apple);
      },
    );

    test('não lança exceção em caso de sucesso', () async {
      final repo = _makeRepo(
        serviceResult: const AppleSignInSuccess(
          userId: 'u',
          identityToken: 'tok',
        ),
      );

      expect(() => repo.signInWithApple(), returnsNormally);
    });

    // ------------------------------------------------------------------
    // Cenário: cancelamento
    // ------------------------------------------------------------------

    test('lança AppleSignInException quando usuário cancela', () async {
      final repo = _makeRepo(serviceResult: const AppleSignInCancelled());

      await expectLater(
        repo.signInWithApple(),
        throwsA(isA<AppleSignInException>()),
      );
    });

    test('mensagem de cancelamento está em PT-BR', () async {
      final repo = _makeRepo(serviceResult: const AppleSignInCancelled());

      try {
        await repo.signInWithApple();
        fail('Deveria ter lançado AppleSignInException');
      } on AppleSignInException catch (e) {
        expect(e.message, 'Login com Apple cancelado.');
      }
    });

    // ------------------------------------------------------------------
    // Cenário: erro do serviço
    // ------------------------------------------------------------------

    test(
      'propaga mensagem de erro do serviço como AppleSignInException',
      () async {
        const errorMsg = 'Falha na autorização com Apple. Tente novamente.';
        final repo = _makeRepo(
          serviceResult: const AppleSignInError(message: errorMsg),
        );

        try {
          await repo.signInWithApple();
          fail('Deveria ter lançado AppleSignInException');
        } on AppleSignInException catch (e) {
          expect(e.message, errorMsg);
        }
      },
    );

    // ------------------------------------------------------------------
    // Cenário: erro do Supabase (AuthException)
    // ------------------------------------------------------------------

    test(
      'traduz AuthException do Supabase para AppleSignInException',
      () async {
        final fakeAuth = _FakeGoTrueClient()
          ..exceptionToThrow = const AuthException('invalid token');

        final repo = AppleSignInRepository(
          service: _FakeAppleSignInService(
            const AppleSignInSuccess(userId: 'u', identityToken: 'tok'),
          ),
          supabaseClient: _FakeSupabaseClient(fakeAuth),
        );

        await expectLater(
          repo.signInWithApple(),
          throwsA(isA<AppleSignInException>()),
        );
      },
    );

    test(
      'mensagem de AuthException "invalid" é traduzida para PT-BR',
      () async {
        final fakeAuth = _FakeGoTrueClient()
          ..exceptionToThrow = const AuthException('invalid token');

        final repo = AppleSignInRepository(
          service: _FakeAppleSignInService(
            const AppleSignInSuccess(userId: 'u', identityToken: 'tok'),
          ),
          supabaseClient: _FakeSupabaseClient(fakeAuth),
        );

        try {
          await repo.signInWithApple();
          fail('Deveria ter lançado AppleSignInException');
        } on AppleSignInException catch (e) {
          expect(e.message, contains('inválido'));
        }
      },
    );

    test(
      'mensagem de AuthException "expired" é traduzida para PT-BR',
      () async {
        final fakeAuth = _FakeGoTrueClient()
          ..exceptionToThrow = const AuthException('token expired');

        final repo = AppleSignInRepository(
          service: _FakeAppleSignInService(
            const AppleSignInSuccess(userId: 'u', identityToken: 'tok'),
          ),
          supabaseClient: _FakeSupabaseClient(fakeAuth),
        );

        try {
          await repo.signInWithApple();
          fail('Deveria ter lançado AppleSignInException');
        } on AppleSignInException catch (e) {
          expect(e.message, contains('expirado'));
        }
      },
    );

    // ------------------------------------------------------------------
    // AppleSignInException — toString
    // ------------------------------------------------------------------

    test('AppleSignInException.toString inclui a mensagem', () {
      const ex = AppleSignInException('Erro de teste');
      expect(ex.toString(), contains('Erro de teste'));
    });
  });
}
