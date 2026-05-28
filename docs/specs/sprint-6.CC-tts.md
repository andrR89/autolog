# Sprint 6.CC — Áudio TTS (lê insights / recap pro motorista)

> Sintetiza fala em PT-BR via `flutter_tts` (já compatível iOS+Android,
> sem chave/API). Botão "▶ Ouvir" em telas-chave: insights, recap, fiscal.

## Decisões
- Pacote `flutter_tts` (oficial community, ativo).
- Default voice: pt-BR (qualquer disponível no device).
- Velocidade 0.5 (mais lenta — user dirigindo, contexto de stress).
- Botão `IconButton(Icons.volume_up)` discreto no AppBar de telas elegíveis.
- Toggle play/pause; estado por tela.

## Mudanças

### 1. Pacote
`pubspec.yaml`: `flutter_tts: ^4.2.0`.

### 2. Service
`lib/features/tts/tts_service.dart`:
```dart
abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
  Stream<bool> get isSpeaking;
}

class RealTtsService implements TtsService {
  // FlutterTts singleton.
  // setLanguage('pt-BR'), setSpeechRate(0.5), setPitch(1.0).
}

class MockTtsService implements TtsService {
  int speakCallCount = 0;
  String? lastText;
}

final ttsServiceProvider = Provider<TtsService>(...);
final isSpeakingProvider = StreamProvider<bool>(...);
```

### 3. Widget reutilizável
`lib/features/tts/widgets/tts_button.dart`:
- ConsumerWidget recebe `String Function() textBuilder` (lazy — só monta texto se user tocar).
- Mostra `Icons.volume_up` parado / `Icons.stop` durante speak.
- Tap toggle.

### 4. Integração
Botão TTS no AppBar de:
- `InsightsScreen` — lê padrões detectados + propostas.
- `RecapScreen` — narra slide atual.
- `FiscalPlanScreen` — lê propostas.

Helper `lib/features/tts/insight_narrator.dart`:
- `String narrateInsights(HistoryInsights r)` — junta padrões/propostas em texto fluído PT-BR.
- `String narrateRecapSlide(int index, RecapData r)` — frase pro slide N.
- `String narrateFiscal(List<ProposedReminder> r, Vehicle v)` — agrupa.

## Testes
- `test/features/tts/tts_service_test.dart` — MockTtsService callCount/lastText.
- `test/features/tts/insight_narrator_test.dart` — outputs determinísticos:
  - `narrateInsights({patterns: [], proposed: []})` → "Sem insights ainda."
  - 1 padrão + 1 proposta → texto contém ambos.
  - Recap slide 0 (hero) → "Seu mês em movimento..."

## Critérios
- Suite verde + ~10 novos
- analyze 0, iOS sim builds
- Pacote `flutter_tts` resolve sem conflito

## Não-objetivos
- Voice picker (usa default device).
- Highlight do trecho falado.
- TTS na tela chat (futuro — preciso tokenizar resposta).
