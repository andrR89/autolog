// tts_button.dart — Botão reutilizável de TTS para AppBars.
//
// Toggle play/stop. Constrói o texto de forma lazy (só quando o usuário toca).
// Mantém estado de "está falando" via isSpeakingProvider.

import 'package:autolog/features/tts/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Botão de leitura TTS para AppBar.
///
/// [textBuilder] é chamado de forma lazy — apenas no momento do toque,
/// evitando montar textos longos a cada rebuild.
class TtsButton extends ConsumerWidget {
  const TtsButton({super.key, required this.textBuilder});

  /// Função que constrói o texto a ser narrado.
  final String Function() textBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpeakingAsync = ref.watch(isSpeakingProvider);
    final isSpeaking = isSpeakingAsync.valueOrNull ?? false;

    return IconButton(
      tooltip: isSpeaking ? 'Parar leitura' : 'Ouvir',
      icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
      onPressed: () {
        final svc = ref.read(ttsServiceProvider);
        if (isSpeaking) {
          svc.stop();
        } else {
          svc.speak(textBuilder());
        }
      },
    );
  }
}
