# Handoff pro Code — Contraste dos ícones na AppBar de Relatórios

**Severidade:** 🟡 Baixo (visual, não bloqueia) · **Achado em:** 19/06/2026 (revalidação de fidelidade UX)

## O bug
Na tela **Relatórios** (AppBar com `backgroundColor: AppColors.brand`, verde), o **título "Relatórios" e a seta de voltar** aparecem em tom claro (`brandInk`), **mas os dois ícones de `actions`** — "Comparar período" (`compare_arrows_rounded`) e o Recap (`_RecapMenuAction`, ✨) — **saem num tom escuro quase igual ao fundo verde**, ficando praticamente invisíveis.

Resultado: parece que os botões "sumiram". Eles **estão lá e funcionam** (tocar no canto abre normalmente a tela "Comparar período"), só não dá pra ver.

## Repro
1. Abrir um veículo → AppBar → "…" → **Relatórios** (ou ícone de relatórios).
2. Olhar o canto superior direito da AppBar verde.
3. Os ícones ⇄ e ✨ estão lá, mas quase imperceptíveis contra o verde.

## Causa provável
Os `IconButton` dentro de `actions:` não estão herdando o `foregroundColor` / `iconTheme` (`brandInk`) do `AppBar`. Arquivo: `lib/features/reports/reports_screen.dart` (~L56–83).

```dart
appBar: AppBar(
  backgroundColor: AppColors.brand,
  foregroundColor: AppColors.brandInk,
  iconTheme: const IconThemeData(color: AppColors.brandInk),
  ...
  actions: [
    IconButton(
      tooltip: 'Comparar período',
      icon: const Icon(Icons.compare_arrows_rounded), // <- herda cor errada
      ...
    ),
    const _RecapMenuAction(), // <- idem (checar a cor do ícone dentro do widget)
  ],
),
```

## Fix sugerido
Forçar a cor dos ícones de ação para `AppColors.brandInk` (mesmo tom do título/voltar). Ex.: `icon: Icon(Icons.compare_arrows_rounded, color: AppColors.brandInk)` e garantir o mesmo dentro de `_RecapMenuAction`. Ou definir `actionsIconTheme: const IconThemeData(color: AppColors.brandInk)` no `AppBar`.

## Como vou revalidar
Abrir Relatórios e confirmar que os dois ícones (⇄ e ✨) ficam visíveis no mesmo tom claro do título.
