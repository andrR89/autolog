# Spec — Sprint 0.4: Supabase (tabelas espelho, RLS, Auth)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; **André aplica o SQL no console**.
> Fonte: `docs/ARCHITECTURE.md §3, §10` + Regras de Ouro. Depende de 0.2/0.3 (schema + modelos).

## Natureza desta tarefa
**Infra-pesada.** A maior parte (criar projeto, aplicar SQL, RLS, OAuth) não roda em `flutter test`. Adaptação do ciclo TDD:
- **Testável em Dart (RED→GREEN):** validação de `SupabaseConfig`.
- **Deliverables revisados por Haiku + aplicados/homologados por André:** migrations SQL, init do client, wiring.

## Credenciais (já fornecidas)
- Project URL: `https://vdtlldfklcrtpuumfkbm.supabase.co` · anon key validada (auth health 200).
- Injeção via **`--dart-define-from-file=dart_define.json`** (arquivo já criado, **gitignored**). Exemplo versionado em `dart_define.example.json`. **Nenhuma credencial hardcoded no código.**

## Decisões técnicas

### 1. `SupabaseConfig` (testável)
`lib/core/config.dart` — classe de valor imutável:
- Construtor `SupabaseConfig({required String url, required String anonKey})` que **valida**: `url` não-vazia e começa com `https://`; `anonKey` não-vazia. Inválido → `ArgumentError` (mensagem clara em PT-BR).
- Factory `SupabaseConfig.fromEnvironment()` lendo `String.fromEnvironment('SUPABASE_URL')` e `String.fromEnvironment('SUPABASE_ANON_KEY')` e delegando ao construtor validante.

### 2. Init do client + provider
- `lib/data/remote/supabase_client.dart`: inicialização via `Supabase.initialize(url:..., anonKey:...)` usando `SupabaseConfig.fromEnvironment()`; expõe `SupabaseClient` por um provider Riverpod (`supabaseClientProvider`).
- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()` + `await Supabase.initialize(...)` antes do `runApp`, dentro de `ProviderScope`. Trocar o boilerplate `MyApp` por `AutoLogApp` (de `lib/app.dart`).

### 3. Migrations SQL (espelho do Drift, `ARCHITECTURE §3`)
`supabase/migrations/0001_initial_schema.sql`:
- 5 tabelas espelho: `vehicles`, `fuel_entries`, `expenses`, `reminders`, `usage_quota`.
- Tipos Postgres: `id uuid PK`, textos `text`, dinheiro/volume **`numeric`** (não `float`/`double precision` — precisão), datas `timestamptz`, `date` para `reminders.due_date`, enums como `text` com `CHECK` nos wire values (`fuel_type in ('gasolina',...)`, `source in ('ai_scan','ocr','manual')`, etc.), `sync_status text default 'pending'`, `deleted_at timestamptz null`.
- `vehicles.user_id uuid not null references auth.users(id)`. `usage_quota.user_id uuid PK references auth.users(id)`.
- **RLS habilitado em todas.** Políticas:
  - `vehicles` e `usage_quota`: `user_id = auth.uid()` (select/insert/update/delete).
  - `fuel_entries`, `expenses`, `reminders` (não têm `user_id` — **não alterar o modelo de dados aprovado**): política via subquery — `vehicle_id in (select id from vehicles where user_id = auth.uid())`.
- Índices em FKs (`vehicle_id`) e em `updated_at` (sync incremental).

> **Decisão registrada p/ André:** as 3 tabelas-filha fazem RLS por subquery em `vehicles` em vez de denormalizar `user_id`, para **não mexer no modelo de dados** já fechado nas 0.2/0.3. Performance é suficiente para o volume single-user do MVP.

### 4. Auth
- **Email/senha** habilitado (default). Suficiente para a 0.5 começar.
- **Google OAuth fica para depois** (precisa de Google Cloud + URL scheme iOS) — não bloqueia o login. Anotar como follow-up.

## Critérios de aceite
**Testes (`test/core/config_test.dart`) — verdes:**
1. `SupabaseConfig(url:'https://x.supabase.co', anonKey:'k')` cria ok e expõe os valores.
2. url vazia → `ArgumentError`.
3. url sem `https://` → `ArgumentError`.
4. anonKey vazia → `ArgumentError`.

**Deliverables (revisão Haiku + homologação André):**
5. `supabase/migrations/0001_initial_schema.sql` aplicável sem erro; RLS ativo; CHECKs batem com os wire values dos enums (0.3).
6. App inicializa o Supabase no boot via dart-define (sem credencial no código); `flutter analyze` limpo; suíte verde.

## Definition of Done
- Testes de `SupabaseConfig` verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- SQL pronto e revisado; **André aplica no SQL Editor** e confirma (entra no `HOMOLOG.md` na homologação do Sprint 0).
- App builda com `--dart-define-from-file=dart_define.json`.
- Follow-up "Google OAuth" anotado.
