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
// Stats computation
// ---------------------------------------------------------------------------

interface ComputedStats {
  currentOdometerKm: number | null;
  totalKmDriven: number | null;
  avgConsumptionKmL: number | null;
  favoriteStation: string | null;
  topExpenseCategory: string | null;
  activeRemindersCount: number;
  cheapestPpl: number | null;
  mostExpensivePpl: number | null;
}

function computeStats(
  fuelEntries: any[],
  expenses: any[],
  reminders: any[],
): ComputedStats {
  // Odometer stats.
  const odometerValues = fuelEntries
    .map((f) => parseInt(f.odometer, 10))
    .filter((v) => isFinite(v));
  const currentOdometerKm =
    odometerValues.length > 0 ? Math.max(...odometerValues) : null;
  const minOdometer =
    odometerValues.length > 0 ? Math.min(...odometerValues) : null;
  const totalKmDriven =
    currentOdometerKm != null && minOdometer != null
      ? currentOdometerKm - minOdometer
      : null;

  // Average consumption: only when >= 2 fuel entries.
  let avgConsumptionKmL: number | null = null;
  if (fuelEntries.length >= 2 && totalKmDriven != null && totalKmDriven > 0) {
    const totalLiters = fuelEntries.reduce(
      (sum: number, f) => sum + (parseFloat(f.liters) || 0),
      0,
    );
    if (totalLiters > 0) {
      avgConsumptionKmL = totalKmDriven / totalLiters;
    }
  }

  // Favorite station: top (brand || name) normalized, counted by entriesCount.
  const stationCount: Record<string, number> = {};
  for (const f of fuelEntries) {
    const brand = (f.station_brand ?? '').trim();
    const name = (f.station_name ?? '').trim();
    const key = brand || name;
    if (key) {
      stationCount[key] = (stationCount[key] ?? 0) + 1;
    }
  }
  let favoriteStation: string | null = null;
  let favoriteCount = 0;
  for (const [station, count] of Object.entries(stationCount)) {
    if (count > favoriteCount) {
      favoriteCount = count;
      favoriteStation = station;
    }
  }
  if (favoriteStation && favoriteCount > 0) {
    favoriteStation = `${favoriteStation} (${favoriteCount} visitas)`;
  }

  // Top expense category.
  const categoryCount: Record<string, number> = {};
  for (const e of expenses) {
    const cat = (e.category ?? '').trim();
    if (cat) {
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }
  }
  let topExpenseCategory: string | null = null;
  let topCatCount = 0;
  for (const [cat, count] of Object.entries(categoryCount)) {
    if (count > topCatCount) {
      topCatCount = count;
      topExpenseCategory = cat;
    }
  }

  // Active reminders count: not done, not deleted.
  const activeRemindersCount = reminders.filter(
    (r) => !r.is_done && !r.deleted_at,
  ).length;

  // Price per liter min/max.
  const ppls = fuelEntries
    .map((f) => parseFloat(f.price_per_liter))
    .filter((v) => isFinite(v) && v > 0);
  const cheapestPpl = ppls.length > 0 ? Math.min(...ppls) : null;
  const mostExpensivePpl = ppls.length > 0 ? Math.max(...ppls) : null;

  return {
    currentOdometerKm,
    totalKmDriven,
    avgConsumptionKmL,
    favoriteStation,
    topExpenseCategory,
    activeRemindersCount,
    cheapestPpl,
    mostExpensivePpl,
  };
}

// ---------------------------------------------------------------------------
// Prompt PT-BR estruturado
// ---------------------------------------------------------------------------

function buildSystemPrompt(
  vehicle: Record<string, unknown>,
  fuelEntries: any[],
  expenses: any[],
  reminders: any[],
): string {
  const stats = computeStats(fuelEntries, expenses, reminders);

  // Vehicle line: year make model • placa • type • cor • uf
  // NOTE: renavam e chassi são omitidos por privacidade (Regra de Ouro).
  const vehicleHeader = [
    vehicle.year,
    vehicle.make,
    vehicle.model,
  ]
    .filter(Boolean)
    .join(' ');

  const vehicleMeta = [
    vehicle.plate ? `placa ${vehicle.plate}` : null,
    vehicle.type ?? null,
    vehicle.color ? `cor ${vehicle.color}` : null,
    vehicle.uf ?? null,
  ]
    .filter(Boolean)
    .join(' • ');

  const vehicleLine = vehicleHeader
    ? `${vehicleHeader}${vehicleMeta ? ' • ' + vehicleMeta : ''}`
    : 'não informado';

  // Specs line.
  const engineCc = vehicle.engine_displacement_cc;
  const tankL = vehicle.tank_capacity_l;
  const hp = vehicle.horsepower;
  const specsLine =
    engineCc || tankL || hp
      ? [
          engineCc ? `Cilindrada: ${engineCc} cc` : null,
          tankL ? `Tanque: ${tankL} L` : null,
          hp ? `Potência: ${hp} cv` : null,
        ]
          .filter(Boolean)
          .join(' · ')
      : null;

  // FIPE line.
  const fipeValue = vehicle.fipe_value;
  const fipeRef = vehicle.fipe_reference_month;
  const fipeLine =
    fipeValue
      ? `FIPE: R$ ${parseFloat(fipeValue as string).toLocaleString('pt-BR', { minimumFractionDigits: 0 })}${fipeRef ? ` (${fipeRef})` : ''}`
      : null;

  // Consumption display.
  const consumptionDisplay =
    stats.avgConsumptionKmL != null
      ? `${stats.avgConsumptionKmL.toFixed(1).replace('.', ',')} km/L`
      : '—';

  // Price per liter display.
  const pplDisplay =
    stats.cheapestPpl != null && stats.mostExpensivePpl != null
      ? `R$ ${stats.cheapestPpl.toFixed(2).replace('.', ',')} (mín) a R$ ${stats.mostExpensivePpl.toFixed(2).replace('.', ',')} (máx)`
      : '—';

  // Compact history.
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
    .filter((r: any) => !r.is_done && !r.deleted_at)
    .map(
      (r: any) =>
        `${r.title} | vence: ${r.due_date?.slice(0, 10) ?? (r.due_km ? `${r.due_km}km` : 'N/A')}`,
    )
    .join('\n');

  return `Você é o assistente do AutoLog. Responda em PT-BR com base no contexto abaixo.
Seja direto, objetivo, útil. Se não tiver dado pra responder, diga "Não tenho dados pra responder isso" — nunca invente.

# Veículo do usuário
${vehicleLine}${specsLine ? '\n' + specsLine : ''}${fipeLine ? '\n' + fipeLine : ''}

# Stats agregadas (últimos 36 meses)
Odômetro atual: ${stats.currentOdometerKm != null ? stats.currentOdometerKm.toLocaleString('pt-BR') + ' km' : '—'} · Total rodado: ${stats.totalKmDriven != null ? stats.totalKmDriven.toLocaleString('pt-BR') + ' km' : '—'}
Consumo médio: ${consumptionDisplay}
Posto preferido: ${stats.favoriteStation ?? '—'}
Categoria de despesa mais frequente: ${stats.topExpenseCategory ?? '—'}
Preço gasolina: ${pplDisplay}
Lembretes ativos: ${stats.activeRemindersCount}

# Histórico bruto
## Últimos abastecimentos (até 20)
${fuelCompact || '(nenhum)'}

## Últimas despesas (até 20)
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
  // NOTE: renavam and chassi are intentionally excluded for privacy.
  const { data: vehicle } = await supabase
    .from('vehicles')
    .select(
      'id,user_id,year,make,model,plate,type,color,uf,' +
      'engine_displacement_cc,tank_capacity_l,horsepower,' +
      'fipe_value,fipe_reference_month,initial_odometer',
    )
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
    .select('date,odometer,liters,total_cost,fuel_type,price_per_liter,station_brand,station_name')
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
    .select('title,due_date,due_km,type,is_done,deleted_at')
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
