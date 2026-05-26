import 'package:autolog/features/auth/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 0.5 — lógica pura de redirect por estado de sessão.
/// Spec: docs/specs/sprint-0.5-auth.md
void main() {
  group('authRedirect', () {
    test('não-logado fora de rota de auth vai para /login', () {
      expect(authRedirect(isLoggedIn: false, location: '/home'), '/login');
    });

    test('não-logado já em rota de auth não redireciona', () {
      expect(authRedirect(isLoggedIn: false, location: '/login'), isNull);
      expect(authRedirect(isLoggedIn: false, location: '/signup'), isNull);
    });

    test('logado em rota de auth vai para /home', () {
      expect(authRedirect(isLoggedIn: true, location: '/login'), '/home');
      expect(authRedirect(isLoggedIn: true, location: '/signup'), '/home');
    });

    test('logado fora de rota de auth não redireciona', () {
      expect(authRedirect(isLoggedIn: true, location: '/home'), isNull);
    });
  });
}
