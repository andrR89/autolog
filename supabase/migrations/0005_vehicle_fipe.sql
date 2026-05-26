-- Sprint 6.I — FIPE fields on vehicles (fipe_cache é local-only, não entra aqui)
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_code text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_value text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_reference_month text;
