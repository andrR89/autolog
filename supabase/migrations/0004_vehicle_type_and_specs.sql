-- Sprint 6.H — Tipo de veículo + specs técnicos
-- Adiciona: type (carro/moto), engine_displacement_cc, tank_capacity_l, horsepower
-- Ref: docs/specs/sprint-6.H-vehicle-type-and-specs.md

ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'carro';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS engine_displacement_cc integer;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS tank_capacity_l text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS horsepower integer;
