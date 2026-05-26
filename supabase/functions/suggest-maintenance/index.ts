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
// Empty fallback response (parse failure)
// ---------------------------------------------------------------------------

const EMPTY_RESPONSE = { items: [] };

// ---------------------------------------------------------------------------
// Prompt PT-BR
// ---------------------------------------------------------------------------

function buildPrompt(
  type: string,
  make: string,
  model: string,
  year: number,
  engineCc?: number,
  tankL?: string,
  uf?: string,
  odometerKm?: number,
): string {
  const extras = [
    engineCc != null ? `  Cilindrada: ${engineCc} cc` : null,
    tankL != null ? `  Tanque: ${tankL} L` : null,
    uf != null ? `  UF: ${uf}` : null,
    odometerKm != null
      ? `  Quilometragem atual: ${odometerKm.toLocaleString('pt-BR')} km`
      : null,
  ]
    .filter(Boolean)
    .join('\n');

  const regionalSuffix = [
    uf != null
      ? '- Se UF for litorânea (RJ, SP, BA, CE, PE, ES, SC, etc.), considere itens de prevenção a corrosão (revisão de partes metálicas, pintura).'
      : null,
    odometerKm != null && odometerKm >= 80000
      ? '- Quilometragem >= 80.000 km: priorize correia dentada, embreagem, suspensão e amortecedores.'
      : null,
    year <= 2010
      ? '- Ano <= 2010: mencione revisão de mangueiras, borrachas e juntas.'
      : null,
  ]
    .filter(Boolean)
    .join('\n');

  return `Você é especialista em manutenção de veículos brasileiros.
Dado:
  Tipo: ${type}
  Marca: ${make}
  Modelo: ${model}
  Ano: ${year}${extras ? '\n' + extras : ''}

Liste 4 a 10 itens de manutenção típicos para esse veículo.
Para cada um, indique a cadência (a cada N km, N meses, ou ambos — o que ocorrer primeiro).

Responda APENAS com JSON, sem markdown.
Schema:
{
  "items": [
    {
      "task": string,
      "cadence_type": "km" | "months" | "km_or_months",
      "every_km": int|null,
      "every_months": int|null,
      "notes": string|null
    }
  ]
}

Regras:
- Foque em manutenções padrão: óleo, filtros, freios, correia dentada, velas, fluidos, etc.
- Use intervalos típicos brasileiros para esse modelo e ano.
- Se type=moto, inclua itens específicos de moto (corrente, kit relação, etc.).
- Se type=carro, não inclua itens exclusivos de moto.
- cadence_type: use "km" quando a cadência é só por km, "months" quando só por tempo, "km_or_months" quando for o que ocorrer primeiro.
- every_km deve ser int positivo ou null; every_months deve ser int positivo ou null.
- notes é opcional — use para observações importantes (ex: "Use óleo sintético 5W30").
- Nunca invente dados sem base; prefira omitir a fabricar intervalos incorretos.${regionalSuffix ? '\n' + regionalSuffix : ''}`;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

const VALID_CADENCE_TYPES = new Set(['km', 'months', 'km_or_months']);

function toPositiveIntOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  if (!isFinite(value)) return null;
  const int = Math.round(value);
  if (int <= 0) return null;
  return int;
}

function toStringOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

interface MaintenanceItem {
  task: string;
  cadence_type: string;
  every_km: number | null;
  every_months: number | null;
  notes: string | null;
}

function validateItem(raw: unknown): MaintenanceItem | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const obj = raw as Record<string, unknown>;

  // task: non-empty string required.
  const task = toStringOrNull(obj['task']);
  if (!task) return null;

  // cadence_type: must be one of the valid values.
  const cadenceType = obj['cadence_type'];
  if (typeof cadenceType !== 'string' || !VALID_CADENCE_TYPES.has(cadenceType)) {
    return null;
  }

  const everyKm = toPositiveIntOrNull(obj['every_km']);
  const everyMonths = toPositiveIntOrNull(obj['every_months']);
  const notes = toStringOrNull(obj['notes']);

  return {
    task,
    cadence_type: cadenceType,
    every_km: everyKm,
    every_months: everyMonths,
    notes,
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

  // --- 2. Parse and validate request body ---
  let vehicleType: string;
  let make: string;
  let model: string;
  let year: number;
  let engineDisplacementCc: number | undefined;
  let tankCapacityL: string | undefined;
  let vehicleUf: string | undefined;
  let currentOdometerKm: number | undefined;

  try {
    const body = await req.json();

    if (!body.type || typeof body.type !== 'string' || !['carro', 'moto'].includes(body.type)) {
      return json({ error: 'invalid_type', detail: 'type must be "carro" or "moto"' }, 400);
    }
    if (!body.make || typeof body.make !== 'string' || body.make.trim() === '') {
      return json({ error: 'invalid_make', detail: 'make must be a non-empty string' }, 400);
    }
    if (!body.model || typeof body.model !== 'string' || body.model.trim() === '') {
      return json({ error: 'invalid_model', detail: 'model must be a non-empty string' }, 400);
    }
    if (typeof body.year !== 'number' || !isFinite(body.year)) {
      return json({ error: 'invalid_year', detail: 'year must be a number' }, 400);
    }

    const currentYear = new Date().getFullYear();
    const yearInt = Math.round(body.year);
    if (yearInt < 1900 || yearInt > currentYear + 1) {
      return json({ error: 'invalid_year', detail: `year must be between 1900 and ${currentYear + 1}` }, 400);
    }

    vehicleType = body.type.trim();
    make = body.make.trim();
    model = body.model.trim();
    year = yearInt;

    // Optional fields.
    if (body.engine_displacement_cc != null && typeof body.engine_displacement_cc === 'number') {
      const cc = Math.round(body.engine_displacement_cc);
      if (cc >= 50 && cc <= 9999) engineDisplacementCc = cc;
    }
    if (body.tank_capacity_l != null && typeof body.tank_capacity_l === 'string') {
      const parsed = parseFloat(body.tank_capacity_l);
      if (isFinite(parsed) && parsed > 0 && parsed <= 500) {
        tankCapacityL = body.tank_capacity_l;
      }
    }
    // New optional params (6.W.1).
    if (typeof body.vehicle_uf === 'string') {
      vehicleUf = body.vehicle_uf;
    }
    if (typeof body.current_odometer_km === 'number') {
      currentOdometerKm = Math.round(body.current_odometer_km);
    }
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 3. Quota check — shared scan_count (limit 5/mês free) ---
  const currentMonth = new Date().toISOString().slice(0, 7); // "YYYY-MM"

  const { data: quotaRow } = await supabase
    .from('usage_quota')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  const isPremium: boolean = quotaRow?.is_premium ?? false;
  const effectiveCount: number =
    quotaRow?.month === currentMonth ? (quotaRow.scan_count as number ?? 0) : 0;

  if (!isPremium && effectiveCount >= 5) {
    return json({ error: 'quota_exhausted' }, 429);
  }

  // --- 4. Call Claude Haiku 4.5 ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

  const prompt = buildPrompt(
    vehicleType,
    make,
    model,
    year,
    engineDisplacementCc,
    tankCapacityL,
    vehicleUf,
    currentOdometerKm,
  );

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
        max_tokens: 1024,
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

  // --- 5. Defensive parse ---
  // Strip markdown code fences if present.
  let stripped = claudeText.trim();
  stripped = stripped.replace(/^```(json)?/m, '').replace(/```$/m, '').trim();

  let rawItems: unknown[] = [];
  try {
    const maybeObj = JSON.parse(stripped);
    if (maybeObj && typeof maybeObj === 'object' && !Array.isArray(maybeObj)) {
      const parsed = maybeObj as Record<string, unknown>;
      if (Array.isArray(parsed['items'])) {
        rawItems = parsed['items'] as unknown[];
      }
    }
  } catch {
    // Parse failure → return empty without incrementing quota.
    console.warn('Claude response was not valid JSON; returning empty schedule.');
    return json(EMPTY_RESPONSE);
  }

  // --- 6. Validate and filter items ---
  const items: MaintenanceItem[] = rawItems
    .map(validateItem)
    .filter((item): item is MaintenanceItem => item !== null);

  // --- 7. Increment quota only if items were returned ---
  if (items.length > 0) {
    try {
      await supabase.from('usage_quota').upsert({
        user_id: userId,
        month: currentMonth,
        scan_count: effectiveCount + 1,
        is_premium: isPremium,
      });
    } catch (e) {
      // Non-fatal: log and continue.
      console.error('Failed to increment quota:', e);
    }
  }

  // --- 8. Return schedule ---
  return json({ items });
});
