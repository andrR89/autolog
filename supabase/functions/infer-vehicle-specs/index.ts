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

const EMPTY_RESPONSE = {
  engine_displacement_cc: null,
  tank_capacity_l: null,
  horsepower: null,
  confidence: 0.0,
};

// ---------------------------------------------------------------------------
// Prompt PT-BR
// ---------------------------------------------------------------------------

function buildPrompt(type: string, make: string, model: string, year: number): string {
  return `Você sabe specs técnicas de veículos brasileiros.
Dado:
  Tipo: ${type}
  Marca: ${make}
  Modelo: ${model}
  Ano: ${year}

Responda APENAS com JSON, sem markdown.
Schema: {
  "engine_displacement_cc": int|null,
  "tank_capacity_l": number|null,
  "horsepower": int|null,
  "confidence": number entre 0 e 1
}
Regras:
- engine_displacement_cc: cilindrada em cc (carro 1.6L → 1600). Range válido 50..9999.
- tank_capacity_l: capacidade do tanque em litros. Decimal. Range 0.5..500.
- horsepower: potência em cv. Range 1..2000.
- confidence: sua certeza global no chute (0 = chute total, 1 = informação oficial).
Se não souber um campo, retorne null.
Nunca invente — prefira null com baixa confidence a chutar.`;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

function toEngineDisplacementOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  if (!isFinite(value)) return null;
  const int = Math.round(value);
  if (int < 50 || int > 9999) return null;
  return int;
}

function toTankCapacityStringOrNull(value: unknown): string | null {
  if (typeof value !== 'number') return null;
  if (!isFinite(value) || value <= 0 || value > 500) return null;
  // Serialize as decimal string to preserve precision (Dart Decimal expects string).
  return String(value);
}

function toHorsepowerOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  if (!isFinite(value)) return null;
  const int = Math.round(value);
  if (int < 1 || int > 2000) return null;
  return int;
}

function toConfidence(value: unknown): number {
  if (typeof value !== 'number') return 0.0;
  if (!isFinite(value)) return 0.0;
  return Math.min(1.0, Math.max(0.0, value));
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

  const prompt = buildPrompt(vehicleType, make, model, year);

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
        max_tokens: 256,
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

  let parsed: Record<string, unknown> = {};
  try {
    const maybeObj = JSON.parse(stripped);
    if (maybeObj && typeof maybeObj === 'object' && !Array.isArray(maybeObj)) {
      parsed = maybeObj as Record<string, unknown>;
    }
  } catch {
    // Parse failure → return empty without incrementing quota.
    console.warn('Claude response was not valid JSON; returning empty specs.');
    return json(EMPTY_RESPONSE);
  }

  // --- 6. Validate and normalize fields ---
  const engineDisplacementCc = toEngineDisplacementOrNull(parsed['engine_displacement_cc']);
  const tankCapacityL = toTankCapacityStringOrNull(parsed['tank_capacity_l']);
  const horsepower = toHorsepowerOrNull(parsed['horsepower']);
  const confidence = toConfidence(parsed['confidence']);

  // --- 7. Increment quota only if result is useful ---
  // Condition: at least 1 of the 3 fields is non-null AND confidence >= 0.3
  const hasUsefulData = (engineDisplacementCc !== null || tankCapacityL !== null || horsepower !== null)
    && confidence >= 0.3;

  if (hasUsefulData) {
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

  // --- 8. Return structured specs ---
  return json({
    engine_displacement_cc: engineDisplacementCc,
    tank_capacity_l: tankCapacityL,
    horsepower,
    confidence,
  });
});
