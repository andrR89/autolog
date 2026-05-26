import 'package:autolog/features/auth/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 0.5 — validadores de formulário de auth.
/// Spec: docs/specs/sprint-0.5-auth.md
void main() {
  group('validateEmail', () {
    test('vazio retorna erro', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail(null), isNotNull);
    });

    test('sem formato de email retorna erro', () {
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('abc@'), isNotNull);
      expect(validateEmail('a b@c.com'), isNotNull);
    });

    test('email válido retorna null', () {
      expect(validateEmail('a@b.com'), isNull);
      expect(validateEmail('andre.rt0@gmail.com'), isNull);
    });
  });

  group('validatePassword', () {
    test('vazio retorna erro', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });

    test('menos de 6 caracteres retorna erro', () {
      expect(validatePassword('12345'), isNotNull);
    });

    test('6 ou mais caracteres retorna null', () {
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('senhaforte123'), isNull);
    });
  });
}
