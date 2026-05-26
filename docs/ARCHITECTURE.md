# ARCHITECTURE.md — AutoLog

> Define **como** o produto de `PRD.md` é construído. Decisões técnicas e suas justificativas.

## 1. Stack

| Camada | Escolha | Por quê |
|---|---|---|
| App | **Flutter** (Dart) | Cross-platform real: Android, depois Web, depois iOS, do mesmo código. |
| Estado | **Riverpod** | Testável, sem boilerplate; bom para estado assíncrono (sync). |
| Persistência local | **Drift** (SQLite tipado) | Queries SQL reais — essenciais para relatórios agregados. Na web, Drift roda sobre WASM/IndexedDB. |
| Backend | **Supabase** | Postgres real (relatórios = SQL), Auth + RLS para isolamento por usuário, tier grátis segura o MVP. |
| Auth | Supabase Auth | Email/senha + Google. |
| IA — cupom | **Claude Haiku 4.5** via backend | Extração estruturada de imagem; barato; nunca chamado direto do app. |
| IA — odômetro | **ML Kit Text Recognition** (on-device) | Grátis, offline, só dígitos. **Só mobile** (não existe na web). |
| Billing | **Play + App Store IAP + Stripe**, unificados via **RevenueCat** | Um entitlement, três canais de venda. Ver §8. |

## 2. Princípio de arquitetura: cloud-first, mas tolerante a falha

> O momento de registro é **no posto de gasolina**, frequentemente com sinal péssimo.

Portanto: **escrita otimista local + sync em background.** A fonte de verdade é a nuvem, mas o app nunca bloqueia o usuário esperando rede. O registro manual funciona 100% offline.

```
[UI] → escreve no Drift (local) IMEDIATAMENTE → marca registro como "pending_sync"
                                                          ↓
                                          [SyncService em background]
                                                          ↓
                                   sobe para Supabase quando houver rede
                                                          ↓
                                   marca como "synced" / resolve conflito
```

### Estratégia de sync
- Cada tabela sincronizável tem: `id` (UUID gerado no client), `updated_at`, `sync_status` (`pending` | `synced`), `deleted_at` (soft delete — nunca hard delete no MVP).
- Sync incremental por `updated_at` (pull do que mudou; push do que está `pending`).
- Resolução de conflito: **last-write-wins** por `updated_at` no MVP. Suficiente para single-user; revisitar se multi-device pesar.
- UUID no client evita colisão e permite criar offline sem ida ao servidor.

## 3. Modelo de dados

### `vehicles`
| Campo | Tipo | Notas |
|---|---|---|
| id | UUID (PK) | gerado no client |
| user_id | UUID (FK) | RLS |
| nickname | text | "Meu Civic" |
| make / model | text | opcional |
| plate | text | opcional |
| fuel_type | enum | gasolina/etanol/diesel/flex/gnv |
| initial_odometer | int | km |
| created_at, updated_at, deleted_at, sync_status | | |

### `fuel_entries` (abastecimentos)
| Campo | Tipo | Notas |
|---|---|---|
| id | UUID (PK) | |
| vehicle_id | UUID (FK) | |
| date | timestamp | |
| odometer | int | km no momento |
| liters | decimal | |
| price_per_liter | decimal | |
| total_cost | decimal | redundante p/ histórico de preço |
| full_tank | bool | **CRÍTICO p/ cálculo de consumo (ver PRD §7)** |
| fuel_type | enum | pode diferir do veículo (flex) |
| source | enum | `ai_scan` / `ocr` / `manual` — mede adoção da tese |
| receipt_image_url | text? | opcional, storage |
| created_at, updated_at, deleted_at, sync_status | | |

### `expenses` (despesas gerais)
| Campo | Tipo | Notas |
|---|---|---|
| id | UUID (PK) | |
| vehicle_id | UUID (FK) | |
| date | timestamp | |
| category | enum | manutenção/lavagem/estacionamento/multa/seguro/IPVA/outro |
| description | text | |
| amount | decimal | |
| odometer | int? | opcional |
| created_at, updated_at, deleted_at, sync_status | | |

### `reminders` (lembretes)
| Campo | Tipo | Notas |
|---|---|---|
| id | UUID (PK) | |
| vehicle_id | UUID (FK) | |
| type | enum | por_km / por_data |
| title | text | "Troca de óleo" |
| due_km | int? | dispara quando odômetro ≥ |
| due_date | date? | |
| is_done | bool | |
| created_at, updated_at, deleted_at, sync_status | | |

### `usage_quota` (controle de cota de scan — desde o dia 1)
| Campo | Tipo | Notas |
|---|---|---|
| user_id | UUID (PK) | |
| month | text | "2026-05" |
| scan_count | int | incrementa a cada scan de IA |
| is_premium | bool | espelha entitlement validado (ver §8) |

> Cota checada/incrementada **no backend** (edge function), nunca confiando só no client. Limite free: **5/mês**.

## 4. Captura de imagem — abstração por plataforma

> Regra: a fonte da imagem difere por plataforma, o pipeline de IA NÃO. Abstrair desde o dia 1.

```dart
abstract class ImageSource {
  Future<Uint8List?> obtainReceiptImage();
}
// MobileImageSource  → câmera (image_picker / camera)
// WebImageSource     → file picker / drag-and-drop
```

A camada de scan recebe `Uint8List` e não sabe (nem se importa) de onde veio. Isso evita acoplar o fluxo de IA à câmera e poupa retrabalho quando a web entrar.

## 5. Pipeline de scan por IA (cupom fiscal)

```
App obtém imagem (câmera OU upload) → comprime/redimensiona local → POST p/ Edge Function (Supabase)
   → Edge Function: 1) checa cota  2) chama Claude Haiku 4.5 com a imagem
   → Haiku retorna JSON: {liters, price_per_liter, total, date, fuel_type}
   → backend incrementa usage_quota → devolve JSON ao app
   → App PRÉ-PREENCHE o formulário e MOSTRA p/ revisão do usuário
   → usuário confirma/corrige → salva (otimista local + sync), source = ai_scan
```

Pontos não-negociáveis:
- **Nunca** chamar a API Anthropic direto do app (chave vazaria). Sempre via Edge Function.
- **Nunca** salvar o resultado sem revisão humana — o scan pré-preenche, o usuário confirma.
- **Fallback manual sempre disponível**: se o scan falha, a cota esgota, ou não há rede, o usuário preenche na mão. O formulário manual é o caminho base; o scan é um atalho que o alimenta.
- Prompt instrui o modelo a responder **somente JSON**, sem markdown. Parse defensivo no backend.
- Comprimir imagem antes de enviar (reduz tokens = reduz custo).

### Esboço do prompt de extração (backend)
```
Você extrai dados de cupons fiscais de postos de combustível brasileiros.
Responda APENAS com JSON válido, sem markdown, sem explicação.
Schema: {"liters": number|null, "price_per_liter": number|null,
"total": number|null, "date": "YYYY-MM-DD"|null, "fuel_type": string|null}
Se um campo não for legível, use null. Nunca invente valores.
```

## 6. Economia da IA (COGS)
- Modelo: **Claude Haiku 4.5** ($1/M input, $5/M output) — otimizado p/ extração de alto volume.
- Custo por scan de cupom: **< US$ 0,01**. Usuário free que esgota 5/mês ≈ 5 centavos/mês.
- Híbrido p/ reduzir custo: **odômetro → OCR on-device** (ML Kit, grátis, mobile); **cupom → API multimodal** (caso difícil).

## 7. Divergências por plataforma (resumo)

| Recurso | Mobile (Android/iOS) | Web |
|---|---|---|
| Captura de imagem | Câmera | Upload / drag-drop |
| OCR odômetro on-device | ML Kit ✅ | ❌ (manual ou scan multimodal) |
| Scan de cupom (IA) | ✅ | ✅ (mesmo pipeline) |
| Billing | Play (Android) / IAP (iOS) | Stripe |
| Notificações | Local notifications | Web push (ou e-mail) |
| Persistência | SQLite nativo | Drift WASM / IndexedDB |

## 8. Billing — entitlement único, múltiplos canais

> **Princípio central:** a assinatura é um **entitlement no backend, atrelado à CONTA, agnóstico de plataforma e de dispositivo.** Onde foi comprada não importa para onde vale. Quem assina na web usa no mobile e vice-versa.

```
  Compra via Google Play  ─┐
  Compra via App Store IAP ─┼─→ webhook → RevenueCat → backend: is_premium=true (conta)
  Compra via Stripe (web) ─┘                                    │
                                                                ↓
                       App (qualquer plataforma) consulta o backend → libera premium
```

### O que as lojas permitem (estado 2026, em movimento por litígio Epic)
- **Regra base:** dentro do app das lojas, você **não pode linkar/direcionar** para um pagamento alternativo (ex.: "assine mais barato no site"). Isso vale para Play e App Store.
- **O que SEMPRE é permitido:** vender a assinatura na **web** (Stripe, mais barato sem taxa de loja) e divulgar esse preço **fora dos apps** (site, e-mail, redes). A assinatura comprada na web **funciona normalmente** no mobile — basta logar. É o modelo Netflix/Spotify.
- **Android (EUA):** desde out/2025, pagamento externo liberado, mas programas específicos (Alternative Billing / External Links) com regras e taxas reduzidas. Geografia importa.
- **iOS (EUA):** desde abr/2025, links externos sem comissão da Apple — mas **específico dos EUA**. O AutoLog provavelmente **não** se qualifica como "reader app" clássico (ferramenta, não consumo de mídia), então fora dos EUA a Apple tende a exigir oferecer o IAP como opção.

### Decisão para o AutoLog (conservadora, à prova de rejeição, funciona em qualquer país)
- **Android:** oferece assinatura via **Google Play Billing** dentro do app (15% após 1º ano; converte bem). Não linkar para web dentro do app.
- **Web:** vende a mesma assinatura via **Stripe**, mais barata. Divulga o preço web **fora** dos apps.
- **iOS (3ª onda):** oferecer **App Store IAP** dentro do app. Reavaliar regras de "reader app"/links externos na época.
- **Unificação:** **RevenueCat** sincroniza o entitlement entre Play, App Store e Stripe → backend mantém `is_premium` único. Evita costurar 3 webhooks na mão.

> ⚠️ **Aviso para qualquer agente/dev:** estas regras de loja mudam mês a mês por litígio ativo (Epic v. Apple/Google) e variam por país. NÃO tratar como verdade eterna. **Ler a Payments policy (Play Console) e a Guideline 3.1 (App Store) atuais antes de cada publicação.** Não somos advogados.

## 9. Estrutura de pastas (Flutter)
```
lib/
  core/            # tema, constantes, utils, errors
  platform/        # abstrações: ImageSource, billing, notifications (impl por plataforma)
  data/
    local/         # Drift: tabelas, DAOs
    remote/        # Supabase client, edge function calls
    sync/          # SyncService, conflict resolution
    repositories/  # uma fonte de verdade por entidade
  domain/
    models/        # entidades puras (freezed)
    services/      # cálculo de consumo, regras de negócio
  features/
    vehicles/
    fuel/          # registro manual + scan
    expenses/
    reminders/
    reports/
    paywall/       # assinatura / entitlement
  app.dart
  main.dart
```

## 10. Segurança / privacidade
- RLS no Supabase: usuário só lê/escreve `where user_id = auth.uid()`.
- Chave da API Anthropic vive **só** no backend (env da Edge Function).
- Imagens de cupom: storage privado, URL assinada com expiração.
- LGPD: prever exclusão de conta (apaga dados) no backlog.

## 11. Decisões em aberto (revisitar)
- Storage de imagem de cupom: guardar p/ reauditoria vs. processar-e-descartar. Inclinação: descartar no MVP, guardar só p/ premium.
- Notificações de lembrete: local notifications bastam no mobile MVP; web push só se necessário.
- Entrar ou não nos programas de billing alternativo das lojas: avaliar quando houver volume; hoje o modelo conservador (web fora do app) basta.
