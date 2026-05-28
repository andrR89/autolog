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

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Only accept POST.
  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405);
  }

  // --- 1. Auth: extract JWT and identify user (owner) ---
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json({ error: 'missing_authorization' }, 401);
  }
  const jwt = authHeader.replace(/^Bearer\s+/i, '');

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Service-role client — bypasses RLS para operações admin.
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'unauthorized' }, 401);
  }
  const ownerId = user.id;

  // --- 2. Parse and validate request body ---
  let vehicle_id: string;
  let member_email: string;
  try {
    const body = await req.json();
    if (!body.vehicle_id || typeof body.vehicle_id !== 'string') {
      return json({ error: 'missing_vehicle_id' }, 400);
    }
    if (!body.member_email || typeof body.member_email !== 'string') {
      return json({ error: 'missing_member_email' }, 400);
    }
    vehicle_id = body.vehicle_id.trim();
    member_email = body.member_email.trim().toLowerCase();
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  if (!member_email.includes('@')) {
    return json({ error: 'invalid_email' }, 400);
  }

  // --- 3. Verify requesting user owns the vehicle ---
  const { data: vehicle, error: vehicleError } = await supabase
    .from('vehicles')
    .select('id, user_id')
    .eq('id', vehicle_id)
    .eq('user_id', ownerId)
    .is('deleted_at', null)
    .maybeSingle();

  if (vehicleError) {
    console.error('Error fetching vehicle:', vehicleError);
    return json({ error: 'server_error' }, 500);
  }
  if (!vehicle) {
    return json({ error: 'forbidden' }, 403);
  }

  // --- 4. Look up the target user by email (via service role admin API) ---
  // listUsers returns paginated results; we filter client-side.
  // For production scale consider a DB index on email or a custom lookup.
  let memberUserId: string | null = null;
  try {
    const { data: usersData, error: listError } = await supabase.auth.admin.listUsers({
      perPage: 1000,
    });
    if (listError) {
      console.error('Error listing users:', listError);
      return json({ error: 'server_error' }, 500);
    }
    const found = usersData?.users?.find(
      (u) => u.email?.toLowerCase() === member_email,
    );
    if (found) {
      memberUserId = found.id;
    }
  } catch (e) {
    console.error('Failed to list users:', e);
    return json({ error: 'server_error' }, 500);
  }

  if (!memberUserId) {
    return json({ error: 'email_not_found' }, 404);
  }

  // Prevent owner from adding themselves.
  if (memberUserId === ownerId) {
    return json({ error: 'cannot_add_self' }, 400);
  }

  // --- 5. Insert into vehicle_members (idempotent via ON CONFLICT DO NOTHING) ---
  const { error: insertError } = await supabase
    .from('vehicle_members')
    .upsert(
      {
        vehicle_id,
        user_id: memberUserId,
        role: 'member',
      },
      { onConflict: 'vehicle_id,user_id', ignoreDuplicates: true },
    );

  if (insertError) {
    console.error('Error inserting vehicle_member:', insertError);
    return json({ error: 'server_error' }, 500);
  }

  // --- 6. Return success ---
  return json({ ok: true, member_user_id: memberUserId });
});
