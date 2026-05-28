import 'package:autolog/features/tts/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.CC — testes do MockTtsService.
void main() {
  late MockTtsService svc;

  setUp(() {
    svc = MockTtsService();
  });

  tearDown(() {
    svc.dispose();
  });

  group('MockTtsService', () {
    test('speakCallCount começa em zero', () {
      expect(svc.speakCallCount, 0);
    });

    test('lastText começa nulo', () {
      expect(svc.lastText, isNull);
    });

    test('speak incrementa speakCallCount', () async {
      await svc.speak('Olá mundo');
      expect(svc.speakCallCount, 1);
    });

    test('speak grava lastText', () async {
      await svc.speak('Teste de TTS');
      expect(svc.lastText, 'Teste de TTS');
    });

    test('speak múltiplas vezes acumula contagem', () async {
      await svc.speak('Um');
      await svc.speak('Dois');
      await svc.speak('Três');
      expect(svc.speakCallCount, 3);
      expect(svc.lastText, 'Três');
    });

    test('speak emite true no stream isSpeaking', () async {
      final future = expectLater(svc.isSpeaking, emits(true));
      await svc.speak('Narrar insights');
      await future;
    });

    test('stop emite false no stream isSpeaking', () async {
      final future = expectLater(svc.isSpeaking, emits(false));
      await svc.stop();
      await future;
    });

    test('setSpeaking emite valor no stream', () async {
      final future = expectLater(
        svc.isSpeaking,
        emitsInOrder(<bool>[true, false]),
      );
      svc.setSpeaking(true);
      svc.setSpeaking(false);
      await future;
    });

    test('speak aceita texto vazio sem erro', () async {
      await svc.speak('');
      expect(svc.speakCallCount, 1);
    });

    test('speak aceita texto longo sem erro', () async {
      final long = 'A ' * 500;
      await svc.speak(long);
      expect(svc.lastText, long);
    });
  });
}
