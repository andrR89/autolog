// Serviço de Apple Sign In — Sprint 6.LL.
//
// Abstrai o pacote `sign_in_with_apple` atrás de uma interface testável.
// A implementação real (`RealAppleSignInService`) só é usada em mobile iOS 13+.
// Em Android, `isAvailable()` sempre retorna false — o botão não aparece na UI.
// Na web (Sprint 8), o redirect URL será configurado separadamente.
//
// Regra de Ouro #8: Apple Sign In apenas IDENTIFICA o usuário.
// A assinatura premium é decidida no backend (is_premium), independente de plataforma.

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// ============================================================================
// Resultado sealed
// ============================================================================

/// Resultado possível de uma tentativa de Apple Sign In.
sealed class AppleSignInResult {
  const AppleSignInResult();
}

/// Login bem-sucedido — contém o identityToken para troca com o Supabase.
class AppleSignInSuccess extends AppleSignInResult {
  const AppleSignInSuccess({
    required this.userId,
    required this.identityToken,
    this.email,
    this.fullName,
    this.authorizationCode,
  });

  /// Identificador opaco e estável da Apple para o usuário.
  final String userId;

  /// JWT emitido pela Apple — usado em `signInWithIdToken` no Supabase.
  final String identityToken;

  /// E-mail do usuário (fornecido apenas no primeiro login; null nas vezes seguintes).
  final String? email;

  /// Nome completo (fornecido apenas no primeiro login; null nas vezes seguintes).
  final String? fullName;

  /// Código de autorização de uso único (opcional, para validação extra no backend).
  final String? authorizationCode;
}

/// Usuário cancelou o fluxo de login.
class AppleSignInCancelled extends AppleSignInResult {
  const AppleSignInCancelled();
}

/// Erro durante o fluxo de login.
class AppleSignInError extends AppleSignInResult {
  const AppleSignInError({required this.message});

  /// Mensagem de erro em PT-BR para exibição ao usuário.
  final String message;
}

// ============================================================================
// Contrato / interface
// ============================================================================

/// Contrato de Apple Sign In.
///
/// Abstraído para facilitar testes (usar [MockAppleSignInService]) e
/// futura troca de implementação sem alterar callers.
abstract class AppleSignInService {
  /// Retorna `true` se Apple Sign In está disponível no dispositivo/OS atual.
  ///
  /// iOS 13+ → true.
  /// Android → false.
  /// Web → false (suporte via redirect na Sprint 8).
  Future<bool> isAvailable();

  /// Inicia o fluxo nativo de Apple Sign In.
  ///
  /// Retorna [AppleSignInSuccess], [AppleSignInCancelled] ou [AppleSignInError].
  /// Nunca lança exceção — todo erro é encapsulado em [AppleSignInError].
  Future<AppleSignInResult> signIn();
}

// ============================================================================
// Implementação real (usa pacote sign_in_with_apple)
// ============================================================================

/// Implementação concreta que delega ao pacote `sign_in_with_apple`.
class RealAppleSignInService implements AppleSignInService {
  const RealAppleSignInService();

  @override
  Future<bool> isAvailable() async {
    return SignInWithApple.isAvailable();
  }

  @override
  Future<AppleSignInResult> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        return const AppleSignInError(
          message: 'Não foi possível obter o token de identidade da Apple.',
        );
      }

      // Monta fullName a partir dos campos separados (Apple envia assim)
      final nameParts = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ');

      return AppleSignInSuccess(
        userId: credential.userIdentifier ?? '',
        identityToken: identityToken,
        email: credential.email,
        fullName: nameParts.isEmpty ? null : nameParts,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AppleSignInCancelled();
      }
      return AppleSignInError(message: _mapAppleError(e));
    } catch (e) {
      return AppleSignInError(
        message: 'Erro ao entrar com Apple: ${e.toString()}',
      );
    }
  }

  /// Traduz erros da Apple para mensagens PT-BR.
  String _mapAppleError(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.failed:
        return 'Falha na autorização com Apple. Tente novamente.';
      case AuthorizationErrorCode.invalidResponse:
        return 'Resposta inválida da Apple. Tente novamente.';
      case AuthorizationErrorCode.notHandled:
        return 'Operação Apple Sign In não suportada neste dispositivo.';
      case AuthorizationErrorCode.notInteractive:
        return 'Não foi possível exibir a tela de login da Apple.';
      case AuthorizationErrorCode.unknown:
        return 'Erro desconhecido ao entrar com Apple.';
      case AuthorizationErrorCode.canceled:
        // Não deve chegar aqui (já tratado acima), mas cobre o exhaustive check.
        return 'Login cancelado.';
    }
  }
}

// ============================================================================
// Mock para testes e desenvolvimento
// ============================================================================

/// Implementação falsa de [AppleSignInService] para uso em testes e mocks.
///
/// Configurar [resultToReturn] antes de chamar [signIn].
/// Configurar [availableResult] antes de chamar [isAvailable].
class MockAppleSignInService implements AppleSignInService {
  /// Resultado que [isAvailable] vai retornar. Default: `true`.
  bool availableResult = true;

  /// Resultado que [signIn] vai retornar. Default: [AppleSignInCancelled].
  AppleSignInResult resultToReturn = const AppleSignInCancelled();

  @override
  Future<bool> isAvailable() async => availableResult;

  @override
  Future<AppleSignInResult> signIn() async => resultToReturn;
}
