# Branding — App icon + splash final

> Configuração dos pacotes `flutter_launcher_icons` + `flutter_native_splash`.
> Sem design real ainda — usa placeholder simples (texto + cor brand).
> Diretor troca asset depois quando tiver logo final.

## Decisões pragmáticas
- **Splash**: cor sólida verde-meia-noite (brand `#0E1F1A`) + logo opcional.
  Se asset não existir, splash vira só cor sólida (limpo, sem assets falsos).
- **Launcher icon**: precisa de PNG 1024x1024. README detalha caminho
  `assets/branding/app_icon.png` e instruções de geração via Figma/Canva.
- Configuração 100% pronta no `pubspec.yaml` — basta o asset existir
  e rodar `dart run flutter_launcher_icons` + `dart run flutter_native_splash:create`.
- Suporte: iOS + Android (web ignorado por ora).

## Mudanças

### 1. Pacotes
`pubspec.yaml` — dev_dependencies:
```yaml
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.4
```

### 2. Config splash
`pubspec.yaml` — root:
```yaml
flutter_native_splash:
  color: "#0E1F1A"          # brand verde-meia-noite
  color_dark: "#0E1F1A"     # mesmo (brand é sempre escuro)
  image: assets/branding/splash_logo.png   # opcional — branco/lima
  android_12:
    color: "#0E1F1A"
    image: assets/branding/splash_logo_android12.png
  ios: true
  android: true
  web: false
```

Adicionar `assets/branding/` ao `flutter.assets` se for usar imagens (anota TODO).

### 3. Config launcher icons
`pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/app_icon.png"   # 1024x1024
  adaptive_icon_background: "#0E1F1A"
  adaptive_icon_foreground: "assets/branding/app_icon_foreground.png"  # 1024x1024 com transparência, 70% safe area
  remove_alpha_ios: true
  min_sdk_android: 21
```

### 4. README
`docs/branding-setup.md`:
- Passos pra criar os 3 PNGs (1024x1024):
  - `app_icon.png` — full bleed, fundo brand verde + "AL" lima
  - `app_icon_foreground.png` — só "AL" lima centralizado em 70% da área (resto transparente)
  - `splash_logo.png` — opcional, "AutoLog" branco
- Comandos:
  ```
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
- Anota que Sonnet NÃO gerou PNGs (precisa de design tool real).

### 5. Placeholder via cor sólida (funciona já sem PNG)
Pra splash funcionar IMEDIATAMENTE sem asset, manter `image:` comentado:
```yaml
flutter_native_splash:
  color: "#0E1F1A"
  # image: assets/branding/splash_logo.png   # adicionar quando tiver
  ios: true
  android: true
```

Comando `dart run flutter_native_splash:create` gera splash de cor sólida.

Pra launcher icon: sem asset → não rodar `flutter_launcher_icons` (ícone default do Flutter fica). Anota TODO.

## Critérios
- pubspec.yaml configurado (sem erro de lint)
- README detalhado em docs/branding-setup.md
- `flutter_native_splash:create` roda com sucesso e produz splash sólido brand
- Build iOS sim OK
- Suite verde
