-- Sprint 6.Y — Compartilhar veículo (multi-user via RLS)
-- Schema v15: nova tabela vehicle_members + atualização de policies.
--
-- DEPLOY: aplicar via `supabase db push` ou Supabase Dashboard > SQL Editor.
-- Após aplicar, deploy da Edge Function share-vehicle separadamente.

-- =============================================================================
-- 1. Tabela vehicle_members
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.vehicle_members (
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id)     ON DELETE CASCADE,
  role       text NOT NULL DEFAULT 'member',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (vehicle_id, user_id)
);

ALTER TABLE public.vehicle_members ENABLE ROW LEVEL SECURITY;

-- Dono do veículo gerencia membros (INSERT, UPDATE, DELETE, SELECT).
CREATE POLICY "vehicle_members_owner_manages" ON public.vehicle_members
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND v.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND v.user_id = auth.uid()
    )
  );

-- Membro vê sua própria row (para sync local).
CREATE POLICY "vehicle_members_self_read" ON public.vehicle_members
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- =============================================================================
-- 2. Atualiza policy de vehicles: dono OU membro pode ver e editar
-- =============================================================================

DROP POLICY IF EXISTS "Users see only their own vehicles" ON public.vehicles;

CREATE POLICY "vehicles_owner_or_member" ON public.vehicles
  FOR ALL TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.vehicle_members vm
      WHERE vm.vehicle_id = id
        AND vm.user_id = auth.uid()
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.vehicle_members vm
      WHERE vm.vehicle_id = id
        AND vm.user_id = auth.uid()
    )
  );

-- =============================================================================
-- 3. fuel_entries — dono OU membro do veículo
-- =============================================================================

DROP POLICY IF EXISTS "Users see own fuel entries" ON public.fuel_entries;

CREATE POLICY "fuel_entries_via_vehicle" ON public.fuel_entries
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  );

-- =============================================================================
-- 4. expenses — dono OU membro do veículo
-- =============================================================================

DROP POLICY IF EXISTS "Users see own expenses" ON public.expenses;

CREATE POLICY "expenses_via_vehicle" ON public.expenses
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  );

-- =============================================================================
-- 5. reminders — dono OU membro do veículo
-- =============================================================================

DROP POLICY IF EXISTS "Users see own reminders" ON public.reminders;

CREATE POLICY "reminders_via_vehicle" ON public.reminders
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  );

-- =============================================================================
-- 6. fines — dono OU membro do veículo
-- =============================================================================

DROP POLICY IF EXISTS "Users see own fines" ON public.fines;

CREATE POLICY "fines_via_vehicle" ON public.fines
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  );

-- =============================================================================
-- 7. insurances — dono OU membro do veículo
-- =============================================================================

DROP POLICY IF EXISTS "Users see own insurances" ON public.insurances;

CREATE POLICY "insurances_via_vehicle" ON public.insurances
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = vehicle_id
        AND (
          v.user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = v.id
              AND vm.user_id = auth.uid()
          )
        )
    )
  );
