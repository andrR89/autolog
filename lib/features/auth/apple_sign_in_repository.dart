// Repositório de Apple Sign In — Sprint 6.LL.
//
// Orquestra o fluxo:
//   AppleSignInService.signIn() → identityToken → Supabase.signInWithIdToken
//
// Entradas: AppleSignInService (injetado), SupabaseClient (injetado).
// Saídas: void (sucesso) ou exceção tipada [AppleSignInException].
//
// Regra de Ouro #8: este repositório apenas AUTENTICA o usuário.
// Nada de lógica de assinatura/premium aqui — isso é decidido no backend.

import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/auth/apple_sign_in_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Exceção de domínio
// ============================================================================

/// Exceção lançada pelo [AppleSignInRepository] quando o fluxo falha.
class AppleSignInException implements Exception {
  const AppleSignInException(this.message);

  /// Mensagem em PT-BR para exibição ao usuário.
  final String message;

  @override
  String toString() => 'AppleSignInException: $message';
}

// ============================================================================
// Repositório
// ============================================================================

/// Orquestra o fluxo completo de autenticação via Apple Sign In.
class AppleSignInRepository {
  const AppleSignInRepository({
    required AppleSignInService service,
    required SupabaseClient supabaseClient,
  }) : _service = service,
       _client = supabaseClient;

  final AppleSignInService _service;
  final SupabaseClient _client;

  /// Inicia o fluxo de Apple Sign In e autentica o usuário no Supabase.
  ///
  /// Retorna normalmente em caso de sucesso.
  /// Lança [AppleSignInException] se o usuário cancelou ou se houve erro.
  Future<void> signInWithApple() async {
    final result = await _service.signIn();

    switch (result) {
      case AppleSignInCancelled():
        throw const AppleSignInException('Login com Apple cancelado.');

      case AppleSignInError(:final message):
        throw AppleSignInException(message);

      case AppleSignInSuccess(:final identityToken):
        try {
          await _client.auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: identityToken,
          );
        } on AuthException catch (e) {
          throw AppleSignInException(_mapSupabaseError(e));
        } catch (e) {
          throw AppleSignInException(
            'Erro ao autenticar com Apple: ${e.toString()}',
          );
        }
    }
  }

  /// Traduz erros do Supabase Auth para mensagens PT-BR.
  String _mapSupabaseError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('token') && msg.contains('expired')) {
      return 'Token Apple expirado. Tente novamente.';
    }
    if (msg.contains('invalid') || msg.contains('malformed')) {
      return 'Token Apple inválido. Tente novamente.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Sem conexão. Verifique sua internet e tente novamente.';
    }
    return 'Erro ao autenticar: ${e.message}';
  }
}

// ============================================================================
// Providers Riverpod
// ============================================================================

/// Provider do [AppleSignInService] — usa a implementação real em produção.
///
/// Override em testes: `ProviderScope(overrides: [appleSignInServiceProvider.overrideWithValue(...)])`.
final appleSignInServiceProvider = Provider<AppleSignInService>((ref) {
  return const RealAppleSignInService();
});

/// Provider do [AppleSignInRepository].
final appleSignInRepositoryProvider = Provider<AppleSignInRepository>((ref) {
  return AppleSignInRepository(
    service: ref.watch(appleSignInServiceProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
