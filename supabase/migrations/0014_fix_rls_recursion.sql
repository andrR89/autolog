-- Fix homologação 18/06 — RLS infinite recursion (Postgres 42P17)
--
-- Sintoma: TODA query em vehicles / fuel_entries / expenses / reminders /
-- fines / insurances retornava
--   "infinite recursion detected in policy for relation 'vehicles' (42P17)"
--
-- Causa: migration 0010 (vehicle_members) criou um loop circular —
--   vehicles policy faz `EXISTS (SELECT … FROM vehicle_members …)`,
--   e vehicle_members policy faz `EXISTS (SELECT … FROM vehicles …)`.
--   Cada SELECT dispara a policy da outra tabela, recursivamente.
--
-- Fix: dois helpers SECURITY DEFINER que bypassam RLS durante a checagem,
-- quebrando a recursão. Padrão recomendado pelo Supabase para este caso.

-- =============================================================================
-- 1. Helpers — SECURITY DEFINER (rodam com privilégios do owner; ignoram RLS)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.is_vehicle_member(p_vehicle_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.vehicle_members
    WHERE vehicle_id = p_vehicle_id
      AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_vehicle_owner(p_vehicle_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.vehicles
    WHERE id = p_vehicle_id
      AND user_id = auth.uid()
  );
$$;

-- Concede execução pra usuários autenticados (necessário pra policy chamar).
GRANT EXECUTE ON FUNCTION public.is_vehicle_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_vehicle_owner(uuid)  TO authenticated;

-- =============================================================================
-- 2. vehicles — usa helper em vez de subquery em vehicle_members
-- =============================================================================

DROP POLICY IF EXISTS "vehicles_owner_or_member" ON public.vehicles;
CREATE POLICY "vehicles_owner_or_member" ON public.vehicles
  FOR ALL TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_vehicle_member(id)
  )
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_vehicle_member(id)
  );

-- =============================================================================
-- 3. vehicle_members — usa helper em vez de subquery em vehicles
-- =============================================================================

DROP POLICY IF EXISTS "vehicle_members_owner_manages" ON public.vehicle_members;
CREATE POLICY "vehicle_members_owner_manages" ON public.vehicle_members
  FOR ALL TO authenticated
  USING (public.is_vehicle_owner(vehicle_id))
  WITH CHECK (public.is_vehicle_owner(vehicle_id));

-- A policy "vehicle_members_self_read" (SELECT) é direta (user_id = auth.uid())
-- e não causa recursão; mantém-se como está.

-- =============================================================================
-- 4. fuel_entries — substitui o EXISTS aninhado pelos helpers
-- =============================================================================

DROP POLICY IF EXISTS "fuel_entries_via_vehicle" ON public.fuel_entries;
CREATE POLICY "fuel_entries_via_vehicle" ON public.fuel_entries
  FOR ALL TO authenticated
  USING (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  )
  WITH CHECK (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  );

-- =============================================================================
-- 5. expenses
-- =============================================================================

DROP POLICY IF EXISTS "expenses_via_vehicle" ON public.expenses;
CREATE POLICY "expenses_via_vehicle" ON public.expenses
  FOR ALL TO authenticated
  USING (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  )
  WITH CHECK (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  );

-- =============================================================================
-- 6. reminders
-- =============================================================================

DROP POLICY IF EXISTS "reminders_via_vehicle" ON public.reminders;
CREATE POLICY "reminders_via_vehicle" ON public.reminders
  FOR ALL TO authenticated
  USING (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  )
  WITH CHECK (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  );

-- =============================================================================
-- 7. fines
-- =============================================================================

DROP POLICY IF EXISTS "fines_via_vehicle" ON public.fines;
CREATE POLICY "fines_via_vehicle" ON public.fines
  FOR ALL TO authenticated
  USING (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  )
  WITH CHECK (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  );

-- =============================================================================
-- 8. insurances
-- =============================================================================

DROP POLICY IF EXISTS "insurances_via_vehicle" ON public.insurances;
CREATE POLICY "insurances_via_vehicle" ON public.insurances
  FOR ALL TO authenticated
  USING (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  )
  WITH CHECK (
    public.is_vehicle_owner(vehicle_id)
    OR public.is_vehicle_member(vehicle_id)
  );
