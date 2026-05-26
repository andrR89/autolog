// Smoke test mínimo para AutoLogApp.
// Substitui o boilerplate de contador gerado pelo Flutter que ficou obsoleto
// após a migração do main.dart para AutoLogApp (Sprint 0.4).

import 'package:autolog/app.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Implementação falsa de [AuthService] para uso em testes de widget.
///
/// Simula um usuário não autenticado sem depender do Supabase.
class FakeAuthService implements AuthService {
  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> signUpWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('AutoLogApp constrói sem erros e exibe título', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
        child: const AutoLogApp(),
      ),
    );
    expect(find.text('AutoLog'), findsOneWidget);
  });
}
