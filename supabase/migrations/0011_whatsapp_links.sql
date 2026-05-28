CREATE TABLE IF NOT EXISTS public.whatsapp_links (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number text NOT NULL UNIQUE,
  paired_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.whatsapp_pending_codes (
  code text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.whatsapp_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_pending_codes ENABLE ROW LEVEL SECURITY;
-- Service role bypassa RLS (edge fns).
CREATE POLICY "wa_links_self" ON public.whatsapp_links
  FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "wa_codes_self" ON public.whatsapp_pending_codes
  FOR ALL TO authenticated USING (user_id = auth.uid());
