# Achados — Roteiro Onda 4 (i18n EN/ES), 25/06

**Tester:** Claude (Cowork) · **Ambiente:** Simulador iPhone 16e, iOS 26.3 (sistema em PT-BR) · **Conta:** premium.0618@autolog.test

> Legenda: ✅ validado ao vivo · 🟡 validado por código · ⏭️ não executável aqui.
> **Resultado: sem bugs.** Tudo que foi migrado está correto e a troca de idioma é reativa (a UI muda na hora). Algumas notas de escopo/copy abaixo.

## Bloco 1 — Setup base ✅
- **1.1** Settings em PT-BR → AppBar "Configurações" ✅
- **1.2** Card **"Idioma"** com ícone 🌐 + subtítulo "Padrão do sistema" ✅
- **1.3** Bottom sheet com **4 opções**: Padrão do sistema (✓), Português, English, Español ✅
- **1.4** Estrutura do seletor confere (4 locales: pt/en/es + null=sistema, `locale_providers.dart`).

## Bloco 2 — English ✅
- **2.1** Idioma → English: sheet fecha e AppBar vira **"Settings"** na hora (reativo via `ref.watch(localeProvider)` em `app.dart`) ✅
- **2.2** Card Premium: **"Go Premium" / "Unlimited scans and insights."** ✅
- **2.3** Card logout: **"Sign out" / "Logs out from this device."** ✅
- **2.4** Card idioma: **"Language" / "English"** (não "system default", porque foi escolha explícita) ✅
- **2.5/2.6** Tela de login em EN — 🟡 código: `Sign in to your account`, `Email`, `Password`, toggle `Show password` (verifiquei a tela ao vivo em ES; a de EN sai dos mesmos getters).
- **2.7** Garagem/forms/resto seguem em PT-BR — **esperado** ✅ (só Premium/Language/Sign out + login foram migrados).

## Bloco 3 — Español ✅
- **3.1** AppBar **"Configuración"** ✅
- **3.2** Premium: **"Hazte Premium" / "Escaneos e ideas ilimitados."** ✅
- **3.3** Logout: **"Cerrar sesión" / "Cierra la sesión en este dispositivo."** ✅
- **3.4** Login ao vivo: **"Inicia sesión en tu cuenta"**, **"Correo electrónico"**, **"Contraseña"** ✅
- **3.5** Toggle senha tooltip **"Mostrar contraseña"** — 🟡 código (`authPasswordShow` es).

## Bloco 4 — Persistência + sistema
- **4.2** ✅ Idioma → "Predeterminado del sistema": app volta **na hora** pro locale do iOS (PT) — AppBar "Configurações", subtítulo "Padrão do sistema".
- **4.1** 🟡 Persistência via **SharedPreferences** (`locale_code`, lido no `LocaleNotifier.build()`); o idioma sobreviveu à transição de logout (login saiu em ES). Cold-kill via gesto não foi confiável no simulador, mas o cold-start lê o mesmo pref. *(Vale um kill+reopen no device pra fechar 100%.)*
- **4.4** 🟡 "Português" explícito → subtítulo "Português" (`localeDisplayName`).
- **4.3** ⏭️ Trocar o idioma do **iOS** e ver o app seguir: não executei (mudar idioma do simulador é pesado/reinicia). Implementação suporta (`locale: null` → fallback pro sistema entre `supportedLocales`). Confirmar no device.

## 📝 Notas (não são bugs)
1. **Roteiro 4.2 — texto diferente do real.** O roteiro esperava subtítulo "Configuración del sistema"; o app mostra **"Predeterminado del sistema"** (tradução padrão e correta). Só ajuste do roteiro.
2. **Roteiro 4.2 — comportamento.** Esperava que o subtítulo "ficasse em ES" ao escolher sistema; na prática a troca é **instantânea** pro locale do sistema (PT). Comportamento certo, expectativa do roteiro é que estava off.
3. **Tela de login — migração parcial.** Título + e-mail + senha + toggle migraram (EN/ES), mas **"Continuar com Google/Apple"**, a tagline **"Tire uma foto. O app preenche o resto."** e **"Cadastre-se"** seguem em PT-BR. Bate com a decisão de migração parcial, mas como a tela de login é "a primeira coisa que um falante não-PT vê", vale decidir se esses 3 entram no escopo do login.
4. **EN/ES sem revisão nativa** (você sinalizou): tudo que vi soa natural — "Go Premium", "Unlimited scans and insights.", "Hazte Premium", "Escaneos e ideas ilimitados.", "Cerrar sesión", "Inicia sesión en tu cuenta", "Correo electrónico", "Contraseña". Nada robótico.

## Tempo
~15 min (parte perdida com a tela do Mac travando/bloqueando no meio).

## Sensação geral
Framework de i18n sólido e reativo: trocar idioma reflete na hora, persiste, e o fallback de sistema funciona. As strings migradas estão certas nos 3 idiomas. O único ponto de decisão é o escopo da tela de login (3 strings ainda em PT).

## Surpresa positiva
A troca ser **instantânea** (sem reiniciar o app) e o seletor já localizar as próprias opções ("System default" / "Predeterminado del sistema") — detalhe caprichado.
