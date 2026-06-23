import 'package:autolog/core/observability/analytics.dart';
import 'package:autolog/data/remote/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contrato de autenticação da camada de domínio.
///
/// Abstraído do Supabase para facilitar testes e possível troca futura.
abstract class AuthService {
  /// Stream que emite `true` quando o usuário está logado, `false` caso contrário.
  Stream<bool> get authStateChanges;

  /// Estado atual de autenticação (síncrono).
  bool get isLoggedIn;

  /// Registra um novo usuário com e-mail e senha.
  Future<void> signUpWithEmail(String email, String password);

  /// Autentica um usuário existente com e-mail e senha.
  Future<void> signInWithEmail(String email, String password);

  /// Inicia o fluxo OAuth com Google via navegador.
  Future<void> signInWithGoogle();

  /// Encerra a sessão do usuário atual.
  Future<void> signOut();
}

/// Implementação concreta de [AuthService] usando Supabase Auth.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Stream<bool> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) => event.session != null);
  }

  @override
  bool get isLoggedIn => _client.auth.currentSession != null;

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
    final uid = _client.auth.currentSession?.user.id;
    if (uid != null) {
      await analyticsIdentify(uid);
      await track(AnalyticsEvent.signupComplete, props: {'method': 'email'});
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final uid = _client.auth.currentSession?.user.id;
    if (uid != null) {
      await analyticsIdentify(uid);
      await track(AnalyticsEvent.loginSuccess, props: {'method': 'email'});
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.autolog://login-callback/',
    );
    // signInWithOAuth retorna antes do callback resolver — o identify real
    // do user Google é feito no listener de authStateChanges em app.dart.
  }

  @override
  Future<void> signOut() async {
    await track(AnalyticsEvent.logout);
    await analyticsReset();
    await _client.auth.signOut();
  }
}

/// Provider Riverpod que expõe o [AuthService] da aplicação.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthService(client);
});
