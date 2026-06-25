# Roteiro de Teste — Onda 4 (i18n EN/ES)

> Valida o setup de internacionalização do item #16. **Escopo curto** — só
> as strings migradas até agora (Settings + Login). O resto do app
> continua em PT-BR hardcoded por design.
>
> Tempo estimado: **10 min**.
> Pré-requisitos: build atual rodando, conta de teste (`premium.0618@autolog.test`).

## Setup (1 min)

1. App instalado, login na conta.
2. Idioma do iOS/Android: deixa em **Português (Brasil)** pra começar.

### Como reportar achados
- **Bloco / passo**: ex. "Bloco 2, passo 2.3"
- **Esperado vs observado** (1 linha cada)
- **Print** sempre que possível
- **Plataforma**: iOS (modelo) ou Android (modelo)

---

## Bloco 1 — Setup base (3 min)

| # | Ação | Esperado |
|---|------|----------|
| 1.1 | Abre Settings | AppBar "Configurações" (PT-BR — porque o sistema está em PT-BR) |
| 1.2 | Role até o card **"Idioma"** | Visível com ícone 🌐, subtítulo "Padrão do sistema" |
| 1.3 | Tocar o card | Abre bottom sheet com 4 opções: **Padrão do sistema** (✓), **Português**, **English**, **Español** |
| 1.4 | Cancela tocando fora do sheet | Volta sem mudar nada, subtítulo continua "Padrão do sistema" |

> ⚠️ Se o card "Idioma" não aparecer ou o sheet não abrir, é regressão. Reporta.

---

## Bloco 2 — Troca pra English (3 min)

| # | Ação | Esperado |
|---|------|----------|
| 2.1 | Settings → Idioma → **English** | Sheet fecha, AppBar muda na hora pra **"Settings"** |
| 2.2 | Conferir os outros cards de Settings | "Go Premium" (em vez de "Virar Premium"), subtitle "Unlimited scans and insights." |
| 2.3 | Card "Sair" | Vira "Sign out" + "Logs out from this device." |
| 2.4 | Card "Idioma" agora | Title "Language", subtítulo "English" (não "Padrão do sistema" — porque o usuário escolheu explicitamente) |
| 2.5 | Faz logout pelo card "Sign out" → cai em login | Título da tela: **"Sign in to your account"** |
| 2.6 | Conferir campos | Label "Email" + "Password". Toca no 👁 da senha → tooltip "Show password" |
| 2.7 | Outras telas do app (Garagem, fuel form, paywall) | Continuam em PT-BR — **isso é esperado** (migração total fica como follow-up; ver `docs/I18N.md`) |

> ⚠️ Se algum desses títulos/labels migrados continuou em PT-BR depois de trocar pra English, reporta com o widget exato.

---

## Bloco 3 — Troca pra Español (2 min)

| # | Ação | Esperado |
|---|------|----------|
| 3.1 | Loga de novo, vai em Settings → Idioma → **Español** | AppBar "Configuración" |
| 3.2 | Card Premium | "Hazte Premium" + "Escaneos e ideas ilimitados." |
| 3.3 | Card Sair | "Cerrar sesión" + "Cierra la sesión en este dispositivo." |
| 3.4 | Loga out → tela de login | "Inicia sesión en tu cuenta" / "Correo electrónico" / "Contraseña" |
| 3.5 | Toggle senha | Tooltip "Mostrar contraseña" |

---

## Bloco 4 — Persistência + sistema (2 min)

| # | Ação | Esperado |
|---|------|----------|
| 4.1 | Com app em Español, **mata o app** (swipe na multitarefa) e reabre | Abre em Español (persistido em SharedPreferences) |
| 4.2 | Volta em Settings → Idioma → **Padrão do sistema** | Subtítulo passa a "Configuración del sistema" (porque ainda está em ES). Bottom sheet fechou; AppBar fica em PT-BR (ou no que o iOS tiver setado) |
| 4.3 | Vai no iOS Settings → Geral → Idioma e região → muda pra English (se sua conta tiver) → volta no app | App agora em English automaticamente. Se reverter o iOS pra PT-BR, app volta pra PT-BR. |
| 4.4 | Volta pro PT-BR via iOS + escolhe **Português** explícito no app | Subtítulo do card mostra "Português" |

> ⚠️ Se mudar idioma no iOS **não refletir** com o app já aberto, abrir um issue baixo (alguns devices precisam de hot restart pra propagar — verifica se kill+reopen resolve antes de reportar).

---

## ✅ Encerramento

Manda pro Diretor:
1. Lista numerada de bugs (bloco/passo, print, plataforma).
2. Tempo total que demorou.
3. 1 linha sobre a sensação geral.
4. Coisas que te surpreenderam positivamente.

Notas:
- **Migração total** é um trabalho denso (300+ strings). Decisão consciente foi entregar o framework + áreas que falantes não-PT veem primeiro (login + settings). Resto fica como follow-up — está documentado em `docs/I18N.md`.
- **Traduções EN/ES** foram feitas por mim sem revisão nativa. Se algo soar gringo ou errado, anota tipo "EN: 'Try again' soa robótico, melhor seria 'Retry'" e a gente corrige.

Bom teste! 🌍
