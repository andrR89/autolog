import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/// Gera um código aleatório de 6 dígitos numéricos como string.
function generateCode(): string {
  const num = Math.floor(Math.random() * 1_000_000);
  return num.toString().padStart(6, '0');
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Only accept POST.
  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405);
  }

  // --- 1. Auth: extract JWT and identify user ---
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json({ error: 'missing_authorization' }, 401);
  }
  const jwt = authHeader.replace(/^Bearer\s+/i, '');

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Service-role client bypasses RLS para operações admin.
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'unauthorized' }, 401);
  }
  const userId = user.id;

  // --- 2. Limpa códigos antigos do mesmo usuário (máximo 1 pendente por vez) ---
  await supabase
    .from('whatsapp_pending_codes')
    .delete()
    .eq('user_id', userId);

  // --- 3. Gera e persiste o novo código ---
  const code = generateCode();

  const { error: insertError } = await supabase
    .from('whatsapp_pending_codes')
    .insert({ code, user_id: userId });

  if (insertError) {
    console.error('Error inserting pending code:', insertError);
    return json({ error: 'server_error' }, 500);
  }

  // --- 4. Retorna código ---
  return json({ code });
});
