# Sprint 6.BB — Widget tela inicial

> **MVP foca iOS** (WidgetKit). Android entra em sprint futura ou
> se o Sonnet conseguir paridade no mesmo PR.

## Decisões pragmáticas
- Pacote `home_widget` (community) faz ponte Dart ↔ nativo.
- Widget pequeno (systemSmall): mostra UM dado relevante.
- Conteúdo: próximo lembrete OU total gasto no mês corrente (escolhe
  o mais útil pra contexto — começa com "próximo lembrete").
- Refresh: dispara `HomeWidget.updateWidget` ao salvar
  abastecimento/despesa/lembrete.

## Mudanças

### 1. Pacote
`pubspec.yaml`: `home_widget: ^0.7.0` (ou latest estável).

### 2. App Group (iOS)
Necessário pra widget e app compartilharem `UserDefaults`. Configurar
em `ios/Runner/Runner.entitlements` + Capability `com.apple.security.application-groups`
com identifier `group.com.oddcar.autolog`.

### 3. Camada Dart
`lib/features/home_widget/home_widget_service.dart`:
```dart
class HomeWidgetService {
  static const _appGroupId = 'group.com.oddcar.autolog';
  static const _iosWidgetName = 'AutoLogWidget';

  /// Atualiza o widget com dados frescos.
  /// Lê do banco: próximo lembrete (data mais próxima futura).
  Future<void> refresh({
    required ReminderRepository reminderRepo,
    required String userId,
  }) async {
    final next = await _findNextReminder(reminderRepo, userId);
    if (next == null) {
      await HomeWidget.saveWidgetData('headline', 'Sem lembretes');
      await HomeWidget.saveWidgetData('sub', 'Tudo em dia');
    } else {
      await HomeWidget.saveWidgetData('headline', next.title);
      await HomeWidget.saveWidgetData('sub', _formatDue(next));
    }
    await HomeWidget.updateWidget(
      iOSName: _iosWidgetName,
      androidName: 'AutoLogWidgetProvider', // anota TODO Android
    );
  }
}
```

Provider Riverpod. Chamar em saves importantes (fuel_entry_saver,
reminder_repository.create, etc) fire-and-forget.

### 4. iOS WidgetKit target
**ESTA PARTE É COMPLEXA E PODE PRECISAR DE CONFIGURAÇÃO MANUAL.**

Idealmente:
- Criar target "AutoLogWidget" no `ios/Runner.xcodeproj`
- Adicionar Swift WidgetBundle + Widget
- Compartilhar App Group entitlement
- Widget Swift lê `UserDefaults(suiteName: "group.com.oddcar.autolog")` e
  renderiza Text(headline) + Text(sub).

Se o Sonnet não conseguir editar Runner.xcodeproj programaticamente,
crie um README detalhado em `ios/AutoLogWidget/README.md` com passos
manuais pra Diretor seguir no Xcode.

### 5. Android (TODO/opcional)
Se sobrar tempo: AppWidgetProvider Kotlin + xml layout. Senão, anotar
TODO no spec e seguir só iOS.

### 6. Trigger refresh
`lib/features/fuel/fuel_entry_saver.dart` e `reminder_repository.dart`:
- Após cada save bem-sucedido, chamar
  `ref.read(homeWidgetServiceProvider).refresh(...)` fire-and-forget.

### 7. Tests Dart
- `test/features/home_widget/home_widget_service_test.dart` —
  helper pra calcular "próximo lembrete" + format de data.
  Real `HomeWidget.saveWidgetData` é mockável; sem teste do
  WidgetKit (Swift) na suite Dart.

## Critérios
- `flutter test` → 904 + ~5 novos
- `flutter analyze` → 0
- `flutter build ios --simulator --no-codesign` → OK (build base do
  app — widget target separado pode falhar build sem Xcode setup
  manual; aceitável)
- README detalhado se a config Xcode não couber automatizar.

## Não-objetivos
- Android (TODO se sobrar tempo).
- Múltiplos tamanhos de widget (só systemSmall).
- Deep link específico (tap abre o app na home — refinar depois).
