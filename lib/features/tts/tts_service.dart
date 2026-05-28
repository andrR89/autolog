// tts_service.dart — Abstração de Text-to-Speech para o AutoLog.
//
// RealTtsService envolve flutter_tts com configurações PT-BR.
// MockTtsService permite testes e simulador web sem engine de voz.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ---------------------------------------------------------------------------
// Abstração
// ---------------------------------------------------------------------------

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
  Stream<bool> get isSpeaking;

  void dispose();
}

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealTtsService implements TtsService {
  RealTtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  void _init() {
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _controller.add(false);
    });

    _tts.setErrorHandler((dynamic msg) {
      // Erros silenciosos — não interrompe a UI.
      _controller.add(false);
    });

    _tts.setCancelHandler(() {
      _controller.add(false);
    });
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      _controller.add(true);
      await _tts.speak(text);
    } catch (_) {
      // Falha silenciosa.
      _controller.add(false);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Falha silenciosa.
    }
    _controller.add(false);
  }

  @override
  Stream<bool> get isSpeaking => _controller.stream;

  @override
  void dispose() {
    _tts.stop();
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Mock (testes / simulador sem TTS engine)
// ---------------------------------------------------------------------------

class MockTtsService implements TtsService {
  int speakCallCount = 0;
  String? lastText;

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  Future<void> speak(String text) async {
    speakCallCount++;
    lastText = text;
    _controller.add(true);
  }

  @override
  Future<void> stop() async {
    _controller.add(false);
  }

  /// Controle manual de estado — útil nos testes.
  void setSpeaking(bool value) => _controller.add(value);

  @override
  Stream<bool> get isSpeaking => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Providers Riverpod
// ---------------------------------------------------------------------------

/// Instância única do serviço TTS.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = RealTtsService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream do estado de "está falando".
final isSpeakingProvider = StreamProvider<bool>((ref) {
  final svc = ref.watch(ttsServiceProvider);
  return svc.isSpeaking;
});
