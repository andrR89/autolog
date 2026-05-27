# Sprint 6.AA — Dark mode

> Sistema visual paralelo escuro. Toggle persistido.

## Decisões
- Não usar `Theme.of(context).brightness` direto — criar `AppColors.of(context)` que retorna `LightPalette` ou `DarkPalette`.
- Persistir preferência via Drift (nova mini-tabela `UserSettings` PK userId).
- Toggle 3-way: System / Light / Dark.
- Cor de marca preservada em ambos (verde-meia-noite continua brand).
- Adicionar tela `SettingsScreen` (não existia ainda — também serve pra 6.W.4 futuro).

## Mudanças

### 1. Palette dual
`lib/core/design/tokens.dart`:
- Manter `AppColors` atual como `LightPalette`.
- Criar `DarkPalette` com inversões inteligentes (surface → ink, surfaceRaised → surfaceRaisedDark, etc).
- Função `palette(BuildContext)` que retorna correta baseada em `Theme.of(context).brightness`.

PRAGMÁTICO: pra esta sprint, criar `AppColorsDark` paralela e usar `Theme.of(context).colorScheme` derivada disso. Telas que usam `AppColors.surface` diretamente continuam funcionando porque vamos definir cores no Theme.

Abordagem mais simples e efetiva:
- Manter `AppColors` como está (não trocar 200 referências).
- Criar `buildDarkTheme()` que mapeia cores dark equivalentes via `ColorScheme.dark`.
- Telas migram opcionalmente (foco no Scaffold/AppBar/cards principais).
- Aceitar que algumas telas ficam "estilo claro" no MVP do dark — UX polish posterior.

### 2. ThemeMode persistido
`lib/data/local/tables.dart`:
```dart
@DataClassName('UserSettingsRow')
class UserSettings extends Table {
  TextColumn get userId => text()();
  TextColumn get themeMode => text().withDefault(const Constant('system'));
  // adicionar mais flags futuras aqui (notif prefs etc)
  @override
  Set<Column> get primaryKey => {userId};
}
```

Schema v12. Migration `if (from < 12) { createTable(userSettings); }`.

### 3. Settings screen
`lib/features/settings/settings_screen.dart`:
- AppBar "Configurações"
- ListTile com SwitchListTile pra ThemeMode com 3 opções (System/Light/Dark).
- (Futuro 6.W.4): switches de notif por categoria.

Provider `themeModeProvider` lê da tabela, expõe AsyncValue<ThemeMode>.

### 4. Entry point Settings
Adicionar item no menu/drawer principal pra `/settings`. Verificar onde tem menu (provavelmente `vehicles_list_screen` ou home).

### 5. Aplicar themeMode em MaterialApp.router
`lib/app.dart`: `MaterialApp.router(themeMode: ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system, theme: AppTheme.light, darkTheme: AppTheme.dark)`.

`AppTheme.dark`: ColorScheme.dark com brand verde preservado, surface escuro (#101816 ou similar), surfaceRaised mais claro, ink claro.

## Testes
- `test/features/settings/theme_mode_persistence_test.dart` — persistência via Drift mock.
- `test/data/local/user_settings_schema_v12_test.dart` — schema bump.

## Não-objetivos
- Refator de TODAS as telas pra usar ThemeOf<ColorScheme>. Foco: Scaffold/AppBar/Cards principais funcionarem em dark; resto polish posterior.
- Tema acompanha sistema automaticamente sem precisar tocar (default System).

## Critérios
- Suite verde (799+ + ~10 novos)
- analyze 0, iOS build OK
