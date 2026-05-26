-- Sprint 6.G: adiciona coluna analysis_count na tabela usage_quota.
-- Controla a cota mensal de análises de histórico (3/mês free, ilimitado premium).
ALTER TABLE public.usage_quota
  ADD COLUMN IF NOT EXISTS analysis_count integer NOT NULL DEFAULT 0;
