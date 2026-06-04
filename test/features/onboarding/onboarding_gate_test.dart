import 'package:autolog/features/onboarding/onboarding_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowOnboarding', () {
    // ── Casos novos (fix caso B — onboarding é marketing pré-login) ──────────

    test('nunca viu E não logado → mostra onboarding', () {
      expect(shouldShowOnboarding(seen: false, isLoggedIn: false), isTrue);
    });

    test('nunca viu E logado → não mostra (já é usuário, já converteu)', () {
      expect(shouldShowOnboarding(seen: false, isLoggedIn: true), isFalse);
    });

    test('já viu E não logado → não mostra', () {
      expect(shouldShowOnboarding(seen: true, isLoggedIn: false), isFalse);
    });

    test('já viu E logado → não mostra', () {
      expect(shouldShowOnboarding(seen: true, isLoggedIn: true), isFalse);
    });

    // ── Teste de regressão do bug homologado ─────────────────────────────────

    test(
      'regressão (homolog 04/06/2026): seen=false isLoggedIn=false retorna true',
      () {
        // Antes do fix, a implementação tinha `if (!isLoggedIn) return false`
        // como primeiro guard, fazendo com que desinstalar + abrir deslogado
        // caísse direto no login em vez de mostrar o onboarding.
        expect(shouldShowOnboarding(seen: false, isLoggedIn: false), isTrue);
      },
    );
  });
}
