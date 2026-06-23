# Handoff pro Code — Texto invisível no diálogo "Confirmar restauração"

**Severidade:** 🔴 (usuário confirma restauração às cegas) · **Achado em:** 23/06/2026 (roteiro Ondas 1-3, Bloco 7.6)

## O bug
Settings → Backup completo → **Importar** → seleciona o JSON → abre o `AlertDialog` de confirmação **só com os botões Cancelar/Restaurar**. O título "Confirmar restauração" e a contagem do bundle (`X veículos, Y abastecimentos…`) **não aparecem** — corpo do diálogo em branco. O texto existe no widget (`backup_card.dart` L188-201), então é **cor de texto errada** (texto claro sobre fundo claro).

## Repro
1. Settings → role até **Backup completo** → **Exportar tudo** → Salvar em Arquivos.
2. **Importar** → escolhe o JSON salvo.
3. Diálogo abre: só "Cancelar"/"Restaurar" visíveis; título e contagem invisíveis.

## Causa raiz (encontrada)
Em `lib/core/design/app_theme.dart`, `buildLightTheme()`:

- A cor `AppColors.ink` é aplicada **só** ao `textTheme` do `base` via `.apply(bodyColor/displayColor)` (L92-95).
- Mas o `dialogTheme` referencia a variável **`textTheme` crua** (sem o `.apply`):

```dart
dialogTheme: DialogThemeData(
  backgroundColor: AppColors.surfaceRaised,   // claro
  ...
  titleTextStyle: textTheme.titleLarge,        // <- sem cor → default (claro)
  contentTextStyle: textTheme.bodyMedium,      // <- idem
),
```

Como `titleLarge`/`bodyMedium` aqui **não** recebem `AppColors.ink`, o texto sai na cor default (clara) sobre `surfaceRaised` (claro) = invisível. `AppBar` e outros componentes não sofrem porque setam cor explícita.

## Fix sugerido
Forçar a cor do texto no `dialogTheme` (light e dark):

```dart
// light
titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.ink),
contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.ink),

// dark (buildDarkTheme, mesmo bloco)
titleTextStyle: textTheme.titleLarge?.copyWith(color: _DarkColors.ink),
contentTextStyle: textTheme.bodyMedium?.copyWith(color: _DarkColors.ink),
```

## Atenção — pode afetar outros diálogos
Como é do `dialogTheme` global, **qualquer `AlertDialog`** que dependa do tema (sem cor inline) tem o mesmo problema. Vale varrer os `AlertDialog`/`showDialog` do app (ex.: confirmações de exclusão) e conferir título/conteúdo visíveis em tema claro **e** escuro.

## Como vou revalidar
Importar um backup e confirmar que o diálogo mostra "Confirmar restauração" + a contagem (X veículos, Y abastecimentos…) legível, em tema claro e escuro.
