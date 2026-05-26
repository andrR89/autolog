-- Sprint 6.K — adiciona renavam e chassi à tabela vehicles.
-- Safe: IF NOT EXISTS garante idempotência.

ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS renavam text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS chassi text;
