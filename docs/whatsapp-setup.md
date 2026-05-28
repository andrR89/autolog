# WhatsApp Bot Setup — AutoLog

> Guia de configuração do bot WhatsApp para registrar abastecimentos por mensagem de texto.

## Visão geral

O bot usa **Twilio WhatsApp Sandbox** para receber mensagens. O usuário parei com um
número Twilio, envia abastecimentos em linguagem natural e o bot os registra via IA (Haiku).

Arquitetura:
```
Usuário → WhatsApp → Twilio → Edge Function whatsapp-webhook → Supabase/Haiku → fuel_entries
```

---

## 1. Criar conta Twilio

1. Acesse [twilio.com](https://www.twilio.com) e crie uma conta gratuita.
2. Vá em **Messaging → Try it out → Send a WhatsApp message**.
3. Ative o **WhatsApp Sandbox** e anote o número Twilio (ex: `+14155238886`).
4. Siga as instruções para ativar o sandbox no seu número pessoal:
   - Envie `join <palavra-chave>` para o número do sandbox.

---

## 2. Configurar webhook no console Twilio

1. No painel Twilio, vá em **Messaging → Settings → WhatsApp Sandbox Settings**.
2. No campo **When a message comes in**, coloque:
   ```
   https://vdtlldfklcrtpuumfkbm.supabase.co/functions/v1/whatsapp-webhook
   ```
3. Método: `HTTP POST`.
4. Salve.

---

## 3. Variáveis de ambiente nas Edge Functions

As Edge Functions já usam `SUPABASE_SERVICE_ROLE_KEY` e `ANTHROPIC_API_KEY` do ambiente do projeto Supabase. Nenhuma chave Twilio é necessária no servidor (Twilio só chama o webhook via POST).

Para verificar:
```bash
supabase secrets list
```

---

## 4. Deploy das Edge Functions

```bash
supabase functions deploy whatsapp-generate-code
supabase functions deploy whatsapp-webhook
```

---

## 5. Aplicar a migration

```bash
supabase db push
```

Ou via Supabase Dashboard → SQL Editor, execute o conteúdo de:
`supabase/migrations/0011_whatsapp_links.sql`

---

## 6. Fluxo de pareamento

1. Usuário abre **Configurações → WhatsApp** no app.
2. Toca em **Conectar WhatsApp** → app chama `whatsapp-generate-code` → exibe código de 6 dígitos.
3. Usuário envia no WhatsApp para o número Twilio:
   ```
   AUTOLOG 123456
   ```
4. Bot responde: "Pareado com sucesso!"
5. App mostra status "Conectado: +55…".

---

## 7. Enviar abastecimento

Após pareado, o usuário envia mensagens em linguagem natural, ex:
```
abasteci 40 litros de gasolina por R$5,79 no Civic
```
```
40L gasolina 5.79 Civic
```
```
gastei R$231,60 de etanol no Ka
```

Bot responde: "Registrado: 40L por R$231,60 no Civic!"

---

## 8. Custos

| Plano | Mensagens | Custo |
|-------|-----------|-------|
| Sandbox | ~1.000/mês | Gratuito |
| Produção (aprovação Meta) | Ilimitado | ~US$0,005/msg |

> **Nota:** Produção requer aprovação de template de mensagem pela Meta. O sandbox não requer aprovação e é suficiente para desenvolvimento e testes.

---

## 9. TODO pós-MVP

- [ ] WhatsApp como feature premium (paywall): implementar gating na Edge Function após lançamento.
- [ ] Suporte a foto/scan via WhatsApp (Media URL do Twilio).
- [ ] Multi-veículo: confirmação interativa quando o veículo for ambíguo.
- [ ] Template de mensagem aprovado pela Meta para produção.
- [ ] Twilio Verify para validação de número extra (opcional).
