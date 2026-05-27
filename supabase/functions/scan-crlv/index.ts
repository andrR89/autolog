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
// Prompt (Sprint 6.K — CRLV extraction)
// ---------------------------------------------------------------------------

const PROMPT = `Você extrai dados do CRLV-e (Certificado de Registro e Licenciamento do Veículo)
brasileiro. Responda APENAS com JSON válido, sem markdown.
Schema: {
  "plate": string|null, "renavam": string|null, "chassi": string|null,
  "color": string|null, "fuel_type": string|null,
  "make": string|null, "model": string|null, "year": number|null
}
Normalize:
- plate: maiúsculas, sem espaço, sem hífen. Aceita formato ABC1D23 (Mercosul) ou ABC1234.
- renavam: só dígitos.
- chassi: 17 caracteres alfanuméricos maiúsculos, sem espaço.
- fuel_type: um de "gasolina","etanol","diesel","flex","gnv". Se "ÁLCOOL" → "etanol". Mapeie o que conseguir; null se incerto.
- year: ano de fabricação (não modelo). Inteiro.
Se um campo não for legível, use null. Nunca invente.`;

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

const VALID_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/heic',
  'application/pdf',
];

const VALID_FUEL_TYPES = ['gasolina', 'etanol', 'diesel', 'flex', 'gnv'];

const PLATE_RE = /^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$/;
const PLATE_OLD_RE = /^[A-Z]{3}[0-9]{4}$/;
const RENAVAM_RE = /^\d{9,11}$/;
const CHASSI_RE = /^[A-Z0-9]{17}$/;

function toPlateOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().toUpperCase().replace(/[-\s]/g, '');
  if (PLATE_RE.test(normalized) || PLATE_OLD_RE.test(normalized)) {
    return normalized;
  }
  return null;
}

function toRenavamOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().replace(/\D/g, '');
  return RENAVAM_RE.test(normalized) ? normalized : null;
}

function toChassiOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().toUpperCase().replace(/[\s-]/g, '');
  return CHASSI_RE.test(normalized) ? normalized : null;
}

function toFuelTypeOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().toLowerCase();
  return VALID_FUEL_TYPES.includes(normalized) ? normalized : null;
}

function toYearOrNull(value: unknown): number | null {
  if (typeof value !== 'number') return null;
  const year = Math.floor(value);
  const currentYear = new Date().getFullYear();
  if (year < 1900 || year > currentYear + 1) return null;
  return year;
}

function toColorOrNull(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed.slice(0, 50);
}

function toStringOrNull(value: unknown, maxLen = 100): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed.slice(0, maxLen);
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
  let document_base64: string;
  let mime_type: string;
  try {
    const body = await req.json();
    if (!body.document_base64 || typeof body.document_base64 !== 'string') {
      return json({ error: 'missing_document_base64' }, 400);
    }
    if (!body.mime_type || typeof body.mime_type !== 'string') {
      return json({ error: 'missing_mime_type' }, 400);
    }
    document_base64 = body.document_base64;
    mime_type = body.mime_type;
  } catch {
    return json({ error: 'invalid_json_body' }, 400);
  }

  // --- 2b. Validate mime_type ---
  if (!VALID_MIME_TYPES.includes(mime_type)) {
    return json({ error: 'invalid_mime_type', valid: VALID_MIME_TYPES }, 400);
  }

  // --- 3. Quota check — shared scan_count (mesma tabela usage_quota) ---
  const { effective, isPremium, currentMonth } = await readQuota(supabase, userId);

  if (!isPremium && effective.scan >= 5) {
    return json({ error: 'quota_exhausted' }, 429);
  }

  // --- 4. Call Claude Haiku 4.5 ---
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return json({ error: 'server_configuration_error' }, 500);
  }

  // Build content block conditioned on mime_type.
  let contentBlock: unknown;
  if (mime_type.startsWith('image/')) {
    contentBlock = {
      type: 'image',
      source: {
        type: 'base64',
        media_type: mime_type,
        data: document_base64,
      },
    };
  } else {
    // application/pdf
    contentBlock = {
      type: 'document',
      source: {
        type: 'base64',
        media_type: 'application/pdf',
        data: document_base64,
      },
    };
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
              contentBlock,
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
    console.warn('Claude response was not valid JSON; returning empty CRLV.');
    return json({
      plate: null,
      renavam: null,
      chassi: null,
      color: null,
      fuel_type: null,
      make: null,
      model: null,
      year: null,
    });
  }

  // --- 6. Validate and normalize fields ---
  const plate = toPlateOrNull(parsed['plate']);
  const renavam = toRenavamOrNull(parsed['renavam']);
  const chassi = toChassiOrNull(parsed['chassi']);
  const color = toColorOrNull(parsed['color']);
  const fuel_type = toFuelTypeOrNull(parsed['fuel_type']);
  const make = toStringOrNull(parsed['make']);
  const model = toStringOrNull(parsed['model']);
  const year = toYearOrNull(parsed['year']);

  // --- 7. Increment quota only if response was "útil" ---
  // Útil = plate != null || chassi != null || (make != null && model != null)
  const wasUseful = plate !== null || chassi !== null || (make !== null && model !== null);
  if (wasUseful) {
    try {
      await incrementQuota(supabase, {
        userId, currentMonth, effective, isPremium, field: 'scan_count',
      });
    } catch (e) {
      console.error('Failed to increment quota:', e);
    }
  }

  // --- 8. Return structured CRLV (shape ScannedCrlv.fromJson expects) ---
  return json({
    plate,
    renavam,
    chassi,
    color,
    fuel_type,
    make,
    model,
    year,
  });
});
