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
// UFs brasileiras válidas
// ---------------------------------------------------------------------------

const BR_UFS = new Set([
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
  'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
]);

// ---------------------------------------------------------------------------
// Prompt PT-BR
// ---------------------------------------------------------------------------

function buildPrompt(uf: string, digit: number, year: number): string {
  return `Você é especialista em calendário fiscal automotivo brasileiro.
Para a UF ${uf} no ano ${year}, qual o mês de vencimento típico do IPVA
e do licenciamento para um veículo com placa terminada em ${digit}?

Responda APENAS com JSON, sem markdown:
{
  "ipva": {"month": int 1-12, "day": int|null, "source": string|null},
  "licensing": {"month": int 1-12, "day": int|null, "source": string|null}
}

Considere o calendário da SEFAZ/Detran do estado. Se a UF tem cota única
(mesmo mês para todas as placas), use esse mês. Caso contrário, use a
distribuição por final de placa do calendário oficial.

source: cite o órgão ("SEFAZ-SP", "Detran-RJ", etc) se souber. null se não.`;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

function toMonthOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  const int = Math.round(value);
  if (int < 1 || int > 12) return null;
  return int;
}

function toDayOrNull(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'number') return null;
  const int = Math.round(value);
  if (int < 1 || int > 31) return null;
  return int;
}

function toSourceOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const s = value.trim();
  return s.length > 0 ? s : null;
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

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'unauthorized' }, 401);
  }
  const userId = user.id;

  // --- 2. Parse and validate request body ---
  let uf: string;
  let plateLastDigit: number;
  let year: number;

  try {
    const body = await req.json();

    // uf: 2 letras BR
    if (
      typeof body.uf !== 'string' ||
      body.uf.trim().length !== 2 ||
      !BR_UFS.has(body.uf.trim().toUpperCase())
    ) {
      return json({
        error: 'invalid_uf',
        detail: 'uf must be a valid 2-letter Brazilian state code',
      }, 400);
    }

    // plate_last_digit: 0-9
    if (
      typeof body.plate_last_digit !== 'number' ||
      !isFinite(body.plate_last_digit) ||
      Math.round(body.plate_last_digit) < 0 ||
      Math.round(body.plate_last_digit) > 9
    ) {
      return json({
        error: 'invalid_plate_last_digit',
        detail: 'plate_last_digit must be an integer 0-9',
      }, 400);
    }

    // year: > 2000
    if (
      typeof body.year !== 'number' ||
      !isFinite(body.year) ||
      Math.round(body.year) <= 2000
    ) {
      return json({
        error: 'invalid_year',
        detail: 'year must be an integer > 2000',
      }, 400);
    }

    uf = body.uf.trim().toUpperCase();
    plateLastDigit = Math.round(body.plate_last_digit);
    year = Math.round(body.year);
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 3. Quota check — chat_count (10/mês free) ---
  const { effective, isPremium, currentMonth } = await readQuota(supabase, userId);

  if (!isPremium && effective.chat >= 10) {
    return json({ error: 'quota_exhausted' }, 429);
  }

  // --- 4. Call Claude Haiku 4.5 ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

  const prompt = buildPrompt(uf, plateLastDigit, year);

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
  let stripped = claudeText.trim();
  stripped = stripped.replace(/^```(json)?/m, '').replace(/```$/m, '').trim();

  let parsed: Record<string, unknown> = {};
  try {
    const maybeObj = JSON.parse(stripped);
    if (maybeObj && typeof maybeObj === 'object' && !Array.isArray(maybeObj)) {
      parsed = maybeObj as Record<string, unknown>;
    }
  } catch {
    console.warn('Claude response was not valid JSON; returning 502.');
    return json({ error: 'ai_parse_error' }, 502);
  }

  // --- 6. Validate and normalize fields ---
  const ipvaRaw = parsed['ipva'];
  const licRaw = parsed['licensing'];

  if (
    !ipvaRaw || typeof ipvaRaw !== 'object' || Array.isArray(ipvaRaw) ||
    !licRaw || typeof licRaw !== 'object' || Array.isArray(licRaw)
  ) {
    return json({ error: 'ai_invalid_structure' }, 502);
  }

  const ipvaObj = ipvaRaw as Record<string, unknown>;
  const licObj = licRaw as Record<string, unknown>;

  const ipvaMonth = toMonthOrNull(ipvaObj['month']);
  const licMonth = toMonthOrNull(licObj['month']);

  if (ipvaMonth === null || licMonth === null) {
    return json({ error: 'ai_invalid_months' }, 502);
  }

  const result = {
    ipva: {
      month: ipvaMonth,
      day: toDayOrNull(ipvaObj['day']),
      source: toSourceOrNull(ipvaObj['source']),
    },
    licensing: {
      month: licMonth,
      day: toDayOrNull(licObj['day']),
      source: toSourceOrNull(licObj['source']),
    },
  };

  // --- 7. Increment quota on success ---
  try {
    await incrementQuota(supabase, {
      userId, currentMonth, effective, isPremium, field: 'chat_count',
    });
  } catch (e) {
    // Non-fatal: log and continue.
    console.error('Failed to increment quota:', e);
  }

  // --- 8. Return fiscal calendar data ---
  return json(result);
});
