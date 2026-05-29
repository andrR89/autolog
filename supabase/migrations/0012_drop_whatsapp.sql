-- Reverte 0011_whatsapp_links.sql. Feature 6.FF (WhatsApp bot) descartada
-- em 29/05/2026 por decisão do Diretor: custos Twilio + IA já cobrem
-- registro rápido via app; complexidade não justificada.
--
-- Edge functions whatsapp-generate-code e whatsapp-webhook devem ser
-- deletadas via CLI:
--   supabase functions delete whatsapp-generate-code
--   supabase functions delete whatsapp-webhook

DROP TABLE IF EXISTS public.whatsapp_pending_codes;
DROP TABLE IF EXISTS public.whatsapp_links;
