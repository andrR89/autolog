// Helper CORS compartilhado para Edge Functions.
//
// Por que existe: o Supabase REST (`/rest/v1/...`) tem CORS habilitado por
// padrão pelo PostgREST, mas Edge Functions Deno NÃO. Sem preflight OPTIONS
// + Access-Control-Allow-Origin, qualquer navegador (web/PWA) aborta a
// request final ANTES dela chegar — bug reportado no Web Sprint 8 (I1).
//
// Uso:
//   import { corsHeaders, handlePreflight } from '../_shared/cors.ts';
//
//   serve(async (req) => {
//     const preflight = handlePreflight(req);
//     if (preflight) return preflight;
//
//     // ... lógica normal ...
//     return new Response(JSON.stringify(body), {
//       headers: { ...corsHeaders, 'Content-Type': 'application/json' },
//     });
//   });
//
// Allow-Origin '*' é seguro aqui porque:
//   - O bearer JWT já garante quem pode chamar (Supabase Auth);
//   - Nenhuma function depende de cookie/credentials cross-site;
//   - Não temos endpoints públicos sem auth.

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Max-Age': '86400',
};

/// Se a requisição é um preflight OPTIONS, devolve a resposta de CORS pronta;
/// senão, retorna null pra o handler seguir com a lógica normal.
export function handlePreflight(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
}
