-- Sprint 6.MM — Lembretes recorrentes (schema Drift v17→v18).
-- Adicionado em 25/05/2026, mas a migration SQL equivalente nunca foi
-- aplicada no Supabase remoto. Sintoma no web (26/06): sync de reminders
-- falha com PGRST204 "Could not find the 'interval_days' column of 'reminders'
-- in the schema cache" e o indicador acende cloud_off.
--
-- Semântica:
--   * intervalDays   → exige dueDate (lembrete por data com recorrência).
--   * intervalKm     → exige dueKm  (lembrete por km com recorrência).
--   * parentReminderId → id do lembrete que originou este, para
--     rastreabilidade de "marcou done → próximo aparece automático".
--   * Ambos null = one-shot (comportamento original, retrocompatível).

ALTER TABLE public.reminders
  ADD COLUMN IF NOT EXISTS interval_days       integer,
  ADD COLUMN IF NOT EXISTS interval_km         integer,
  ADD COLUMN IF NOT EXISTS parent_reminder_id  uuid
    REFERENCES public.reminders(id) ON DELETE SET NULL;

-- PostgREST cacheia o schema em memória; sem reload as colunas novas
-- não ficam visíveis na API mesmo depois do ALTER TABLE.
NOTIFY pgrst, 'reload schema';
