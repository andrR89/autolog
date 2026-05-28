# Sprint 6.FF — WhatsApp bot (registra abastecimento por mensagem)

> User manda "abasteci 40 litros por 5,79 no Civic" pro número Twilio;
> bot parseia via Haiku, registra fuel_entry no veículo correto.

## Decisões
- Provider de mensageria: **Twilio WhatsApp** (sandbox grátis pra dev).
- Setup Twilio externo (Diretor faz quando quiser ativar) — Edge fn fica
  pronta + README documenta passos.
- Parsing via Haiku — reusa pattern de scan-expense.
- Pareamento user ↔ número: code de 6 dígitos. App gera code, user envia
  pro número Twilio com "AUTOLOG <code>", server cria link.
- Schema servidor: `whatsapp_links(user_id, phone_number, paired_at)`.
- Estrutura completa pronta; ativação real exige config Twilio.

## Mudanças

### 1. Migration Supabase `0011_whatsapp_links.sql`
```sql
CREATE TABLE IF NOT EXISTS public.whatsapp_links (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number text NOT NULL UNIQUE,
  paired_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.whatsapp_pending_codes (
  code text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.whatsapp_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_pending_codes ENABLE ROW LEVEL SECURITY;
-- Service role bypassa RLS (edge fns).
CREATE POLICY "wa_links_self" ON public.whatsapp_links
  FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "wa_codes_self" ON public.whatsapp_pending_codes
  FOR ALL TO authenticated USING (user_id = auth.uid());
```

### 2. Edge fn `whatsapp-generate-code`
`supabase/functions/whatsapp-generate-code/index.ts`:
- Auth JWT.
- Gera código random 6 dígitos.
- Insert em `whatsapp_pending_codes`.
- Return `{code: "123456"}`.

### 3. Edge fn `whatsapp-webhook`
`supabase/functions/whatsapp-webhook/index.ts`:
- POST público (Twilio chama). Sem auth JWT (webhook).
- Body: parâmetros do Twilio (form-urlencoded: `From`, `Body`, etc).
- Lógica:
  1. Se `Body` começa com "AUTOLOG ": extrai código, busca em
     `whatsapp_pending_codes`, cria `whatsapp_links` pro user, deleta
     code, responde "Pareado!".
  2. Senão: busca link pelo `From` (número). Se não pareado, responde
     "Não pareado. Abra Configurações → WhatsApp pra gerar código."
  3. Se pareado: passa `Body` pro Haiku com prompt extrai
     `{vehicle_hint, liters, price_per_liter, total_cost, fuel_type, date?}`.
  4. Busca veículo do user que matcha `vehicle_hint` (nickname/marca).
     Sem match → responde "Não identifiquei o veículo. Disponíveis: …"
  5. Cria fuel_entry no banco (service role bypassa RLS).
  6. Responde "Registrado!".

Resposta no TwiML format `<Response><Message>...</Message></Response>`.

### 4. Service Dart
`lib/features/whatsapp/whatsapp_service.dart`:
```dart
abstract class WhatsAppService {
  Future<bool> isPaired();
  Future<String?> pairedPhoneNumber();
  Future<String> generatePairingCode();
  Future<void> unpair();
}

class RealWhatsAppService implements WhatsAppService { ... }
class MockWhatsAppService implements WhatsAppService { ... }
```

### 5. UI Settings
`SettingsScreen` ganha card "WhatsApp":
- Desconectado: "Conectar WhatsApp" → gera code → mostra instrução
  "Envie 'AUTOLOG 123456' pro nosso número: +14155238886".
- Conectado: "Conectado: +5511…" + "Desconectar".

### 6. README setup
`docs/whatsapp-setup.md`:
- Criar conta Twilio + ativar sandbox WhatsApp.
- Configurar webhook URL no console Twilio →
  `https://vdtlldfklcrtpuumfkbm.supabase.co/functions/v1/whatsapp-webhook`.
- Custos: sandbox grátis 1k msg/mês; produção precisa template aprovado.
- TODO pós-MVP: paywall do WhatsApp como feature premium.

## Testes
- `test/features/whatsapp/whatsapp_service_test.dart` — MockWhatsAppService.
- Tests da edge fn: out of scope (Deno, sem suite Dart).

## Critérios
- Suite verde + ~5 novos
- analyze 0, iOS sim builds
- README setup detalhado
- Migration 0011 + 2 edge fns prontas pra deploy

## Não-objetivos
- Foto/scan via WhatsApp (futuro).
- Multi-conta WhatsApp por usuário.
- Confirmação interativa via reply (registro é direto).
