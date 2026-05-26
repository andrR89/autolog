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
// Prompt PT-BR estruturado
// ---------------------------------------------------------------------------

function buildSystemPrompt(
  vehicle: Record<string, unknown>,
  fuelEntries: unknown[],
  expenses: unknown[],
  reminders: unknown[],
): string {
  const vehicleLine = [
    vehicle.year,
    vehicle.make,
    vehicle.model,
    vehicle.uf ? `(${vehicle.uf})` : null,
  ]
    .filter(Boolean)
    .join(' ');

  // Estatísticas agregadas simples
  const totalFuelCost = fuelEntries.reduce(
    (sum: number, f: any) => sum + (parseFloat(f.total_cost) || 0),
    0,
  );
  const totalFuelLiters = fuelEntries.reduce(
    (sum: number, f: any) => sum + (parseFloat(f.liters) || 0),
    0,
  );
  const avgPricePerLiter =
    totalFuelLiters > 0 ? totalFuelCost / totalFuelLiters : 0;

  const totalExpenses = expenses.reduce(
    (sum: number, e: any) => sum + (parseFloat(e.amount) || 0),
    0,
  );

  const fuelCompact = fuelEntries
    .slice(-20)
    .map(
      (f: any) =>
        `${f.date?.slice(0, 10)} | ${f.fuel_type} | ${f.liters}L | R$${f.total_cost} | ${f.odometer}km`,
    )
    .join('\n');

  const expensesCompact = expenses
    .slice(-20)
    .map(
      (e: any) =>
        `${e.date?.slice(0, 10)} | ${e.category} | R$${e.amount} | ${e.description ?? ''}`,
    )
    .join('\n');

  const remindersCompact = reminders
    .map(
      (r: any) =>
        `${r.title} | vence: ${r.due_date?.slice(0, 10) ?? r.due_km ? `${r.due_km}km` : 'N/A'}`,
    )
    .join('\n');

  return `Você é um assistente do AutoLog. Responda em PT-BR baseando-se no histórico do veículo ${vehicleLine || 'não informado'} fornecido abaixo. Seja direto e útil. Se não tiver dado pra responder, diga "Não tenho dados pra responder isso".

# Contexto do veículo

Veículo: ${vehicleLine || 'não informado'}

## Estatísticas (últimos 36 meses)
- Total gasto com combustível: R$${totalFuelCost.toFixed(2)}
- Total litros abastecidos: ${totalFuelLiters.toFixed(1)}L
- Preço médio por litro: R$${avgPricePerLiter.toFixed(3)}
- Total gasto com despesas: R$${totalExpenses.toFixed(2)}
- Número de abastecimentos: ${fuelEntries.length}
- Número de despesas registradas: ${expenses.length}

## Últimos abastecimentos
${fuelCompact || '(nenhum)'}

## Últimas despesas
${expensesCompact || '(nenhuma)'}

## Lembretes ativos
${remindersCompact || '(nenhum)'}`;
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

  // Service-role client bypasses RLS for atomic quota writes.
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'unauthorized' }, 401);
  }
  const userId = user.id;

  // --- 2. Parse request body ---
  let vehicle_id: string;
  let user_message: string;
  let recent_history: Array<{ role: string; content: string }> = [];

  try {
    const body = await req.json();

    if (
      !body.vehicle_id ||
      typeof body.vehicle_id !== 'string' ||
      body.vehicle_id.trim() === ''
    ) {
      return json({ error: 'missing_vehicle_id' }, 400);
    }
    if (
      !body.user_message ||
      typeof body.user_message !== 'string' ||
      body.user_message.trim() === ''
    ) {
      return json({ error: 'missing_user_message' }, 400);
    }

    vehicle_id = body.vehicle_id.trim();
    user_message = body.user_message.trim();

    if (Array.isArray(body.recent_history)) {
      recent_history = body.recent_history
        .filter(
          (m: any) =>
            m &&
            typeof m.role === 'string' &&
            typeof m.content === 'string',
        )
        .map((m: any) => ({ role: m.role, content: m.content }));
    }
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 3. Quota check (chat_count, limit 10/mês free) ---
  const currentMonth = new Date().toISOString().slice(0, 7); // "YYYY-MM"

  const { data: quotaRow } = await supabase
    .from('usage_quota')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  const isPremium: boolean = quotaRow?.is_premium ?? false;
  const effectiveCount: number =
    quotaRow?.month === currentMonth
      ? (quotaRow.chat_count as number ?? 0)
      : 0;

  if (!isPremium && effectiveCount >= 10) {
    return json({ error: 'quota_exhausted' }, 429);
  }

  // --- 4. Load vehicle (verify ownership) ---
  const { data: vehicle } = await supabase
    .from('vehicles')
    .select('*')
    .eq('id', vehicle_id)
    .eq('user_id', userId)
    .maybeSingle();

  if (!vehicle) {
    return json({ error: 'vehicle_not_found' }, 404);
  }

  // --- 5. Load history (last 36 months) ---
  const since = new Date();
  since.setMonth(since.getMonth() - 36);
  const sinceIso = since.toISOString();

  const { data: fuelEntries } = await supabase
    .from('fuel_entries')
    .select('date,odometer,liters,total_cost,fuel_type')
    .eq('vehicle_id', vehicle_id)
    .is('deleted_at', null)
    .gte('date', sinceIso)
    .order('date');

  const { data: expenses } = await supabase
    .from('expenses')
    .select('date,category,description,amount,odometer')
    .eq('vehicle_id', vehicle_id)
    .is('deleted_at', null)
    .gte('date', sinceIso)
    .order('date');

  const { data: reminders } = await supabase
    .from('reminders')
    .select('title,due_date,due_km,type')
    .eq('vehicle_id', vehicle_id)
    .is('deleted_at', null)
    .eq('is_done', false);

  // --- 6. Build messages for Claude ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

  const systemPrompt = buildSystemPrompt(
    vehicle,
    fuelEntries ?? [],
    expenses ?? [],
    reminders ?? [],
  );

  // Monta o histórico de conversa + nova mensagem do usuário
  const messages: Array<{ role: string; content: string }> = [
    ...recent_history,
    { role: 'user', content: user_message },
  ];

  // --- 7. Call Claude Haiku 4.5 ---
  let assistantContent: string;
  try {
    const claudeResp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5',
        max_tokens: 800,
        system: systemPrompt,
        messages,
      }),
    });

    if (!claudeResp.ok) {
      const errBody = await claudeResp.text();
      console.error(`Anthropic API error ${claudeResp.status}: ${errBody}`);
      return json({ error: 'ai_service_error' }, 502);
    }

    const claudeData = await claudeResp.json();
    assistantContent = claudeData?.content?.[0]?.text ?? '';
  } catch (e) {
    console.error('Failed to call Anthropic API:', e);
    return json({ error: 'ai_service_error' }, 502);
  }

  // --- 8. Increment chat_count on success ---
  try {
    await supabase.from('usage_quota').upsert({
      user_id: userId,
      month: currentMonth,
      chat_count: effectiveCount + 1,
      is_premium: isPremium,
    });
  } catch (e) {
    // Non-fatal: log and continue.
    console.error('Failed to increment chat quota:', e);
  }

  // --- 9. Return result ---
  return json({ content: assistantContent });
});
