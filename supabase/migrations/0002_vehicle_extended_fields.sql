-- Sprint 6.E — campos opcionais expandidos do Vehicle.
-- Adiciona year/uf/color (todos nullable) à tabela public.vehicles.
-- Veículos existentes ficam com NULL nos novos campos.

ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS year integer;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS uf text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS color text;
