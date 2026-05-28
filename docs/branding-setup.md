# Branding Setup — AutoLog

## Estado atual

| Item | Status |
|------|--------|
| `flutter_launcher_icons ^0.14.4` | Configurado no `pubspec.yaml` |
| `flutter_native_splash ^2.4.7` | Configurado + **splash gerado** |
| Splash cor sólida `#0E1F1A` (iOS + Android) | **Ativo agora** |
| Launcher icon | Aguardando PNGs — **não rodar ainda** |

A splash screen de cor sólida verde-meia-noite (`#0E1F1A`) já está compilada.
O launcher icon ainda exibe o ícone padrão do Flutter até que os assets sejam criados.

---

## Assets necessários

Todos os PNGs devem ter **1024 × 1024 px**, fundo transparente onde indicado.

### `assets/branding/app_icon.png`
- **Full bleed** (sem transparência, cobre tudo).
- Fundo: brand `#0E1F1A` (verde-meia-noite).
- Elemento central: "AL" em accent lima `#C4F25C`, fonte Bricolage Grotesque Bold, centralizado.
- Usado como ícone iOS e como fallback Android (não-adaptativo).

### `assets/branding/app_icon_foreground.png`
- **Só o "AL" lima**, resto transparente.
- O "AL" deve caber dentro de **70 % da área** (safe zone do adaptive icon Android).
  Ou seja: margens de 15 % em cada lado. O sistema recorta o restante em círculo/squircle.
- Usado como `adaptive_icon_foreground` no Android — o `adaptive_icon_background`
  já é definido como `#0E1F1A` no `pubspec.yaml`.

### `assets/branding/splash_logo.png` *(opcional)*
- Logo "AutoLog" em branco (`#FFFFFF`) ou lima (`#C4F25C`), grande e centralizado.
- Fundo transparente — a splash já tem cor de fundo `#0E1F1A`.
- Se não for criado, a splash continua sendo cor sólida (já é o comportamento atual).

---

## Como criar os PNGs

### Opção 1 — Figma / Canva
1. Crie um frame **1024 × 1024 px**.
2. Pinte o fundo `#0E1F1A`.
3. Adicione texto "AL" (ou logotipo), cor `#C4F25C`, centralizado.
4. Para `app_icon_foreground.png`: apague o fundo (transparente) e mantenha
   só o texto dentro dos 70 % centrais.
5. Exporte como **PNG** sem compressão.

### Opção 2 — Inkscape (SVG → PNG)
1. Crie SVG 1024 × 1024, fundo `#0E1F1A`, texto "AL" em `#C4F25C`.
2. `inkscape --export-type=png --export-width=1024 --export-filename=app_icon.png logo.svg`

### Opção 3 — ImageMagick (linha de comando, placeholder funcional)
```bash
# app_icon.png — fundo brand + "AL" lima
magick -size 1024x1024 xc:"#0E1F1A" \
  -font Helvetica-Bold -pointsize 420 \
  -fill "#C4F25C" -gravity Center -annotate 0 "AL" \
  assets/branding/app_icon.png

# app_icon_foreground.png — só "AL" lima em fundo transparente, 70% safe zone
magick -size 1024x1024 xc:none \
  -font Helvetica-Bold -pointsize 420 \
  -fill "#C4F25C" -gravity Center -annotate 0 "AL" \
  assets/branding/app_icon_foreground.png
```
> Requer `brew install imagemagick`. Fonte pode variar — substitua `-font` pela fonte disponível.

---

## Comandos para gerar os ícones (após criar os PNGs)

```bash
# Gera a splash (já foi rodado — re-rodar só se mudar a config):
dart run flutter_native_splash:create

# Gera o launcher icon (rodar APENAS após ter os 2 PNGs):
dart run flutter_launcher_icons
```

> **Atenção:** `dart run flutter_launcher_icons` falha se `assets/branding/app_icon.png`
> ou `assets/branding/app_icon_foreground.png` não existirem. Não rodar antes.

---

## O que muda no splash quando adicionar a imagem

Descomente as linhas no `pubspec.yaml` e re-rode `dart run flutter_native_splash:create`:

```yaml
flutter_native_splash:
  color: "#0E1F1A"
  color_dark: "#0E1F1A"
  image: assets/branding/splash_logo.png           # ← descomentar
  ios: true
  android: true
  web: false
  android_12:
    color: "#0E1F1A"
    image: assets/branding/splash_logo_android12.png  # ← descomentar (pode ser o mesmo PNG)
```

Lembre de adicionar `assets/branding/` ao `flutter.assets` no `pubspec.yaml`
se quiser que o Flutter bundle os PNGs para uso em runtime (cards, about screen, etc.):

```yaml
flutter:
  assets:
    - assets/branding/
```

---

## Arquivos gerados pelo `flutter_native_splash:create`

| Plataforma | Arquivos |
|------------|---------|
| Android | `android/app/src/main/res/drawable/launch_background.xml` |
| Android | `android/app/src/main/res/drawable-night/launch_background.xml` |
| Android | `android/app/src/main/res/drawable-v21/launch_background.xml` |
| Android | `android/app/src/main/res/drawable-night-v21/launch_background.xml` |
| Android 12+ | `android/app/src/main/res/values-v31/styles.xml` (criado) |
| Android 12+ dark | `android/app/src/main/res/values-night-v31/styles.xml` (criado) |
| iOS | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (1×, 2×, 3×) |
| iOS | `ios/Runner/Assets.xcassets/LaunchBackground.imageset/` |

---

## Tokens de cor de referência

Do `lib/core/design/tokens.dart`:

```dart
static const brand  = Color(0xFF0E1F1A); // verde-meia-noite
static const accent = Color(0xFFC4F25C); // lima cítrica — usar nos ícones
```
