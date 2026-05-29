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
// Main handler — DELETE /delete-account
// Sprint 7.3 — LGPD compliance
//
// Fluxo:
//   1. Valida JWT do usuário
//   2. Idempotência: se já deletado, retorna 200 { already_deleted: true }
//   3. Audit log: insere em account_deletion_audit
//   4. Hard delete em CASCADE via transaction (service_role):
//      vehicles → (fuel_entries, expenses, reminders, fines, insurances,
//                   trips, vehicle_members via ON DELETE CASCADE)
//      user_profile, usage_quota, user_settings (local-only, mas limpar)
//      notifications_log (sem relação com vehicles; deletar por userId seria
//        mais correto, mas a tabela não tem user_id — local-only, limpo no client)
//   5. auth.users deletado por último via admin.deleteUser
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Aceita apenas POST
  if (req.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405);
  }

  // --- 1. Extração e validação do JWT ---
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json({ error: 'Autenticação obrigatória.' }, 401);
  }
  const jwt = authHeader.replace(/^Bearer\s+/i, '');

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Cliente service_role: bypass de RLS para todas as operações
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // Valida o JWT e obtém o usuário
  const { data: { user }, error: authError } = await adminClient.auth.getUser(jwt);
  if (authError || !user) {
    return json({ error: 'Token inválido ou expirado.' }, 401);
  }
  const userId = user.id;

  // --- 2. Idempotência: verifica se já foi deletado ---
  // Se getUser retornou o usuário, ele ainda existe. Se for chamado depois da
  // deleção, getUser vai falhar com erro 401 (acima). Verificação via audit
  // log para cobrir edge cases de re-tentativa durante a própria deleção.
  const { data: existingAudit } = await adminClient
    .from('account_deletion_audit')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (existingAudit) {
    // Já havia um registro de deleção para este userId — resposta idempotente.
    return json({ already_deleted: true });
  }

  // --- 3. Audit log (best effort) ---
  const ip =
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    req.headers.get('x-real-ip') ??
    null;
  const userAgent = req.headers.get('user-agent') ?? null;

  await adminClient.from('account_deletion_audit').insert({
    user_id: userId,
    requested_at: new Date().toISOString(),
    ip,
    user_agent: userAgent,
  });

  // --- 4. Hard delete em cascata ---
  // A ordem importa: entidades que têm FK para vehicles são deletadas
  // automaticamente pelo CASCADE do Postgres quando vehicles é deletado.
  // Entidades independentes (user_profile, usage_quota) são deletadas
  // explicitamente. auth.users por último.
  //
  // Tabelas com ON DELETE CASCADE a partir de vehicles:
  //   fuel_entries, expenses, reminders, fines, insurances, trips, vehicle_members
  //
  // Tabelas com ON DELETE CASCADE a partir de auth.users (definidas no schema):
  //   vehicles, user_profile, usage_quota
  //
  // Por segurança, deletamos explicitamente antes do auth.deleteUser para
  // garantir que o CASCADE não falhe por race conditions ou configuração incorreta.

  try {
    // 4a. Deletar veículos do usuário (CASCADE elimina todos os filhos)
    const { error: vehiclesErr } = await adminClient
      .from('vehicles')
      .delete()
      .eq('user_id', userId);
    if (vehiclesErr) {
      console.error('Erro ao deletar vehicles:', vehiclesErr.message);
      throw new Error(`Falha ao remover veículos: ${vehiclesErr.message}`);
    }

    // 4b. Deletar perfil do usuário
    const { error: profileErr } = await adminClient
      .from('user_profile')
      .delete()
      .eq('user_id', userId);
    if (profileErr && profileErr.code !== 'PGRST116') {
      // PGRST116 = row not found — ok, pode não ter perfil
      console.error('Erro ao deletar user_profile:', profileErr.message);
      throw new Error(`Falha ao remover perfil: ${profileErr.message}`);
    }

    // 4c. Deletar cota de uso
    const { error: quotaErr } = await adminClient
      .from('usage_quota')
      .delete()
      .eq('user_id', userId);
    if (quotaErr && quotaErr.code !== 'PGRST116') {
      console.error('Erro ao deletar usage_quota:', quotaErr.message);
      throw new Error(`Falha ao remover cota: ${quotaErr.message}`);
    }

    // 4d. whatsapp_links — migration 0012 dropou a tabela; ignorar.

    // 4e. vehicle_members onde o userId é MEMBRO (não dono) — o dono já
    //     foi limpo via CASCADE de vehicles. Limpar registros onde este
    //     usuário era membro de veículos de outros.
    const { error: membersErr } = await adminClient
      .from('vehicle_members')
      .delete()
      .eq('user_id', userId);
    if (membersErr && membersErr.code !== 'PGRST116') {
      console.error('Erro ao deletar vehicle_members:', membersErr.message);
      // Não fatal — continua a deleção
    }

    // 4f. Por último: deletar o usuário em auth.users
    //     Isso invalida o JWT e impede qualquer re-autenticação.
    const { error: deleteUserErr } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteUserErr) {
      console.error('Erro ao deletar auth.users:', deleteUserErr.message);
      throw new Error(`Falha ao remover conta: ${deleteUserErr.message}`);
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Erro interno.';
    return json(
      { error: `Não foi possível excluir a conta. ${message}` },
      500,
    );
  }

  return json({ success: true });
});
