# AutoLog — Design System (Tranche A: Foundation)

> Status: **Tranche A — foundation only.** Tokens, tipografia, tema global. Telas individuais ainda usam widgets default e serão redesenhadas em Tranche B.
> Implementação: `lib/core/design/tokens.dart`, `lib/core/design/typography.dart`, `lib/core/design/app_theme.dart`.
> Em conflito com `ARCHITECTURE.md`, a arquitetura vence. Em conflito com `PRD.md` em escopo, o PRD vence. Este doc rege **estética e linguagem visual**.

---

## 1. Voz e sensação visual

**O que AutoLog parece ser.** Um aplicativo brasileiro, moderno, sério com dinheiro mas sem cara de banco. A tese do produto é "tire uma foto, o app preenche o resto" — então a UI precisa transmitir **velocidade tranquila**: a sensação de que registrar um abastecimento é trivial, que os números estão sob controle, e que a complexidade fica do lado do código, não do usuário.

A referência mental não é Material/Google nem Apple stock — é a confiança visual dos apps fintech BR de segunda geração (Nubank, Will, C6), cruzada com a contenção tipográfica do Linear e a calidez de papel de algumas referências editoriais. Nada de azul corporativo genérico; nada de gradiente roxo de SaaS; nada de drop-shadow agressivo de Material 2. **Off-white quente, verde-tinta-de-bomba como marca, lima cítrica como acento de ação.**

**Personalidade em três palavras**: *confiante, calmo, brasileiro*. Confiante porque os números importam (km/l, R$/km, saldo de gasto mensal) e a UI nunca pode parecer hesitante. Calmo porque é um app de uso recorrente e baixa frequência (cada abastecimento ≈ 2 min), nunca ansioso. Brasileiro porque o público é, e as paletas frias de fintechs gringas não combinam — daí o off-white quase de papel reciclado, o verde "puxado" pra musgo, e o acento lima que lembra mais limonada no calor do que um terminal hacker.

---

## 2. Paleta

Toda cor vive em `AppColors` (`lib/core/design/tokens.dart`). Nenhum widget deve hardcodar `Color(0xFF...)` — sempre consumir o token.

### Marca

| Token | Hex | Uso |
|---|---|---|
| `brand` | `#0E1F1A` | Cor primária. Botões `FilledButton`, foco de input, texto de marca. **Esta é a cor "AutoLog".** |
| `brandSoft` | `#1B3A30` | Estado hover/pressed sobre brand; container de marca. |
| `brandInk` | `#EAF2EE` | Texto/ícone sobre fundo brand. |
| `accent` | `#C4F25C` | **Acento — uso parcimonioso.** FAB ("novo abastecimento"), botão "Escanear cupom", badges "novo". É o "vai" do app. Se aparecer em mais de 2 elementos visíveis ao mesmo tempo, está sendo abusado. |
| `accentInk` | `#0E1F1A` | Texto sobre accent. |

### Superfícies

| Token | Hex | Uso |
|---|---|---|
| `surface` | `#FAF7F2` | Fundo padrão de tela. Off-white levemente quente, ~3% bege. Não é branco gelado. |
| `surfaceRaised` | `#FFFFFF` | Cards, bottom sheets, dialogs — único lugar onde branco puro aparece. |
| `surfaceSunken` | `#F1ECE3` | Inputs, chips não-selecionados, skeleton states. |
| `surfaceInverse` | `#14241F` | Snackbars, tooltips. |

### Tinta

| Token | Hex | Uso |
|---|---|---|
| `ink` | `#14201C` | Texto principal, ícones em destaque. |
| `inkMuted` | `#55615C` | Subtítulos, metadados, labels secundários. |
| `inkSoft` | `#8A938E` | Placeholders, estados desabilitados. |
| `hairline` | `#E3DED3` | Bordas 1px, dividers — **default de separação** (em vez de sombra). |

### Semânticas

Calibradas para o off-white quente (não vivem bem sobre branco puro).

| Token | Hex | Quando usar |
|---|---|---|
| `success` / `successSoft` | `#1F7A4D` / `#E6F2EB` | Consumo bom, economia, sync OK. |
| `warning` / `warningSoft` | `#B8740B` / `#FBEFD8` | Lembrete vencendo, cota baixa. |
| `danger` / `dangerSoft` | `#B23A2F` / `#F6E1DD` | Erro, confirmação de exclusão. |
| `info` / `infoSoft` | `#2D5DA8` / `#E1EAF7` | Info passiva — raro, evitar. |

### Combustíveis (chips/ícones de tipo)

| Token | Hex | |
|---|---|---|
| `fuelGasoline` | `#B23A2F` | gasolina (vermelho-tijolo) |
| `fuelEthanol` | `#1F7A4D` | etanol (verde-cana) |
| `fuelDiesel` | `#8A6E2F` | diesel (âmbar-óleo) |
| `fuelFlex` | `#6B4FB8` | flex (roxo) |

### Acessibilidade
Contraste mínimo AA verificado para `ink`/`surface`, `brandInk`/`brand`, `accentInk`/`accent`. Cores semânticas têm versão soft (background) + sólida (texto/ícone) e devem sempre aparecer juntas (ex: chip de erro = `dangerSoft` fundo + `danger` texto).

---

## 3. Tipografia

**Pareamento**: `Bricolage Grotesque` (display) + `Manrope` (corpo). Ambas via `google_fonts: ^6.2.1`.

### Por que essas fontes (e não Inter/Roboto)

- **Bricolage Grotesque**: humanista grotesque variável com personalidade no peso 600/700. Os numerais têm "alma" — o `1` tem base, o `7` tem travessão — o que importa demais num app que vive de números. Acentos PT-BR (`ã`, `õ`, `ç`, `é`) renderizam limpos. É menos vista que Inter/Space Grotesk; dá identidade.
- **Manrope**: sans humanista geométrico com tabular figures naturais (R$ 1.234,56 alinha em colunas), `g` descendente que dá calor, e legibilidade excelente em 12-16px. Substitui o "Inter genérico" sem perder qualidade.

**Custo**: `google_fonts` baixa as fontes no primeiro start (~80kb cada, cached em disco). Impacto runtime irrisório. Justificável dado o ganho de identidade. Aprovado em `pubspec.yaml` com comentário.

### Escala (Material 3 completo)

Construída em `AppTypography.buildTextTheme()`. Todos os tamanhos em `sp`, line-heights em múltiplos, tracking ajustado por tamanho (display mais apertado, body neutro).

| Slot | Família | Tamanho | Peso | Line-height | Uso |
|---|---|---|---|---|---|
| `displayLarge` | Bricolage | 57 | 700 | 1.05 | Splash, hero numérico de paywall |
| `displayMedium` | Bricolage | 45 | 700 | 1.08 | "R$ 1.234" hero em relatórios |
| `displaySmall` | Bricolage | 36 | 600 | 1.10 | Big number em card de destaque |
| `headlineLarge` | Bricolage | 32 | 600 | 1.15 | Título de tela hero |
| `headlineMedium` | Bricolage | 28 | 600 | 1.20 | Título de seção principal |
| `headlineSmall` | Bricolage | 24 | 600 | 1.25 | Subtítulo de seção |
| `titleLarge` | Manrope | 20 | 600 | 1.30 | AppBar, título de dialog |
| `titleMedium` | Manrope | 16 | 600 | 1.35 | Título de card, list item primary |
| `titleSmall` | Manrope | 14 | 600 | 1.40 | Title denso |
| `bodyLarge` | Manrope | 16 | 400 | 1.50 | Parágrafo principal |
| `bodyMedium` | Manrope | 14 | 400 | 1.50 | Corpo padrão de UI |
| `bodySmall` | Manrope | 12 | 400 | 1.45 | Metadata, helpers (cor `inkMuted`) |
| `labelLarge` | Manrope | 14 | 600 | 1.20 | Texto de botão |
| `labelMedium` | Manrope | 12 | 600 | 1.20 | Chip, badge |
| `labelSmall` | Manrope | 11 | 600 | 1.20 | Overline, tag (cor `inkMuted`) |

### Estilos especiais

- `AppTypography.metric(size)` — Bricolage 700 com `tabularFigures` e tracking negativo, otimizado para **números de destaque** (km/l hero, R$ total do mês). Use direto em widgets de métrica.
- `AppTypography.tabular(base)` — wrap em qualquer style do textTheme para forçar tabular figures (listas com colunas de R$ alinhadas).

---

## 4. Espaçamento — grid de 4pt

`AppSpacing` em `tokens.dart`. Convenções:

| Token | px | Uso típico |
|---|---|---|
| `xs` | 4 | Gap ícone↔texto |
| `sm` | 8 | Padding interno de chip, gap entre itens de linha |
| `md` | 12 | Padding interno de input |
| `lg` | 16 | Padding-padrão de card e de tela |
| `xl` | 20 | Separação entre seções de formulário |
| `xxl` | 24 | Margem entre blocos visuais |
| `xxxl` | 32 | Topo/rodapé de tela, empty state |
| `huge` | 48 | Hero, headers |

---

## 5. Raios

Mais suaves que o default M3 (4/12/16), para um look menos "Google".

| Token | px | Uso |
|---|---|---|
| `sm` | 8 | Chips, badges, inputs (cantos pequenos) |
| `md` | 14 | Botões, cards |
| `lg` | 20 | Bottom sheets, dialogs, hero cards |
| `pill` | 999 | FAB, pílulas de status |

---

## 6. Elevação e sombras

**Princípio**: **default é flat.** Separação visual padrão = `hairline` (1px `#E3DED3`). Sombras só em elementos genuinamente flutuantes.

| Token | Uso |
|---|---|
| `none` | Cards normais, list items, app bar, inputs |
| `soft` (~4% black, 8px blur) | Card em destaque raro |
| `floating` (~8% black, 16px blur) | FAB, menus suspensos |
| `modal` (~12% black, 32px blur) | Dialogs, bottom sheets |

No tema, `Card` é configurado `elevation: 0` com `BorderSide(hairline)` em vez de sombra. O único elemento com sombra perceptível por default é o FAB.

---

## 7. Motion

Crisp, não bouncy. Brasileiros são tolerantes a animações ágeis, mas overshoot de spring dá ar de toy.

| Token | Duração | Uso |
|---|---|---|
| `fast` | 120ms | Estado de botão, ripple |
| `standard` | 180ms | Fade, slide curto, expand |
| `page` | 240ms | Transição entre rotas |

Curva default: `Curves.easeOutCubic`. Para entradas de elementos importantes (ex: card de scan recém-criado): `Curves.easeOutQuint`. **Nunca** `elasticOut` / `bounceOut`.

Page transitions configuradas no tema: `ZoomPageTransitionsBuilder` no Android (mais sutil que o default), `CupertinoPageTransitionsBuilder` no iOS (slide nativo).

---

## 8. Decisões propagadas no tema

`buildLightTheme()` em `app_theme.dart` configura, para que widgets default já saiam corretos sem custom code:

- **AppBar**: flat, transparente, `Bricolage`-based title em 20px/600, status bar com ícones escuros.
- **Card**: flat com hairline, raio 14, sem surfaceTint (M3 default polui com tint roxo-azulado).
- **FilledButton / OutlinedButton**: altura 52px (toque generoso), raio 14, peso 600.
- **FAB**: pílula, fundo `accent` lima, texto `brandInk`, sombra `floating`.
- **TextField**: fundo `surfaceSunken` (sem outline visível por default), foco com borda `brand` 2px. Sensação "papel embutido", não "caixa de formulário".
- **Chip**: pílula, fundo `surfaceSunken`, selecionado → `brand`.
- **Snackbar**: `surfaceInverse` (escuro), texto `brandInk`, ação em `accent`. Floating com raio 14.
- **Switch / Checkbox**: ativado = `brand`, sem outline esquisito.
- **Dialog / BottomSheet**: raio 20, `surfaceRaised`, drag handle hairline em sheets.
- **TabBar**: indicador `brand`, label-only (não fullWidth), sem overlay de ripple gritante.

---

## 9. Honestidade sobre trade-offs

- **`google_fonts` adiciona uma dep e ~160kb de download no primeiro start.** Aceito porque a identidade tipográfica é central; alternativa (`flutter_local_assets` com `.ttf` empacotados) aumentaria APK em ~400kb com pouco ganho. Se isso virar problema (cota de download da Play Store, área rural com 3G), trocamos para assets locais sem alterar o resto do sistema.
- **Verde-meia-noite + lima é uma aposta.** Foge do azul seguro, então existe risco de "não-default". Mitigado por: lima usada com parcimônia (FAB + scan CTA apenas), brand verde é escuro o suficiente para passar como neutro em contexto.
- **Cards sem sombra precisam de hairline visível.** Em telas com fundo `surfaceRaised` (branco), o hairline aparece bem. Em telas com fundo `surface` (off-white), o contraste do hairline é menor — aceitável porque cards nesse contexto têm fundo branco que contrasta com o off-white da tela.
- **Tabular figures requer um wrap manual** (`AppTypography.tabular` ou `metric`). Não dá para forçar global porque quebraria peso visual de texto não-numérico. A regra é: qualquer widget que mostra R$, km, l, datas com colunas — passa por `metric` ou `tabular`.
- **Tranche A não toca nenhuma tela.** Esperado: já vai *parecer* diferente só pelo tema (off-white em vez de cinza M3, Bricolage no título da AppBar, FAB lima em vez de azul, inputs sem borda dura, botões mais altos com raio maior). Mas a sensação só fecha quando Tranche B refizer telas com layout intencional (hero numérico em fuel_history, vehicle cards com decoração, paywall com display type, etc.).

---

## 10. Como usar (cheat sheet pra Tranche B)

```dart
// Cor: sempre via tema OU AppColors
Container(color: Theme.of(context).colorScheme.surface) // ✅
Container(color: AppColors.brand) // ✅
Container(color: Colors.green) // ❌

// Texto: sempre via textTheme OU AppTypography.metric
Text('Olá', style: Theme.of(context).textTheme.titleMedium) // ✅
Text('12.4 km/l', style: AppTypography.metric(28)) // ✅
Text('Olá', style: TextStyle(fontSize: 16)) // ❌

// Espaçamento: AppSpacing
SizedBox(height: AppSpacing.lg) // ✅
SizedBox(height: 16) // ❌

// Raio: AppRadius
BorderRadius: AppRadius.allMd // ✅
BorderRadius.circular(12) // ❌

// Sombra: AppShadows (default: nenhuma)
BoxDecoration(boxShadow: AppShadows.floating) // ✅
```

---

## 11. Pendências de asset visual (post-MVP)

### App icon — ainda é o default Flutter

O ícone do app no launcher (Android / iOS) ainda usa o ícone Flutter padrão.
Para substituir:

1. Gerar as variantes PNG a partir do `AppLogo` (glifo quadrado verde `#0E1F1A` + fundo
   lima `#C4F25C`, ou variante fundo escuro para tema adaptativo do Android 12+).
2. Adicionar `flutter_launcher_icons: ^0.14` ao `dev_dependencies` do `pubspec.yaml`.
3. Configurar no `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"         # 1024×1024 PNG
     adaptive_icon_background: "#C4F25C"             # lima (Android 12+)
     adaptive_icon_foreground: "assets/icon/app_icon_fg.png"
   ```
4. Rodar `dart run flutter_launcher_icons`.

Não implementado no MVP pois depende de asset PNG gerado em ferramenta de design.
O ícone não impacta a funcionalidade nem os testes.
