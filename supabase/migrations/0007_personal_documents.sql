-- Sprint 6.O — Documentos pessoais: CNH (user_profile), multas (fines), seguros (insurances)

CREATE TABLE IF NOT EXISTS public.user_profile (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  cnh_number text,
  cnh_category text,
  cnh_expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  sync_status text NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS public.fines (
  id uuid PRIMARY KEY,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  auto_number text,
  issued_at timestamptz NOT NULL,
  description text NOT NULL,
  amount text NOT NULL,
  due_date timestamptz,
  paid boolean NOT NULL DEFAULT false,
  points int,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  sync_status text NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS public.insurances (
  id uuid PRIMARY KEY,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  insurer text,
  policy_number text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  premium_paid text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  sync_status text NOT NULL DEFAULT 'pending'
);

-- RLS
ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insurances ENABLE ROW LEVEL SECURITY;

-- user_profile: user só vê o próprio
CREATE POLICY "user_profile_own" ON public.user_profile
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- fines/insurances: user vê os de veículos seus (via join)
CREATE POLICY "fines_own_via_vehicle" ON public.fines
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  );

CREATE POLICY "insurances_own_via_vehicle" ON public.insurances
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  );
