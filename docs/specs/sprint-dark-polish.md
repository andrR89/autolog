# Polish — Dark mode 100%

> Continua o fix anterior (Scaffolds). Agora cards/containers/inputs
> que ainda usam `AppColors.surfaceRaised`/`surfaceSunken` hardcoded
> precisam ler do Theme pra ficar dark-aware.

## Estratégia
Pragmática: criar helpers contextual em `lib/core/design/dynamic_colors.dart`:
```dart
extension DynamicColors on BuildContext {
  Color get surface => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceRaised => Theme.of(this).cardTheme.color ?? ...;
  Color get surfaceSunken => Theme.of(this).colorScheme.surfaceContainerLow;
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get inkMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get hairline => Theme.of(this).dividerColor;
}
```

Refatorar widgets críticos pra usar `context.surfaceRaised` em vez de
`AppColors.surfaceRaised`. Não TODOS — só os ~10-15 widgets mais visíveis:
- Cards de reports (cost_per_km_card, trend_card, favorite_station_card, co2_card)
- Cards de insights (FipeHistoryChart, plan_card etc)
- Form section cards
- AppBar de tela escura (manter brand-color, ok)

Texto também: trocar `color: AppColors.ink` → `context.ink` nas mesmas
áreas.

## Critérios
- Suite verde
- analyze 0
- Cards principais em dark mode mostram corretamente
- Polish "100% do app dark" fica TODO eterno; foco no que é visível na
  navegação principal.

## Não-objetivos
- Refatorar 100% das 200+ referências de AppColors (overhead).
- Onboarding/auth screens (sempre claros por design).
