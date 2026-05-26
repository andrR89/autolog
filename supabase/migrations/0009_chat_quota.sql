-- Sprint 6.T: adiciona coluna chat_count à usage_quota para rastrear
-- o uso do chat IA por mês (limit 10/mês no plano free, ilimitado premium).
ALTER TABLE public.usage_quota ADD COLUMN IF NOT EXISTS chat_count integer NOT NULL DEFAULT 0;
