# Roteiro de Teste — Responsividade Camada 1 (maxWidth)

> Valida o wrapper `ResponsiveBody` aplicado em **13 telas** de coluna única
> (11 forms + chat + paywall + Settings). **Escopo curto**: só confirma que
> o conteúdo centraliza em desktop sem regredir o mobile.
>
> Tempo estimado: **15 min**.
> Como rodar: `flutter run --device-id chrome --dart-define-from-file=dart_define.json --web-port=8080` (já está rodando).

## Setup (1 min)

1. Web: Chrome em http://localhost:8080.
2. DevTools (F12) → modo dispositivo desligado pra usar resize da janela do Chrome.
3. Conta `web.teste.0625@autolog.test` (já logada via IndexedDB).

### Como reportar
- **Bloco / passo** + **viewport (px)** + **print** + **comportamento esperado vs observado**.

---

## Bloco 1 — Desktop largo (≥1440px) (5 min)

**Setup:** janela do Chrome maximizada em monitor 1440px+. Confere com `window.innerWidth` no console se ficar em dúvida.

| # | Tela | Esperado |
|---|------|----------|
| 1.1 | **Settings** (toca no ícone de Configurações) | Cards centralizados em ~720px no meio da tela; background lateral lateral livre (não estica) |
| 1.2 | **Settings → Idioma → bottom sheet** | Sheet do nativo (não controlado pela Camada 1) — deixa do tamanho que tá |
| 1.3 | **Logout → Login** | Form **centralizado em ~560px** (mais estreito que Settings). Logo/título topo OK. Inputs E-mail/Senha não esticam |
| 1.4 | **Cadastro** (link "Já tenho conta? Criar conta") | Mesmo padrão do login (~560px) |
| 1.5 | **Garagem → + → Novo veículo** | Form ~560px centrado. **Save bar "Adicionar veículo" no rodapé continua full-width** (sticky no Scaffold, NÃO centralizada) |
| 1.6 | **Veículo → Novo abastecimento** | Form ~560px. **TotalActionBar (TOTAL — / Salvar) no rodapé continua full-width** |
| 1.7 | **Despesas → Nova despesa** | Form ~560px. Save bar full-width |
| 1.8 | **Lembretes → Novo lembrete** | Form ~560px. Save bar full-width |
| 1.9 | **Configurações → "Virar Premium"** (paywall) | Conteúdo centralizado em ~720px. CTA "Em breve" no rodapé continua full-width |
| 1.10 | **Chat com IA** (algum lugar do app que abre) | Mensagens centralizadas em ~720px. Input do rodapé continua full-width |
| 1.11 | **Documentos → Cadastrar CNH** | Form ~560px. Save bar full-width |

> ⚠️ Bug crítico: form esticando até a borda da tela = ResponsiveBody não aplicou.
> ⚠️ Bug crítico: save bar centralizada (não full-width) = Sonnet wrappou errado.

---

## Bloco 2 — Tablet (768-1023px) (3 min)

**Setup:** DevTools → toggle device toolbar → **iPad** (1024×768 landscape) OU resize manual.

| # | Tela | Esperado |
|---|------|----------|
| 2.1 | Settings | Cards centralizados em 720px, sobra lateral (≈150px de cada lado) |
| 2.2 | Login | Form em 560px, com bastante background lateral |
| 2.3 | Form de veículo / abastecimento | 560px centrado, save bar full-width |

---

## Bloco 3 — Mobile/portrait estreito (<600px) (2 min)

**Setup:** DevTools → toggle device toolbar → **iPhone 14 Pro** (393×852) OU resize pra ~400px de largura.

| # | Tela | Esperado |
|---|------|----------|
| 3.1 | Settings | **Igual ao mobile real** — cards usam toda a largura (sem maxWidth aparente, porque 393 < 560) |
| 3.2 | Login | Igual ao mobile |
| 3.3 | Form de veículo | Igual ao mobile |
| 3.4 | Chat / paywall | Igual ao mobile |

> ⚠️ Se algo ficar com margens laterais em tela <600px = bug (devia usar largura completa).

---

## Bloco 4 — Telas NÃO tocadas pela Camada 1 (regressão) (3 min)

Essas têm **hero header brand-dark cobrindo a largura toda**. Vão receber tratamento diferente em outra rodada. **Devem estar idênticas ao antes da Camada 1.**

| # | Tela | Esperado |
|---|------|----------|
| 4.1 | **Garagem** (`/vehicles`) | Hero "GARAGEM 1 carro" full-width; lista de cards full-width (estica) — visual igual ao pré-C1 |
| 4.2 | **Detalhe do veículo** (fuel history) | Hero brand-dark full-width; cards de consumo/preço esticam — igual ao pré-C1 |
| 4.3 | **Despesas (lista)** | Hero "GASTO ESTE MÊS" full-width; lista estica — igual ao pré-C1 |
| 4.4 | **Lembretes (lista)** | Hero "0 pendentes" full-width; lista estica — igual ao pré-C1 |
| 4.5 | **Documentos** | Hero full-width; cards esticam — igual ao pré-C1 |
| 4.6 | **Relatórios** | Gráficos esticam — igual ao pré-C1 |

> Essas vão ser tratadas em rodada futura (constrain só o conteúdo abaixo do hero, hero continua full).
> ⚠️ Se alguma dessas **mudou** (centralizou ou perdeu o hero brand-dark), é regressão acidental — reporta.

---

## Bloco 5 — Mobile nativo (1 min, OPCIONAL)

Só se você tiver o sim do iOS rodando em paralelo. Pra Camada 1 zero mobile regressão é esperado (todas as telas em viewport <600 ficam idênticas).

| # | Plataforma | Esperado |
|---|------|----------|
| 5.1 | iOS sim | Settings/Login/forms idênticos ao build anterior. Sem espaço lateral, sem mudança visual. |

---

## ✅ Encerramento

Pro Diretor:
1. Lista numerada de regressões (bloco/passo, viewport, print).
2. Sensação visual em 1-2 linhas (forms 560 está confortável? Settings 720 está OK? Algo poderia ser maior/menor?).
3. Tempo total.

Notas:
- **Próxima onda (Camada 2)**: grid em listas (garagem/documentos/lembretes vão virar 2-3 colunas em desktop). Já planejado.
- **Hero headers** (Bloco 4) ficam pra uma terceira rodada — abordagem diferente (constrain só o conteúdo, não o hero).
- Eu (Code) parto pra PWA + service worker quando você confirmar C1 OK.

Bom teste! 📱💻
