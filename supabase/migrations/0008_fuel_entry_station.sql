-- Sprint 6.P — Tracker de preço por posto
-- Adiciona station_name e station_brand à tabela fuel_entries.
ALTER TABLE public.fuel_entries ADD COLUMN IF NOT EXISTS station_name text;
ALTER TABLE public.fuel_entries ADD COLUMN IF NOT EXISTS station_brand text;
