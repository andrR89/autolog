import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { incrementQuota, readQuota } from '../_shared/quota.ts';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Resposta TwiML. Twilio requer Content-Type application/xml.
function twiml(message: string, status = 200): Response {
  const body = `<?xml version="1.0" encoding="UTF-8"?><Response><Message>${escapeXml(message)}</Message></Response>`;
  return new Response(body, {
    status,
    headers: { 'Content-Type': 'application/xml' },
  });
}

function escapeXml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/// Extrai o número limpo do campo From do Twilio.
/// "whatsapp:+5511999999999" → "+5511999999999"
function extractPhone(from: string): string {
  return from.replace(/^whatsapp:/i, '').trim();
}

/// Parse defensivo da resposta do Haiku.
function parseHaikuJson(text: string): Record<string, unknown> {
  let stripped = text.trim();
  // Remove markdown code fences se presentes.
  stripped = stripped.replace(/^```(json)?/m, '').replace(/```$/m, '').trim();
  try {
    const parsed = JSON.parse(stripped);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch {
    // Falha defensiva — retorna objeto vazio.
  }
  return {};
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Só aceita POST (Twilio envia POST).
  if (req.method !== 'POST') {
    return twiml('Método não permitido', 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');

  // Service-role client — bypassa RLS para todas as operações do webhook.
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // --- 1. Parse form-urlencoded body (padrão Twilio) ---
  let from = '';
  let body = '';
  try {
    const text = await req.text();
    const params = new URLSearchParams(text);
    from = params.get('From') ?? '';
    body = params.get('Body') ?? '';
  } catch {
    return twiml('Erro ao ler mensagem.');
  }

  if (!from) {
    return twiml('Requisição inválida: campo From ausente.');
  }

  const phone = extractPhone(from);
  const bodyTrimmed = body.trim();

  // --- 2. Fluxo de pareamento: mensagem começa com "AUTOLOG " ---
  if (bodyTrimmed.toUpperCase().startsWith('AUTOLOG ')) {
    const parts = bodyTrimmed.split(/\s+/);
    const code = parts[1]?.trim() ?? '';

    if (!code || !/^\d{6}$/.test(code)) {
      return twiml('Código inválido. Envie: AUTOLOG 123456');
    }

    // Busca o código pendente.
    const { data: pendingRow, error: codeError } = await supabase
      .from('whatsapp_pending_codes')
      .select('user_id')
      .eq('code', code)
      .maybeSingle();

    if (codeError) {
      console.error('Error fetching pending code:', codeError);
      return twiml('Erro interno. Tente novamente.');
    }

    if (!pendingRow) {
      return twiml('Código inválido ou expirado. Abra o app e gere um novo código.');
    }

    const userId = pendingRow.user_id as string;

    // Cria o link WhatsApp (upsert — caso o usuário repareie).
    const { error: linkError } = await supabase
      .from('whatsapp_links')
      .upsert(
        { user_id: userId, phone_number: phone },
        { onConflict: 'user_id' },
      );

    if (linkError) {
      console.error('Error creating whatsapp_link:', linkError);
      return twiml('Erro ao parear. Tente novamente.');
    }

    // Deleta o código usado.
    await supabase
      .from('whatsapp_pending_codes')
      .delete()
      .eq('code', code);

    return twiml('Pareado com sucesso! Agora envie mensagens de abastecimento, ex: "abasteci 40L de gasolina por R$5,79 no Civic".');
  }

  // --- 3. Fluxo de registro de abastecimento ---

  // Busca link pelo número de telefone.
  const { data: linkRow, error: linkLookupError } = await supabase
    .from('whatsapp_links')
    .select('user_id')
    .eq('phone_number', phone)
    .maybeSingle();

  if (linkLookupError) {
    console.error('Error fetching whatsapp_link:', linkLookupError);
    return twiml('Erro interno. Tente novamente.');
  }

  if (!linkRow) {
    return twiml(
      'Número não pareado. Abra Configurações → WhatsApp no app AutoLog para gerar seu código de pareamento.',
    );
  }

  const userId = linkRow.user_id as string;

  // Busca veículos do usuário.
  const { data: vehicles, error: vehiclesError } = await supabase
    .from('vehicles')
    .select('id, nickname, make, model, fuel_type')
    .eq('user_id', userId)
    .is('deleted_at', null);

  if (vehiclesError || !vehicles) {
    console.error('Error fetching vehicles:', vehiclesError);
    return twiml('Erro ao buscar seus veículos. Tente novamente.');
  }

  if (vehicles.length === 0) {
    return twiml('Você não possui veículos cadastrados. Abra o app para cadastrar.');
  }

  const vehicleList = vehicles
    .map((v: Record<string, unknown>) => [v.nickname, v.make, v.model].filter(Boolean).join(' '))
    .join(', ');

  // Verifica chave Anthropic.
  if (!anthropicApiKey) {
    console.error('ANTHROPIC_API_KEY not configured');
    return twiml('Serviço de interpretação indisponível no momento.');
  }

  // --- 4. Chama Haiku para extrair dados do abastecimento ---
  const prompt = `Extraia dados de um abastecimento informal escrito pelo usuário.
Texto: "${bodyTrimmed}"
Veículos disponíveis: ${vehicleList}
Responda APENAS JSON sem markdown:
{"vehicle_hint": string|null, "liters": number|null, "price_per_liter": number|null, "total_cost": number|null, "fuel_type": "gasolina"|"etanol"|"diesel"|"flex"|"gnv"|null, "date": "YYYY-MM-DD"|null}`;

  let claudeText = '';
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
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    if (!claudeResp.ok) {
      const errBody = await claudeResp.text();
      console.error(`Anthropic API error ${claudeResp.status}: ${errBody}`);
      return twiml('Erro ao interpretar a mensagem. Tente novamente.');
    }

    const claudeData = await claudeResp.json();
    claudeText = claudeData?.content?.[0]?.text ?? '';
  } catch (e) {
    console.error('Failed to call Anthropic API:', e);
    return twiml('Erro ao interpretar a mensagem. Tente novamente.');
  }

  // --- 5. Parse defensivo ---
  const parsed = parseHaikuJson(claudeText);

  const vehicleHint = (parsed['vehicle_hint'] as string | null) ?? null;
  const liters = typeof parsed['liters'] === 'number' ? parsed['liters'] : null;
  const pricePerLiter =
    typeof parsed['price_per_liter'] === 'number' ? parsed['price_per_liter'] : null;
  const totalCostParsed =
    typeof parsed['total_cost'] === 'number' ? parsed['total_cost'] : null;
  const fuelTypeParsed = (parsed['fuel_type'] as string | null) ?? null;
  const dateParsed = (parsed['date'] as string | null) ?? null;

  // --- 6. Match de veículo (case-insensitive em nickname/make/model) ---
  type VehicleRow = { id: string; nickname: string; make: string | null; model: string | null; fuel_type: string };
  let matchedVehicle: VehicleRow | null = null;

  if (vehicleHint) {
    const hint = vehicleHint.toLowerCase();
    matchedVehicle = vehicles.find((v: Record<string, unknown>) => {
      const nickname = ((v.nickname as string) ?? '').toLowerCase();
      const make = ((v.make as string | null) ?? '').toLowerCase();
      const model = ((v.model as string | null) ?? '').toLowerCase();
      return nickname.includes(hint) || hint.includes(nickname) ||
             make.includes(hint) || hint.includes(make) ||
             model.includes(hint) || hint.includes(model);
    }) as VehicleRow | undefined ?? null;
  }

  // Se só há um veículo, usa-o automaticamente.
  if (!matchedVehicle && vehicles.length === 1) {
    matchedVehicle = vehicles[0] as VehicleRow;
  }

  if (!matchedVehicle) {
    return twiml(
      `Não identifiquei o veículo. Disponíveis: ${vehicleList}. Mencione o nome do veículo na mensagem.`,
    );
  }

  // Valida campos mínimos: litros e preço (ou total).
  if (liters === null) {
    return twiml(
      `Não entendi a quantidade de litros. Tente: "abasteci 40 litros de gasolina por R$5,79 no ${matchedVehicle.nickname}".`,
    );
  }

  // Calcula total e preço por litro se um estiver faltando.
  let finalPricePerLiter = pricePerLiter;
  let finalTotalCost = totalCostParsed;

  if (finalPricePerLiter === null && finalTotalCost !== null && liters > 0) {
    finalPricePerLiter = finalTotalCost / liters;
  } else if (finalTotalCost === null && finalPricePerLiter !== null) {
    finalTotalCost = finalPricePerLiter * liters;
  }

  if (finalPricePerLiter === null || finalTotalCost === null) {
    return twiml(
      `Não entendi o preço. Tente: "abasteci ${liters}L por R$5,79" ou "gastei R$231,60 no ${matchedVehicle.nickname}".`,
    );
  }

  // Tipo de combustível: usa o do veículo como fallback.
  const validFuelTypes = ['gasolina', 'etanol', 'diesel', 'flex', 'gnv'];
  const fuelType = (fuelTypeParsed && validFuelTypes.includes(fuelTypeParsed))
    ? fuelTypeParsed
    : matchedVehicle.fuel_type;

  // Data: hoje como fallback.
  const today = new Date().toISOString().slice(0, 10);
  const dateIso = dateParsed ?? today;
  const dateTimestamp = `${dateIso}T12:00:00.000Z`;

  // UUID gerado no servidor para o novo registro.
  const newId = crypto.randomUUID();

  // --- 7. Cria fuel_entry com service role (bypassa RLS) ---
  const { error: insertError } = await supabase
    .from('fuel_entries')
    .insert({
      id: newId,
      vehicle_id: matchedVehicle.id,
      date: dateTimestamp,
      odometer: 0, // Odômetro não informado via WhatsApp — valor zero como placeholder.
      liters: liters.toString(),
      price_per_liter: finalPricePerLiter.toFixed(3),
      total_cost: finalTotalCost.toFixed(2),
      full_tank: false,
      fuel_type: fuelType,
      source: 'manual',
      sync_status: 'synced',
    });

  if (insertError) {
    console.error('Error inserting fuel_entry:', insertError);
    return twiml('Erro ao registrar o abastecimento. Tente novamente.');
  }

  // --- 8. Incrementa cota de scan (compartilha cota de scan_count) ---
  try {
    const { effective, isPremium, currentMonth } = await readQuota(supabase, userId);
    await incrementQuota(supabase, {
      userId,
      currentMonth,
      effective,
      isPremium,
      field: 'scan_count',
    });
  } catch (e) {
    // Não-fatal: o registro já foi criado.
    console.error('Failed to increment quota:', e);
  }

  // --- 9. Resposta de sucesso ---
  const totalFormatted = finalTotalCost.toFixed(2).replace('.', ',');
  return twiml(
    `Registrado: ${liters}L por R$${totalFormatted} no ${matchedVehicle.nickname}!`,
  );
});
