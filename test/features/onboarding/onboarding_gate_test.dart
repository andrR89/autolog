import 'package:autolog/features/onboarding/onboarding_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowOnboarding', () {
    test('logado e nunca viu → deve mostrar', () {
      expect(
        shouldShowOnboarding(seen: false, isLoggedIn: true),
        isTrue,
      );
    });

    test('logado e já viu → não deve mostrar', () {
      expect(
        shouldShowOnboarding(seen: true, isLoggedIn: true),
        isFalse,
      );
    });

    test('não logado (independente de seen) → não deve mostrar', () {
      expect(
        shouldShowOnboarding(seen: false, isLoggedIn: false),
        isFalse,
      );
      expect(
        shouldShowOnboarding(seen: true, isLoggedIn: false),
        isFalse,
      );
    });
  });
}
