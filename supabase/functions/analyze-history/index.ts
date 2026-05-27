import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { readQuota, incrementQuota } from '../_shared/quota.ts';

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
// Empty analysis response (safe fallback)
// ---------------------------------------------------------------------------

const EMPTY_RESPONSE = { patterns: [], proposed_reminders: [] };

// ---------------------------------------------------------------------------
// Prompt PT-BR estruturado
// ---------------------------------------------------------------------------

function buildPrompt(vehicle: Record<string, unknown>, expenses: unknown[], fuelEntries: unknown[]): string {
  const vehicleLine = [
    vehicle.year,
    vehicle.make,
    vehicle.model,
    vehicle.uf ? `(${vehicle.uf})` : null,
  ].filter(Boolean).join(' ');

  const expensesCompact = expenses.map((e: any) =>
    `${e.date?.slice(0, 10)} | ${e.category} | ${e.amount ?? '-'} | ${e.description ?? ''}`
  ).join('\n');

  const fuelCompact = fuelEntries.map((f: any) =>
    `${f.date?.slice(0, 10)} | ${f.fuel_type} | ${f.liters}L | R$${f.total_cost} | ${f.odometer}km`
  ).join('\n');

  return `Você é um assistente de gestão veicular brasileiro. Analise o histórico abaixo e identifique padrões e sugira lembretes proativos.

Veículo: ${vehicleLine || 'não informado'}

=== DESPESAS (últimos 36 meses) ===
${expensesCompact || '(nenhuma)'}

=== ABASTECIMENTOS (últimos 36 meses) ===
${fuelCompact || '(nenhum)'}

Com base nesse histórico, identifique:
1. Padrões recorrentes (ex: IPVA todo janeiro, manutenção a cada 10mil km).
2. Lembretes proativos baseados nesses padrões.

Responda APENAS com JSON válido, sem markdown, sem explicação.
Schema:
{
  "patterns": [
    {
      "category": string,     // ex: "ipva", "manutencao_periodica", "seguro"
      "cadence": string,      // "yearly" | "monthly" | "every_N_km" | "unknown"
      "next_due": string | null, // ISO-8601 UTC ou null
      "confidence": number,   // 0.0 a 1.0
      "rationale": string | null
    }
  ],
  "proposed_reminders": [
    {
      "title": string,
      "due_date": string | null, // ISO-8601 UTC ou null
      "due_km": number | null,
      "rationale": string
    }
  ]
}

Se não houver dados suficientes para identificar padrões, retorne listas vazias.
Nunca invente dados. Seja conservador na confiança se o histórico for curto.`;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

function toStringOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed;
}

function toDateIsoOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  try {
    const d = new Date(value);
    if (isNaN(d.getTime())) return null;
    return d.toISOString();
  } catch {
    return null;
  }
}

function toConfidence(value: unknown): number {
  if (typeof value !== 'number') return 0.0;
  if (!isFinite(value)) return 0.0;
  return Math.min(1.0, Math.max(0.0, value));
}

function toIntOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  if (!isFinite(value) || value < 0) return null;
  return Math.floor(value);
}

function validatePattern(p: unknown): Record<string, unknown> | null {
  if (!p || typeof p !== 'object' || Array.isArray(p)) return null;
  const obj = p as Record<string, unknown>;
  const category = toStringOrNull(obj['category']);
  const cadence = toStringOrNull(obj['cadence']);
  if (!category || !cadence) return null;
  return {
    category,
    cadence,
    next_due: toDateIsoOrNull(obj['next_due']),
    confidence: toConfidence(obj['confidence']),
    rationale: toStringOrNull(obj['rationale']),
  };
}

function validateProposed(r: unknown): Record<string, unknown> | null {
  if (!r || typeof r !== 'object' || Array.isArray(r)) return null;
  const obj = r as Record<string, unknown>;
  const title = toStringOrNull(obj['title']);
  if (!title) return null;
  return {
    title,
    due_date: toDateIsoOrNull(obj['due_date']),
    due_km: toIntOrNull(obj['due_km']),
    rationale: toStringOrNull(obj['rationale']) ?? '',
  };
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

  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'unauthorized' }, 401);
  }
  const userId = user.id;

  // --- 2. Parse request body ---
  let vehicle_id: string;
  try {
    const body = await req.json();
    if (!body.vehicle_id || typeof body.vehicle_id !== 'string' || body.vehicle_id.trim() === '') {
      return json({ error: 'missing_vehicle_id' }, 400);
    }
    vehicle_id = body.vehicle_id.trim();
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 3. Quota check (analysis_count, limit 3/mês free) ---
  const { effective, isPremium, currentMonth } = await readQuota(supabase, userId);

  if (!isPremium && effective.analysis >= 3) {
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

  const { data: expenses } = await supabase
    .from('expenses')
    .select('date,category,description,amount,odometer')
    .eq('vehicle_id', vehicle_id)
    .is('deleted_at', null)
    .gte('date', sinceIso)
    .order('date');

  const { data: fuelEntries } = await supabase
    .from('fuel_entries')
    .select('date,odometer,liters,total_cost,fuel_type')
    .eq('vehicle_id', vehicle_id)
    .is('deleted_at', null)
    .gte('date', sinceIso)
    .order('date');

  // --- 6. Call Claude Haiku 4.5 ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

  const prompt = buildPrompt(vehicle, expenses ?? [], fuelEntries ?? []);

  let claudeText: string;
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
        max_tokens: 2048,
        messages: [
          {
            role: 'user',
            content: [{ type: 'text', text: prompt }],
          },
        ],
      }),
    });

    if (!claudeResp.ok) {
      const errBody = await claudeResp.text();
      console.error(`Anthropic API error ${claudeResp.status}: ${errBody}`);
      return json({ error: 'ai_service_error' }, 502);
    }

    const claudeData = await claudeResp.json();
    claudeText = claudeData?.content?.[0]?.text ?? '';
  } catch (e) {
    console.error('Failed to call Anthropic API:', e);
    return json({ error: 'ai_service_error' }, 502);
  }

  // --- 7. Defensive parse ---
  let stripped = claudeText.trim();
  stripped = stripped.replace(/^```(json)?/m, '').replace(/```$/m, '').trim();

  let parsed: Record<string, unknown> = {};
  try {
    const maybeObj = JSON.parse(stripped);
    if (maybeObj && typeof maybeObj === 'object' && !Array.isArray(maybeObj)) {
      parsed = maybeObj as Record<string, unknown>;
    }
  } catch {
    console.warn('Claude response was not valid JSON; returning empty analysis.');
    // Parse failure → return empty without incrementing quota.
    return json(EMPTY_RESPONSE);
  }

  // --- 8. Validate shape ---
  const rawPatterns = Array.isArray(parsed['patterns']) ? parsed['patterns'] : [];
  const rawProposed = Array.isArray(parsed['proposed_reminders'])
    ? parsed['proposed_reminders']
    : [];

  const patterns = rawPatterns.map(validatePattern).filter(Boolean) as Record<string, unknown>[];
  const proposedReminders = rawProposed.map(validateProposed).filter(Boolean) as Record<string, unknown>[];

  // --- 9. Increment quota only if result is useful ---
  if (patterns.length > 0 || proposedReminders.length > 0) {
    try {
      await incrementQuota(supabase, {
        userId, currentMonth, effective, isPremium, field: 'analysis_count',
      });
    } catch (e) {
      // Non-fatal: log and continue.
      console.error('Failed to increment analysis quota:', e);
    }
  }

  // --- 10. Return result ---
  return json({ patterns, proposed_reminders: proposedReminders });
});
