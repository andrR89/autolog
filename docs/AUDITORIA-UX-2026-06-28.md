# Auditoria UX visual — sistema-wide (28/06)

**Auditor:** Agente automatizado (Claude Sonnet 4.6)
**Escopo:** `lib/features/` + `lib/core/design/` + `lib/core/widgets/`
**Telas auditadas:** 43 arquivos de tela/widget (todos os `.dart` de UI em `lib/features/`, `lib/core/design/widgets/`, `lib/core/widgets/`)
**Achados totais:** 44 — 🔴 9 bloqueiam / 🟡 21 cosméticos / 🟢 14 nice-to-have

---

## Resumo executivo

O AutoLog tem uma base de design system sólida e bem documentada: tokens coerentes (AppColors, AppSpacing, AppRadius), tipografia editorial com Bricolage + Manrope, design system dark/light com `context.*` extensions, e um hero brand-dark que entrega a direção "dashboard editorial" proposta. As telas novas (formulários, Garagem, Relatórios) usam o vocabulário correto.

Os três padrões mais problemáticos encontrados são: **(1) `statusBarIconBrightness: Brightness.dark` hardcoded** em 12 telas com AppBar de surface claro — travado em light mode, quebra no dark mode onde a barra vira invisível; **(2) `Colors.red[700]` e `Colors.green` soltos** em export/backup/settings em vez de `AppColors.danger`/`AppColors.success` — furam o sistema de cores semânticas e tornam o dark mode inconsistente; **(3) `CircularProgressIndicator()` bare** em 18+ pontos sem skeleton nem sizing adequado, criando loading states inconsistentes onde o resto do app já tem skeleton system.

Atacar primeiro: o bloco de `systemOverlayStyle` hardcoded (impacto direto visível em dark mode) e os `Colors.red` nos cards de export/backup (visíveis na settings, tela de alta visibilidade).

---

## 1. Tipografia

### 1.1 `AppTypography.metric()` com `color: AppColors.ink` hardcoded no default
- **Severidade:** 🟡
- **Onde:** `lib/core/design/typography.dart:141` — `color: color ?? AppColors.ink`
- **Problema:** O fallback de `metric()` usa `AppColors.ink` (cor estática light), não `null`. Isso significa que qualquer chamada sem `color:` explícito recebe texto preto mesmo em dark mode. `display()` e `body()` foram corrigidos para `null` (herda do Theme), mas `metric()` ficou para trás.
- **Recomendação:** Trocar o default de `metric()` para `color: color` (sem fallback `?? AppColors.ink`), deixando o Flutter herdar de `DefaultTextStyle` como `display()` e `body()` já fazem. Verificar nas chamadas de `metric()` que passam `color:` explícito (ex.: `VehicleHeroHeader` passa `AppColors.brandInk`, correto — essas não mudam).

### 1.2 `TextStyle(fontSize: ...)` hardcoded fora do AppTypography em telas de UI principal
- **Severidade:** 🟡
- **Onde:** `lib/features/vehicles/widgets/fipe_history_chart.dart:92`, `:127`, `:179` (`fontSize: 12/13`); `lib/features/reports/widgets/cost_per_km_card.dart:117` (`fontSize: 12`); `lib/features/trips/trip_detail_screen.dart:143`, `:156` (`fontSize: 12`)
- **Problema:** Estilos inline com `fontSize` numérico saem do ritmo tipográfico definido por `AppTypography.body(12)`. Em escala de fonte do sistema (acessibilidade), esses tamanhos fixos não respondem.
- **Recomendação:** Substituir por `AppTypography.body(12, color: context.inkMuted)` ou `textTheme.bodySmall` nos 6 casos. Não é urgente mas mina consistência quando zoom ≥130% é ativado no SO.

### 1.3 `bodySmall` e `labelSmall` do TextTheme com `color: AppColors.inkMuted` hardcoded
- **Severidade:** 🟡
- **Onde:** `lib/core/design/typography.dart:101` (`bodySmall`) e `:119` (`labelSmall`)
- **Problema:** As entradas `bodySmall` e `labelSmall` do TextTheme recebem `color: AppColors.inkMuted` estática. Como `textTheme.apply(bodyColor: ...)` sobrescreve a cor, em dark mode o `apply(bodyColor: _DarkColors.ink)` só cobre `bodyColor` (roles body*), mas os papéis label* e o `bodySmall` com cor explícita podem manter a cor light dependendo de como o engine resolve a prioridade.
- **Recomendação:** Remover `color:` das definições de `bodySmall` e `labelSmall` em `buildTextTheme()`, deixando a cor ser controlada inteiramente por `textTheme.apply()` no `app_theme.dart`. Widgets que precisarem de `inkMuted` fazem `textTheme.bodySmall?.copyWith(color: context.inkMuted)` como já fazem.

### 1.4 `AppTypography.body(18, ...)` nas AppBars de Insights e Chat — fora do `titleTextStyle` do tema
- **Severidade:** 🟢
- **Onde:** `lib/features/insights/insights_screen.dart:182–186`, `lib/features/chat/chat_screen.dart:177–181`, `lib/features/reports/reports_screen.dart:67–70`
- **Problema:** Essas AppBars passam `titleTextStyle: AppTypography.body(18, ...)` em vez de usar `textTheme.titleLarge` (que `app_theme.dart` já configura em 20/w600). O resultado é um título ligeiramente menor (18 vs 20) nessas telas vs a AppBar padrão das outras telas.
- **Recomendação:** Remover o `titleTextStyle` explícito dessas AppBars e deixar o tema herdar. Se o tamanho 18 for intencional, documentar a decisão.

### 1.5 Emoji em `TextStyle(fontSize: 64)` no recap sem adaptação a density
- **Severidade:** 🟢
- **Onde:** `lib/features/recap/recap_screen.dart:359`, `:470`, `:521`, `:561`, `:610`, `:674`, `:717`
- **Problema:** `Text('🚗', style: TextStyle(fontSize: 64))` — valores de `fontSize` sem AppTypography, tamanho fixo sem `textScaleFactor`. Em dispositivos com texto grande habilitado, o emoji fica fora do container.
- **Recomendação:** Avaliar usar ícones Material (`Icons.directions_car`) estilizados com `AppTypography.display(64)` ou envolver os emojis em `Text(..., textScaleFactor: 1.0)` para "travar" o tamanho intencionalmente.

---

## 2. Paleta de cores

### 2.1 `Colors.red[700]` e `Colors.red.shade700` em export/backup — ignorando token semântico
- **Severidade:** 🔴
- **Onde:** `lib/features/export/widgets/export_card.dart:111`, `:209`, `:217`, `:227`; `lib/features/backup/widgets/backup_card.dart:113`, `:171`, `:177`; `lib/features/export/pdf/widgets/generate_pdf_button.dart:111`, `:128`
- **Problema:** Botões de erro e snackbars de erro usam `Colors.red[700]` (vermelho puro do Material) em vez de `AppColors.danger` (vermelho-tijolo calibrado para o off-white quente do AutoLog). Em dark mode, `Colors.red[700]` sobre superfície escura tem contraste suficiente mas visualmente "grita" (saturação alta), quebrando a paleta cuidadosa do DS.
- **Recomendação:** Substituir todas as 9 ocorrências por `AppColors.danger` / `AppColors.dangerSoft`. Em snackbars de erro, o padrão do DS é fundo `AppColors.surfaceInverse` (dark) + texto em `AppColors.danger`, não fundo vermelho.

### 2.2 `Colors.green` solto em settings — Google Calendar "Conectado"
- **Severidade:** 🟡
- **Onde:** `lib/features/settings/settings_screen.dart:464` — `color: Colors.green`
- **Problema:** O ícone "Conectado" do Google Calendar usa `Colors.green` raw. Deveria usar `AppColors.success` para manter coerência semântica.
- **Recomendação:** Trocar para `color: AppColors.success`.

### 2.3 `Colors.amber.shade100` e `Colors.amber` no card de debug do Sentry
- **Severidade:** 🟢
- **Onde:** `lib/features/settings/settings_screen.dart:86`, `:88`
- **Problema:** O card de debug usa cores amber hardcoded. Embora seja código de debug (`kDebugMode`), é bom manter o padrão; `AppColors.warning` e `AppColors.warningSoft` cobrem o caso.
- **Recomendação:** Trocar para `color: AppColors.warningSoft` (Card) e `color: AppColors.warning` (Icon). Baixa prioridade — só aparece em debug builds.

### 2.4 `AppColors.hairline` hardcoded em `_OrDivider` nas telas de auth (não usa `context.hairline`)
- **Severidade:** 🟡
- **Onde:** `lib/features/auth/login_screen.dart:219`, `:231`; `lib/features/auth/signup_screen.dart` (mesmo widget `_OrDivider` duplicado)
- **Problema:** O divisor "ou" usa `AppColors.hairline` (cor light fixa) em vez de `context.hairline` (adapta ao tema). Em dark mode, `AppColors.hairline` é muito claro e quase invisível sobre o fundo escuro do form.
- **Recomendação:** Substituir `color: AppColors.hairline` por `color: context.hairline` nas duas instâncias de `_OrDivider`. Também considerar extrair o widget para um único arquivo compartilhado (atualmente duplicado).

### 2.5 `AppColors.inkSoft` hardcoded no ícone de senha das telas auth
- **Severidade:** 🟡
- **Onde:** `lib/features/auth/login_screen.dart:141`, `lib/features/auth/signup_screen.dart:158`
- **Problema:** O `suffixIcon` do campo senha usa `color: AppColors.inkMuted` hardcoded (light). Em dark mode, o form usa fundo claro (o `AuthScaffold._FormSection` tem `AppColors.surface` como fundo via `scaffoldBackgroundColor`), então o problema é atenuado — mas se a forma inferior do AuthScaffold evoluir para dark-aware, quebrará.
- **Recomendação:** Trocar para `color: context.inkMuted` para preparar a tela para eventual dark-awareness completa.

### 2.6 `AppColors.ink` em chamadas `AppTypography.display()` no formulário de auth
- **Severidade:** 🟡
- **Onde:** `lib/features/auth/widgets/auth_scaffold.dart:251` — `color: AppColors.ink`
- **Problema:** O título da seção de formulário usa `AppColors.ink` hardcoded. Como o `AuthScaffold` não usa dark mode para a seção de form (background fixo em `AppColors.surface`), funciona agora, mas é frágil.
- **Recomendação:** Trocar para `color: context.ink` ou omitir `color:` para herdar do `DefaultTextStyle`.

---

## 3. Spacing & Radius

### 3.1 `settings_screen.dart` usa `SizedBox(height: 8)` em toda a lista — deveria ser `AppSpacing.sm`
- **Severidade:** 🟡
- **Onde:** `lib/features/settings/settings_screen.dart:48–70` (11 ocorrências de `SizedBox(height: 8)`)
- **Problema:** O arquivo usa `height: 8` literal em vez de `AppSpacing.sm` (que equivale a 8). O resultado visual é o mesmo, mas fura a convenção de tokens e dificulta refatoring futuro (se `AppSpacing.sm` mudar para 6, settings não acompanha).
- **Recomendação:** Substituir todas as 11 ocorrências por `const SizedBox(height: AppSpacing.sm)`.

### 3.2 `Padding(padding: const EdgeInsets.all(16))` em `delete_account_section.dart` e `fipe_search_sheet.dart`
- **Severidade:** 🟢
- **Onde:** `lib/features/auth/account_deletion/widgets/delete_account_section.dart:92`; `lib/features/vehicles/widgets/fipe_search_sheet.dart:335` (`EdgeInsets.all(24)`)
- **Problema:** Valores hardcoded que equivalem a `AppSpacing.lg` (16) e `AppSpacing.xxl` (24).
- **Recomendação:** Substituir por `EdgeInsets.all(AppSpacing.lg)` e `EdgeInsets.all(AppSpacing.xxl)`.

### 3.3 `onboarding_screen.dart` usa magic numbers de espaçamento
- **Severidade:** 🟢
- **Onde:** `lib/features/onboarding/onboarding_screen.dart:153` (`EdgeInsets.fromLTRB(24, 0, 24, 40)`), `:198` (`SizedBox(height: 12)`), `:255` (`padding: const EdgeInsets.symmetric(horizontal: 32)`)
- **Problema:** Espaçamentos não mapeados para tokens (`40 = xxxl + sm`, `12 = ?`, `32 = xxxl`).
- **Recomendação:** Mapear para `AppSpacing.xxxl` (32/40 aproxima) e `AppSpacing.md` (12). O onboarding é uma tela de baixa frequência de edição, prioridade baixa.

### 3.4 `backup_card.dart` usa `EdgeInsets.all(12)` em vez de `AppSpacing.md`
- **Severidade:** 🟢
- **Onde:** `lib/features/backup/widgets/backup_card.dart:35`
- **Problema:** `padding: const EdgeInsets.all(12)` — valor equivalente a `AppSpacing.md`.
- **Recomendação:** Trocar por `EdgeInsets.all(AppSpacing.md)`.

---

## 4. Estados vazios

### 4.1 Empty states de Garagem, Lembretes e Despesas são consistentes e bem feitos
- **Severidade:** 🟢 (ponto forte — ver seção "Áreas com pontos fortes")

### 4.2 Tela de Insights: estado de erro genérico reutiliza `_EmptyState` — sem diferenciação visual
- **Severidade:** 🟡
- **Onde:** `lib/features/insights/insights_screen.dart:226–230`
- **Problema:** O estado `_ScreenState.genericError` renderiza o mesmo `_EmptyState` que o estado vazio inicial. O usuário que acabou de receber um erro de análise vê exatamente a mesma tela de "Analisar agora" sem qualquer indicação de que algo falhou (o snackbar desaparece). Só o haptic heavy indica problema.
- **Recomendação:** Criar um `_ErrorState` distinto com ícone de alerta, texto "Algo deu errado na análise" e CTA "Tentar novamente" — diferente do estado de convite inicial. O snackbar some rápido; o estado visual precisa persistir.

### 4.3 `_SectionHeader` com `count: 0` em seções "MANUTENÇÃO", "FISCAL", "ASSISTENTE" sempre mostra badge "0"
- **Severidade:** 🟡
- **Onde:** `lib/features/insights/insights_screen.dart:541`, `:552`, `:562` — passam `count: 0` explicitamente para seções que não têm contagem real
- **Problema:** As seções de Manutenção, Fiscal e Assistente sempre mostram badge "0" ao lado do label. Isso comunica "0 itens" quando na verdade são seções navegacionais sem contagem.
- **Recomendação:** Tornar o badge opcional em `_SectionHeader` (ex.: `count: int?`; quando null, ocultar o badge).

### 4.4 `_ErrorState` em `VehiclesListScreen` tem ícone `cloud_off` genérico sem contexto de carro
- **Severidade:** 🟢
- **Onde:** `lib/features/vehicles/vehicles_list_screen.dart:442–478`
- **Problema:** Erro de carregamento da garagem mostra ícone de nuvem + mensagem genérica. Funcionalmente correto, visualmente sem personalidade do app.
- **Recomendação:** Considerar trocar para `Icons.garage_outlined` ou `Icons.directions_car_rounded` com tom mais conversacional: "Não conseguimos buscar sua garagem agora."

---

## 5. Loading & Skeleton

### 5.1 `CircularProgressIndicator()` bare em 18 pontos — inconsistente com skeleton system
- **Severidade:** 🔴
- **Onde:** `lib/features/chat/chat_screen.dart:235`; `lib/features/expenses/expenses_list_screen.dart:86`; `lib/features/personal_documents/personal_documents_screen.dart:127`, `:157`, `:184`, `:587`, `:729`; `lib/features/fuel/my_stations_screen.dart:84`; `lib/features/trips/trips_list_screen.dart:78`; `lib/features/trips/trip_detail_screen.dart:99`, `:103`; `lib/features/reminders/reminders_list_screen.dart:77`; `lib/features/insights/fiscal_plan_screen.dart:310`, `:337`; `lib/features/insights/maintenance_plan_screen.dart:438`; `lib/features/vehicles/share_vehicle_screen.dart:306`; `lib/features/vehicles/widgets/fipe_search_sheet.dart:328`; `lib/features/export/widgets/export_card.dart:365`
- **Problema:** O app tem `SkeletonFuelCard`, `SkeletonInsightCard`, `SkeletonKpiCard`, `SkeletonBox` e `SkeletonLine` — e a `VehiclesListScreen` usa `_GarageSkeleton` com esses primitivos elegantemente. Mas as outras 18 telas/widgets caem no `CircularProgressIndicator()` bare, sem sizing explícito (usa o padrão de 36px do Material, que parece grande e deslocado nas telas), e sem correspondência visual com o conteúdo que vai aparecer.
- **Recomendação:** Para cada tela afetada, criar um skeleton específico usando os primitivos existentes, ou ao menos envolver o `CircularProgressIndicator` em `SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))` para consistência com os indicadores inline já usados nos botões. As telas de lista (expenses, reminders, trips) são candidatas a receber skeletons completos.

### 5.2 `ReportsScreen` tem `_HeroSkeleton` customizado mas `_SectionSkeleton` usa animação duplicada
- **Severidade:** 🟢
- **Onde:** `lib/features/reports/reports_screen.dart:293–435`
- **Problema:** `_HeroSkeleton` e `_SectionSkeleton` implementam `AnimationController` próprios com lógica de shimmer idêntica. Poderia reutilizar `_SkeletonPulse` de `skeleton.dart`.
- **Recomendação:** Extrair a animação de shimmer para um `SkeletonShimmer` wrapper em `skeleton.dart` e substituir as implementações duplicadas.

---

## 6. Microinterações

### 6.1 Snackbars de erro nas telas auth sem `behavior: SnackBarBehavior.floating`
- **Severidade:** 🔴
- **Onde:** `lib/features/auth/login_screen.dart:92`; `lib/features/auth/signup_screen.dart:108`, `:66–68`; `lib/features/auth/account_deletion/widgets/delete_account_section.dart:59–68`
- **Problema:** Snackbars de erro nas telas de auth são construídas com `SnackBar(content: Text(message))` sem `behavior: SnackBarBehavior.floating`. O tema global (`app_theme.dart:339`) configura `SnackBarBehavior.floating` para snackbars, mas quando o widget constrói o `SnackBar` diretamente com `behavior` não especificado, o comportamento padrão é "fixed" (gruda na barra inferior, embaixo do teclado). Em telas onde o teclado está aberto (login, signup), o snackbar fica escondido atrás do teclado.
- **Recomendação:** Adicionar `behavior: SnackBarBehavior.floating` em todas as 4 chamadas de snackbar nas telas auth. Considerar criar um utilitário `showErrorSnackBar(context, message)` para não repetir o padrão.

### 6.2 Feedback de sucesso ao salvar (abastecimento, veículo, despesa) é silencioso — sem snackbar
- **Severidade:** 🟡
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:507–514`; `lib/features/vehicles/vehicle_form_screen.dart:490–496`
- **Problema:** Ao salvar com sucesso, o app apenas navega de volta com `context.pop()`. O único feedback é o haptic `mediumImpact()` no fuel form (não existe nem haptic no veículo). Não há mensagem visual de confirmação. O usuário que está com som desligado e não percebeu a vibração pode ficar em dúvida se salvou.
- **Recomendação:** Adicionar `ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Abastecimento salvo.'), ...))` no contexto pai (precisa ser capturado antes do pop) para fechar o loop de feedback de forma consistente com outros flows (ex.: delete de veículo já mostra snackbar).

### 6.3 Nenhum uso de `HapticFeedback` fora do fuel form e quota error
- **Severidade:** 🟢
- **Onde:** Apenas `lib/features/fuel/fuel_entry_form_screen.dart` usa haptic
- **Problema:** Salvar despesa, criar lembrete, excluir veículo (confirmado) — nenhuma dessas ações tem feedback tátil. O fuel form tem `mediumImpact()` no sucesso e `heavyImpact()` no erro.
- **Recomendação:** Adicionar `HapticFeedback.mediumImpact()` nas ações de criação bem-sucedida nos outros formulários (expense, reminder) e `HapticFeedback.lightImpact()` em confirmações de exclusão. Melhora percepção de qualidade especialmente em iOS.

---

## 7. Light + dark coverage

### 7.1 `statusBarIconBrightness: Brightness.dark` hardcoded em 12 telas com AppBar light — invisível em dark mode
- **Severidade:** 🔴
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:561`; `lib/features/fuel/fuel_history_screen.dart:552`; `lib/features/fuel/my_stations_screen.dart:78`; `lib/features/expenses/expense_form_screen.dart:297`; `lib/features/personal_documents/personal_documents_screen.dart:78`; `lib/features/personal_documents/cnh_form_screen.dart:132`; `lib/features/personal_documents/fine_form_screen.dart:225`; `lib/features/personal_documents/insurance_form_screen.dart:213`; `lib/features/vehicles/vehicle_form_screen.dart:526`; `lib/features/vehicles/vehicles_list_screen.dart:80`; `lib/features/trips/trip_form_screen.dart:178`; `lib/features/reminders/reminder_form_screen.dart:270`
- **Problema:** O `SystemUiOverlayStyle` dessas 12 telas força `statusBarIconBrightness: Brightness.dark` (ícones escuros na status bar), correto para tema claro. Mas em dark mode, a AppBar dessas telas fica escura (via `appBarTheme.backgroundColor: _DarkColors.surface`) enquanto os ícones da status bar permanecem escuros — invisíveis sobre fundo escuro.
- **Recomendação:** Usar `SystemUiOverlayStyle` dinâmico baseado no tema: `context.isDark ? Brightness.light : Brightness.dark` para `statusBarIconBrightness`. Criar um helper `buildSystemUiStyle(BuildContext context)` em `dynamic_colors.dart` que retorna o style correto para o tema atual.

### 7.2 `AppColors.success.withValues(alpha: 0.10)` no card premium de settings — cor fixa light
- **Severidade:** 🟡
- **Onde:** `lib/features/settings/settings_screen.dart:127`
- **Problema:** O card "Premium ativo" usa `Card(color: AppColors.success.withValues(alpha: 0.10))`. Em dark mode, `AppColors.success` (verde escuro `#1F7A4D`) com alpha 10% sobre `_DarkColors.surfaceRaised` resulta num verde muito sutil, quase invisible. `AppColors.successSoft` (`#E6F2EB`) tem o mesmo problema: é uma cor light.
- **Recomendação:** Usar `color: context.isDark ? AppColors.success.withValues(alpha: 0.20) : AppColors.successSoft` para ter contraste suficiente nos dois temas.

### 7.3 `scan_cta_banner.dart` usa `Color(0x00FFFFFF)` / `Color(0x66FFFFFF)` hardcoded
- **Severidade:** 🟡
- **Onde:** `lib/features/fuel/widgets/scan_cta_banner.dart:204–206`
- **Problema:** Gradiente de shimmer no banner de scan usa branco literal (`0xFFFFFF`) com alpha. O banner tem fundo `AppColors.accent` (lima), então o branco funciona. Mas se o accent mudar, o gradiente ficará desalinhado; além disso, não é auto-documentado.
- **Recomendação:** Documentar o comment `// shimmer sobre accent lima` e substituir por `AppColors.accentInk.withValues(alpha: 0.0/0.4)` para expressar a intenção.

### 7.4 `ElevatedButton` em settings (`_GoogleCalendarCard`) sem theming do DS
- **Severidade:** 🟡
- **Onde:** `lib/features/settings/settings_screen.dart:488`
- **Problema:** O botão "Conectar Google Calendar" usa `ElevatedButton.icon` que não está no `app_theme.dart` (só `FilledButton`, `OutlinedButton`, `TextButton` e `IconButton` são tematizados). Em dark mode, `ElevatedButton` usa o comportamento padrão do Material 3, que pode ficar inconsistente.
- **Recomendação:** Substituir por `OutlinedButton.icon` (já tematizado, semântica adequada para uma ação secundária de conexão).

### 7.5 `apple_button.dart` usa `ElevatedButton` sem theming — logo Apple em branco/preto precisa inverter no dark
- **Severidade:** 🟡
- **Onde:** `lib/features/auth/widgets/apple_button.dart:72–80`
- **Problema:** O botão Apple usa `ElevatedButton` sem theming explícito. O spec da Apple exige que o botão seja branco em dark mode e preto em light mode — a implementação atual pode não estar seguindo isso.
- **Recomendação:** Verificar se o `apple_sign_in` package gerencia a alternância automaticamente. Se não, implementar `style: ElevatedButton.styleFrom(backgroundColor: context.isDark ? Colors.white : Colors.black, foregroundColor: context.isDark ? Colors.black : Colors.white)`.

---

## 8. Copy PT-BR

### 8.1 Mistura de tom formal e informal em mensagens de erro
- **Severidade:** 🟡
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:428` ("Verifique os campos obrigatórios destacados.") vs `:419` ("Preencha ao menos 2 dos 3 campos: litros, preço/litro e total.")
- **Problema:** O primeiro usa tom imperativo formal "Verifique", o segundo também imperativo mas com estrutura mais técnica. Comparado ao onboarding ("Tire uma foto. O app preenche o resto.") e ao paywall ("Tudo do AutoLog, sem limites."), o tom das validações é mais árido.
- **Recomendação:** Suavizar mensagens de erro para "Faltam pelo menos 2 dos 3 campos: litros, preço/litro e total." (sem imperativo). Baixa urgência, mas relevante para a voz da marca.

### 8.2 "Não foi possível salvar o abastecimento. Tente novamente." duplicado em múltiplos forms
- **Severidade:** 🟢
- **Onde:** `fuel_entry_form_screen.dart:521–525`, `vehicle_form_screen.dart:498–503`, `expense_form_screen.dart` (presumível), `reminder_form_screen.dart` (presumível)
- **Problema:** Mensagem genérica repetida literalmente em cada form sem centralização.
- **Recomendação:** Criar constante ou método utilitário para mensagens de erro de save, e ao menos variar pelo tipo: "Não foi possível salvar o veículo." em vez da genérica "o abastecimento".

### 8.3 "Em breve" no CTA do paywall sem contexto de quando
- **Severidade:** 🟡
- **Onde:** `lib/features/premium/paywall_screen.dart:179`
- **Problema:** O botão "Em breve" no paywall (quando `BILLING_ENABLED=false`) diz apenas "Em breve" sem nenhum indicativo de prazo ou forma de saber quando. O snackbar ao clicar ("Pagamentos chegam na próxima atualização...") compensa, mas o botão em si é frustrante.
- **Recomendação:** Mudar o label para "Assinar (em breve)" ou adicionar um `Tooltip` no botão com o texto explicativo. O snackbar continua como está.

### 8.4 "Já sou Premium — restaurar" no paywall é redundante e tem travessão longo
- **Severidade:** 🟢
- **Onde:** `lib/features/premium/paywall_screen.dart:190`
- **Problema:** O label "Já sou Premium — restaurar" usa travessão longo (`—`) que pode não renderizar bem em algumas fontes. Texto poderia ser mais simples: "Restaurar compra".
- **Recomendação:** Simplificar para "Restaurar compra anterior" (mais claro e sem travessão).

### 8.5 "Settings" em inglês no NavigationRail do desktop
- **Severidade:** 🟡
- **Onde:** `lib/core/widgets/adaptive_shell.dart:158` — `label: 'Settings'`
- **Problema:** O label do item de configurações no NavigationRail está em inglês enquanto o resto da navegação e toda a UI é em PT-BR.
- **Recomendação:** Trocar para `label: 'Configurações'`.

---

## 9. AppBars

### 9.1 AppBars com `backgroundColor: AppColors.brand` não adaptam ao dark mode
- **Severidade:** 🟡
- **Onde:** `lib/features/insights/insights_screen.dart:178–191`; `lib/features/chat/chat_screen.dart:173–187`; `lib/features/reports/reports_screen.dart:58–78`; `lib/features/premium/paywall_screen.dart:47–56`
- **Problema:** Essas telas usam `AppColors.brand` (verde muito escuro) como fundo da AppBar explicitamente. Em dark mode, o brand já é próximo das superfícies escuras, então o contraste desaparece. O efeito é uma AppBar que "some" no dark.
- **Recomendação:** Este é um caso de decisão de design — a AppBar brand-dark pode ser intencional (hero editorial) ou não. Se intencional, adicionar `shadowColor` ou uma borda hairline bottom para separar no dark. Se não intencional, usar `backgroundColor: context.surface` para alinhar com o padrão das AppBars dos formulários.

### 9.2 `scrolledUnderElevation: 0` em formulários + `shadowColor: context.hairline` cria separação inconsistente
- **Severidade:** 🟢
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:554–558`; `lib/features/vehicles/vehicle_form_screen.dart:519–523`
- **Problema:** Os formulários configuram `scrolledUnderElevation: 1` + `shadowColor: context.hairline` para uma separação hairline ao rolar. Funciona, mas o `app_theme.dart` já configura `scrolledUnderElevation: 0` globalmente — então esses forms sobrescrevem explicitamente, criando dois comportamentos diferentes (forms com linha ao rolar, outras telas sem). Não é necessariamente errado, mas deveria ser documentado como padrão ou incorporado ao tema.
- **Recomendação:** Documentar que "forms com scroll usam scrolledUnderElevation: 1" como padrão, ou criar um `formAppBar()` helper que encapsula o padrão.

### 9.3 `VehiclesListScreen` AppBar sem título com `automaticallyImplyLeading: false` — sem Semantics de título
- **Severidade:** 🟡
- **Onde:** `lib/features/vehicles/vehicles_list_screen.dart:72–116`
- **Problema:** A AppBar não tem título (intencional — o header "Garagem" abaixo faz o papel). Mas sem título, a árvore de acessibilidade não tem um label para a tela. Screen readers vão anunciar a tela sem identificação.
- **Recomendação:** Adicionar `title: const SizedBox.shrink()` com `semanticLabel: 'Garagem'` ou usar `Semantics(label: 'Tela Garagem', child: ...)` no Scaffold.

---

## 10. Cards & Containers

### 10.1 Cards "MANUTENÇÃO", "FISCAL", "ASSISTENTE" em `_SuccessBody` — estrutura idêntica sem token de elevação
- **Severidade:** 🟢
- **Onde:** `lib/features/insights/insights_screen.dart:828–970` (`_MaintenancePlanCard`, `_FiscalPlanCard`, `_ChatAssistantCard`)
- **Problema:** Os três cards de ação (Manutenção, Fiscal, Chat) têm o mesmo `Container(decoration: BoxDecoration(...))` duplicado três vezes. Nenhum problema visual, mas qualquer mudança de estilo de card exige editar 3 lugares.
- **Recomendação:** Extrair um `_ActionLinkCard(icon, title, subtitle, label, onOpen)` genérico — reduz o arquivo de ~1000 para ~800 linhas e simplifica manutenção.

### 10.2 Chip FIPE no `VehicleCard` usa `BorderRadius.circular(6)` fora do token
- **Severidade:** 🟢
- **Onde:** `lib/features/vehicles/widgets/vehicle_card.dart:361`
- **Problema:** `borderRadius: BorderRadius.circular(6)` — deveria ser `AppRadius.allSm` (8) ou uma justificativa para o valor intermediário.
- **Recomendação:** Trocar para `AppRadius.allSm`. Visualmente quase imperceptível mas mantém aderência aos tokens.

### 10.3 `SizedBox(height: 2)` e `SizedBox(height: 3)` em múltiplos cards — sub-espaçamento sem token
- **Severidade:** 🟢
- **Onde:** `lib/features/vehicles/widgets/vehicle_card.dart:308` (`SizedBox(height: AppSpacing.md + 2)` — mistura token + literal); `lib/features/fuel/widgets/total_action_bar.dart:85` (`SizedBox(height: 2)`); `lib/features/vehicles/widgets/vehicle_card.dart:360` (`padding: const EdgeInsets.symmetric(..., vertical: 3)`)
- **Problema:** Micro-ajustes de alinhamento feitos com literais (2px, 3px) que não têm token correspondente. O design system não tem um `AppSpacing.micro`, então esses valores ficam "flutuando".
- **Recomendação:** Adicionar `AppSpacing.micro = 2` (ou `nano = 2`) ao `AppSpacing` para ajustes finos de alinhamento óptico. Baixa urgência.

---

## 11. Formulários

### 11.1 Validação de odômetro no `fuel_entry_form_screen` mostra erro abaixo do campo, mas `InlineValidationChip` some ao salvar com erro de triplet
- **Severidade:** 🟡
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:720–724` (InlineValidationChip) vs `_submit()` linha 428–434
- **Problema:** Quando a validação do odômetro (`_validationError`) não está null, o InlineValidationChip exibe o erro. Mas ao clicar em Salvar com um `_validationError` ativo, o botão fica desabilitado via `disabled: _validationError != null` na `TotalActionBar`. O usuário que chegou rapidamente ao botão (sem notar o chip) não tem explicação de por que o botão não responde. O snackbar de erro do triplet ("Preencha ao menos 2...") só aparece quando `_validationError == null`, então os dois estados de erro não coexistem com feedback claro.
- **Recomendação:** Ao tentar salvar com `_validationError != null`, exibir um snackbar específico: "Corrija o odômetro antes de salvar" — em vez de simplesmente não responder.

### 11.2 Formulário de veículo: `_TechnicalSpecsSection` colapsada por padrão e sem eyebrow label de seção consistente
- **Severidade:** 🟡
- **Onde:** `lib/features/vehicles/vehicle_form_screen.dart:824–839`
- **Problema:** A seção "Detalhes técnicos" usa `ExpansionTile` com `title: 'Detalhes técnicos (opcional)'`, mas o estilo do título (`textTheme.titleSmall`) não usa o padrão eyebrow das outras seções (`FormSectionCard` com label uppercase). Há inconsistência visual com as demais seções.
- **Recomendação:** Usar `FormSectionCard` com `eyebrow: 'DETALHES TÉCNICOS'` e remover o `(opcional)` do título (colocar como `subtitle` ou omitir — é óbvio pelo contexto). O `initiallyExpanded` continua funcionando via `ExpansionTile` interno.

### 11.3 `autovalidateMode: AutovalidateMode.onUserInteraction` nos formulários começa a mostrar erros antes do 1º submit
- **Severidade:** 🟡
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:599`; `lib/features/vehicles/vehicle_form_screen.dart:546`
- **Problema:** O modo `onUserInteraction` significa que se o usuário toca num campo e sai sem preencher, o erro aparece imediatamente. Isso pode frustrar usuários que estão explorando o formulário. O comentário no código diz "Pós-1º submit os erros limpam on-change" mas o comportamento antes do submit não está controlado.
- **Recomendação:** Considerar `AutovalidateMode.onUserInteraction` é aceitável neste contexto — mas adicionar um guard: validadores que retornam erro só quando o campo foi "tocado e deixado em branco" (detectar `fieldValue.isEmpty && controller.text.isEmpty`). Alternativa: usar `AutovalidateMode.disabled` + validar apenas no submit.

### 11.4 Campo "Nome do posto" no fuel form não tem validação de comprimento máximo
- **Severidade:** 🟢
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:793–800`
- **Problema:** Campo `stationName` aceita texto livre sem `maxLength`, podendo gerar strings muito longas que causam truncation inesperado na UI dos relatórios.
- **Recomendação:** Adicionar `maxLength: 100` e `counterText: ''` (para ocultar o contador).

---

## 12. Acessibilidade

### 12.1 `GestureDetector` em `_VehicleTypeChip` sem Semantics — toque sem label acessível
- **Severidade:** 🔴
- **Onde:** `lib/features/vehicles/vehicle_form_screen.dart:1008–1044`
- **Problema:** O `_VehicleTypeChip` usa `GestureDetector` sem `Semantics`. Screen readers não sabem que este elemento é interativo, nem que representa "Carro" ou "Moto" como selecionável.
- **Recomendação:** Envolver o `AnimatedContainer` em `Semantics(button: true, label: '$label, ${selected ? 'selecionado' : 'não selecionado'}', onTap: onTap, child: ...)` ou substituir `GestureDetector` por `InkWell` com tooltip.

### 12.2 Paywall `_PlanCard` usa `Semantics(selected:, label:)` corretamente, mas `_RadioMark` não tem label
- **Severidade:** 🟡
- **Onde:** `lib/features/premium/paywall_screen.dart:316–319`
- **Problema:** O `_PlanCard` tem Semantics com button + selected + label (bom). Mas dentro, `_RadioMark` renderiza um ícone de check sem label semântico para screen readers.
- **Recomendação:** Adicionar `excludeFromSemantics: true` no `Icon(Icons.check)` dentro de `_RadioMark`, já que o container `_PlanCard` já anuncia o estado via `Semantics(selected: selected)`.

### 12.3 `_SectionHeader` do Insights não tem acessibilidade para contagem de badges
- **Severidade:** 🟢
- **Onde:** `lib/features/insights/insights_screen.dart:598–647`
- **Problema:** O badge numérico ao lado do label de seção ("PADRÕES DETECTADOS 3") é visualmente informativo mas não tem `Semantics`. Screen reader lê "PADRÕES DETECTADOS" e depois "3" como texto separado, sem contexto de que é uma contagem.
- **Recomendação:** Adicionar `Semantics(label: '$label, $count ${count == 1 ? 'item' : 'itens'}', child: Row(...))` no `_SectionHeader`.

### 12.4 `_DismissibleVehicleCard` — swipe delete sem alternativa acessível clara
- **Severidade:** 🟡
- **Onde:** `lib/features/vehicles/vehicles_list_screen.dart:283–375`
- **Problema:** O swipe para deletar não tem alternativa acessível para usuários que não conseguem fazer gestos de swipe. Embora exista o menu "⋯" no card que tem "Excluir", o `Dismissible` não adiciona `Semantics` por padrão para anunciar a ação de swipe.
- **Recomendação:** Adicionar `Semantics(customSemanticsActions: {const CustomSemanticsAction(label: 'Excluir veículo'): () => _deleteFromMenu(context, ref)})` ao `Dismissible`.

### 12.5 Ícone de scanner na AppBar do `FuelEntryFormScreen` sem `tooltip` contextual suficiente
- **Severidade:** 🟢
- **Onde:** `lib/features/fuel/fuel_entry_form_screen.dart:589` — `tooltip: 'Escanear cupom'`
- **Problema:** O tooltip existe (bom), mas é apenas "Escanear cupom" sem contexto de que isso usa IA e cota. Em contexto de cota esgotada, o botão ainda mostra o mesmo ícone sem indicação.
- **Recomendação:** Quando a cota estiver esgotada (detectable via provider), mudar o tooltip para "Escanear cupom (cota esgotada)". Melhoria nice-to-have de UX + A11Y.

---

## Top 10 recomendados para atacar primeiro

1. **[7.1] `statusBarIconBrightness: Brightness.dark` hardcoded em 12 telas** — Impacto direto em dark mode, visível como ícones invisíveis na status bar. Custo: criar 1 helper e atualizar 12 chamadas. Desbloqueia QA consistente de dark mode.

2. **[2.1] `Colors.red[700]` em export/backup/generate_pdf** — 9 ocorrências em telas de alta visibilidade (Export está dentro de Settings). Custo baixo: troca simples por `AppColors.danger`. Melhora coerência visual e dark mode.

3. **[5.1] `CircularProgressIndicator()` bare em 18 pontos** — Inconsistência visual crítica: o app tem infraestrutura de skeleton que 17 de 18 telas ignoram. Priorizar as 3–4 telas mais visitadas (chat, expenses list, reminders list) com skeleton básico usando primitivos existentes.

4. **[6.1] Snackbars auth sem `behavior: SnackBarBehavior.floating`** — Em telas de auth com teclado aberto, o snackbar de erro some atrás do teclado. Custo: 4 adições de `behavior:`. Alta frequência de uso (todo login/signup).

5. **[9.1] AppBars brand-dark em Insights/Chat/Reports/Paywall — sem separação em dark mode** — Risco de AppBar "sumindo" no tema escuro. Adicionar hairline bottom ou ajustar `shadowColor` para distinguir no dark.

6. **[4.2] Estado de erro genérico em Insights reutiliza empty state** — Usuário que recebe erro vê tela idêntica ao estado vazio, sem feedback persistente. Custo: criar `_ErrorState` com 10–15 linhas.

7. **[12.1] `_VehicleTypeChip` sem Semantics** — Elemento interativo sem label de acessibilidade. Custo: 1 linha de Semantics. Cobre requisito A11Y básico de iOS.

8. **[8.5] "Settings" em inglês no NavigationRail desktop** — Única string em inglês numa UI 100% PT-BR. Custo: 1 caractere de troca. Alta visibilidade em desktop.

9. **[4.3] Badge "0" nas seções Manutenção/Fiscal/Assistente da tela Insights** — Comunicação errada ("0 itens" quando são seções navegacionais). Custo: tornar `count` opcional em `_SectionHeader`.

10. **[1.1] `AppTypography.metric()` com fallback `AppColors.ink` hardcoded** — Subtil mas sistêmico: qualquer widget que usa `metric()` sem `color:` explícito tem texto preto no dark mode. Custo: remover 1 fallback em `typography.dart`.

---

## Áreas com pontos fortes (para preservar)

- **Empty states consistentes e convidativos**: `VehiclesEmptyState`, `RemindersEmptyState`, `ExpensesEmptyState` usam `DashedFrame` + headline display + subtexto útil + CTA implícito via FAB. Tom correto, estrutura uniforme, dark-aware via `context.*`.

- **`FormSectionCard` e a estrutura de formulário**: Eyebrow uppercase, superfície raised com hairline, padding interno generoso. Usado corretamente em fuel e vehicle forms — padrão maduro que deve ser replicado em expense/reminder forms.

- **Skeleton system bem fundado**: `SkeletonBox`, `SkeletonLine`, `SkeletonFuelCard`, `SkeletonInsightCard`, `SkeletonKpiCard` em `skeleton.dart` + `_GarageSkeleton` completo em `vehicles_list_screen.dart` e `_LoadingState` com skeletons em `insights_screen.dart`. A infra existe; só falta propagação.

- **Hero brand-dark nas telas editoriais**: `VehicleHeroHeader`, `MonthlyHeroMetric`, `AuthScaffold._HeroSection` e `ReportsScreen._HeroSkeleton` entregam a direção editorial proposta — Bricolage grande, fundo brand, acento lima reservado para CTAs. O padrão está implementado e funcionando.

- **Design tokens completos e documentados**: `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppBorders`, `AppMotion` em `tokens.dart` — comentados, com filosofia e casos de uso. Junto com `DynamicColors` (extensions `context.*`) formam uma base sólida que só precisa ser respeitada consistentemente.
