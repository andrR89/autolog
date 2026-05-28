import 'package:autolog/features/whatsapp/whatsapp_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.FF — Testes do MockWhatsAppService.
/// Valida: isPaired toggle, generatePairingCode, unpair, estado inicial.

void main() {
  late MockWhatsAppService svc;

  setUp(() {
    svc = MockWhatsAppService();
  });

  group('estado inicial', () {
    test('começa não-pareado', () async {
      expect(await svc.isPaired(), isFalse);
    });

    test('pairedPhoneNumber retorna null quando não-pareado', () async {
      expect(await svc.pairedPhoneNumber(), isNull);
    });
  });

  group('generatePairingCode', () {
    test('retorna código de 6 dígitos', () async {
      final code = await svc.generatePairingCode();
      expect(code, isNotEmpty);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('expõe lastCode após gerar', () async {
      await svc.generatePairingCode();
      expect(svc.lastCode, isNotNull);
    });

    test('gerar código não altera isPaired', () async {
      await svc.generatePairingCode();
      expect(await svc.isPaired(), isFalse);
    });
  });

  group('simulatePairing / isPaired', () {
    test('simulatePairing → isPaired = true', () async {
      svc.simulatePairing('+5511999999999');
      expect(await svc.isPaired(), isTrue);
    });

    test('simulatePairing → pairedPhoneNumber retorna número', () async {
      svc.simulatePairing('+5511999999999');
      expect(await svc.pairedPhoneNumber(), '+5511999999999');
    });

    test('pairedPhoneNumber retorna null quando não-pareado', () async {
      expect(await svc.pairedPhoneNumber(), isNull);
    });
  });

  group('unpair', () {
    test('unpair após pareamento → isPaired = false', () async {
      svc.simulatePairing('+5511999999999');
      await svc.unpair();
      expect(await svc.isPaired(), isFalse);
    });

    test('unpair → pairedPhoneNumber = null', () async {
      svc.simulatePairing('+5511999999999');
      await svc.unpair();
      expect(await svc.pairedPhoneNumber(), isNull);
    });

    test('unpair sem pareamento prévio é no-op (não lança)', () async {
      await expectLater(svc.unpair(), completes);
    });
  });

  group('reset', () {
    test('reset limpa todo o estado', () async {
      svc.simulatePairing('+5511999999999');
      await svc.generatePairingCode();
      svc.reset();

      expect(await svc.isPaired(), isFalse);
      expect(await svc.pairedPhoneNumber(), isNull);
      expect(svc.lastCode, isNull);
    });
  });

  group('instâncias isoladas', () {
    test('instâncias distintas não compartilham estado', () async {
      final svc2 = MockWhatsAppService();
      svc.simulatePairing('+5511999999999');

      expect(await svc.isPaired(), isTrue);
      expect(await svc2.isPaired(), isFalse);
    });
  });
}
