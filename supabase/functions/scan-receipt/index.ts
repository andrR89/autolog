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
// Prompt (ARCHITECTURE §5)
// ---------------------------------------------------------------------------

const PROMPT = `Você extrai dados de cupons fiscais de postos de combustível brasileiros.
Responda APENAS com JSON válido, sem markdown, sem explicação.
Schema: {"liters": number|null, "price_per_liter": number|null, "total": number|null, "date": "YYYY-MM-DD"|null, "fuel_type": string|null}
Se um campo não for legível, use null. Nunca invente valores.
fuel_type deve ser um de: "gasolina", "etanol", "diesel", "flex", "gnv".`;

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

const VALID_FUEL_TYPES = ['gasolina', 'etanol', 'diesel', 'flex', 'gnv'];
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function toStringOrNull(value: unknown): string | null {
  if (typeof value !== 'number') return null;
  return String(value);
}

function toDateIsoOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  if (!DATE_RE.test(value)) return null;
  // ScannedReceipt.date is DateTime? parsed from ISO-8601 string.
  return `${value}T00:00:00.000Z`;
}

function toFuelTypeOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  return VALID_FUEL_TYPES.includes(value) ? value : null;
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
  let image_base64: string;
  try {
    const body = await req.json();
    if (!body.image_base64 || typeof body.image_base64 !== 'string') {
      return json({ error: 'missing_image_base64' }, 400);
    }
    image_base64 = body.image_base64;
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 3. Quota check (spec §2) ---
  const currentMonth = new Date().toISOString().slice(0, 7); // "YYYY-MM"

  const { data: quotaRow } = await supabase
    .from('usage_quota')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  const isPremium: boolean = quotaRow?.is_premium ?? false;
  const effectiveCount: number =
    quotaRow?.month === currentMonth ? (quotaRow.scan_count as number) : 0;

  if (!isPremium && effectiveCount >= 5) {
    return json({ error: 'quota_exhausted' }, 429);
  }

  // --- 4. Call Claude Haiku 4.5 (spec §3) ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

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
        max_tokens: 512,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: 'image/jpeg',
                  data: image_base64,
                },
              },
              {
                type: 'text',
                text: PROMPT,
              },
            ],
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

  // --- 5. Defensive parse (spec §4) ---
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
    // Parse failure → return all-null receipt without incrementing quota.
    console.warn('Claude response was not valid JSON; returning empty receipt.');
    return json({
      liters: null,
      price_per_liter: null,
      total_cost: null,
      date: null,
      fuel_type: null,
    });
  }

  // --- 6. Validate and normalize fields ---
  const litersStr = toStringOrNull(parsed['liters']);
  const priceStr = toStringOrNull(parsed['price_per_liter']);
  const totalStr = toStringOrNull(parsed['total']);
  const dateIso = toDateIsoOrNull(parsed['date']);
  const fuelType = toFuelTypeOrNull(parsed['fuel_type']);

  // --- 7. Increment quota only if useful data was returned (spec §4 final note) ---
  // "incrementa só se pelo menos liters E price_per_liter vierem não-nulos"
  if (litersStr !== null && priceStr !== null) {
    try {
      await supabase.from('usage_quota').upsert({
        user_id: userId,
        month: currentMonth,
        scan_count: effectiveCount + 1,
        is_premium: isPremium,
      });
    } catch (e) {
      // Non-fatal: log and continue — user got their data, quota increment failure
      // should not break the response. Will self-correct on next scan.
      console.error('Failed to increment quota:', e);
    }
  }

  // --- 8. Return structured receipt (spec §5 — shape Dart model expects) ---
  return json({
    liters: litersStr,
    price_per_liter: priceStr,
    total_cost: totalStr,
    date: dateIso,
    fuel_type: fuelType,
  });
});
