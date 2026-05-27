# Patch — Vazamento de contadores de cota entre meses

> Débito técnico anotado desde Sprint 6.G. Necessário antes do go-live.

## Bug

Cada edge function que incrementa cota usa pattern:
```ts
await supabase.from('usage_quota').upsert({
  user_id, month: currentMonth,
  [meu_campo]: effectiveCount + 1,
  is_premium,
});
```

Quando o mês vira:
- Linha antiga: `month='2026-05', scan_count=5, analysis_count=3, chat_count=2`.
- Edge fn `chat-history` é a primeira chamada em junho.
- `effectiveCount = quotaRow.month === '2026-06' ? row.chat_count : 0` → 0 (correto).
- Upsert envia `{month: '2026-06', chat_count: 1, is_premium}`. **NÃO envia
  scan_count e analysis_count**. Como Supabase `.upsert()` faz UPDATE só dos
  campos enviados, `scan_count` e `analysis_count` **ficam em 5 e 3** (lixo
  do mês passado).
- Próxima vez que o user fizer scan em junho: edge fn `scan-receipt` lê
  `quotaRow.month === '2026-06'` → true, `effectiveCount = scan_count = 5`.
  **User já bate cota no primeiro scan do mês.**

## Fix

Shared lib em `supabase/functions/_shared/quota.ts`:
```ts
export interface QuotaSnapshot {
  month?: string;
  scan_count?: number;
  analysis_count?: number;
  chat_count?: number;
  is_premium?: boolean;
}

/// Lê quota do usuário, retorna efetivo (zerado se mês mudou).
export async function readQuota(supabase, userId): Promise<{
  row: QuotaSnapshot | null;
  effective: {scan: number; analysis: number; chat: number};
  isPremium: boolean;
  currentMonth: string;
}> {
  const currentMonth = new Date().toISOString().slice(0, 7);
  const { data } = await supabase.from('usage_quota')
    .select('*').eq('user_id', userId).maybeSingle();
  const sameMonth = data?.month === currentMonth;
  return {
    row: data,
    effective: {
      scan: sameMonth ? (data?.scan_count ?? 0) : 0,
      analysis: sameMonth ? (data?.analysis_count ?? 0) : 0,
      chat: sameMonth ? (data?.chat_count ?? 0) : 0,
    },
    isPremium: data?.is_premium ?? false,
    currentMonth,
  };
}

/// Incrementa 1 campo + ZERA os outros se mês virou.
/// Sempre envia os 3 campos pro upsert, eliminando o vazamento.
export async function incrementQuota(supabase, params: {
  userId: string;
  currentMonth: string;
  effective: {scan: number; analysis: number; chat: number};
  isPremium: boolean;
  field: 'scan_count' | 'analysis_count' | 'chat_count';
}): Promise<void> {
  const payload = {
    user_id: params.userId,
    month: params.currentMonth,
    scan_count: params.effective.scan + (params.field === 'scan_count' ? 1 : 0),
    analysis_count: params.effective.analysis + (params.field === 'analysis_count' ? 1 : 0),
    chat_count: params.effective.chat + (params.field === 'chat_count' ? 1 : 0),
    is_premium: params.isPremium,
  };
  await supabase.from('usage_quota').upsert(payload);
}
```

## Aplicação

Refatorar 8 edge functions pra usar `readQuota` + `incrementQuota`:
- `scan-receipt` → field `scan_count`
- `scan-expense` → field `scan_count`
- `scan-crlv` → field `scan_count`
- `infer-vehicle-specs` → field `scan_count`
- `suggest-maintenance` → field `scan_count`
- `analyze-history` → field `analysis_count`
- `chat-history` → field `chat_count`
- `fiscal-calendar-lookup` → field `chat_count`

Cada edge fn:
1. Substitui leitura manual de `usage_quota` por `readQuota(supabase, userId)`.
2. Usa `effective.scan` / `effective.analysis` / `effective.chat` no gating.
3. Substitui upsert manual por `incrementQuota(...)`.

## Sem testes Dart

Edge fns são Deno, sem suite Dart. Validação: dispatch dispatcher manual no Diretor (smoke test) ou unit test em Deno (fora de escopo).

## Critérios
- Flutter suite continua verde (844)
- analyze 0, iOS build OK
- 8 edge functions refatoradas + 1 shared lib criada
- Deploy manual: `supabase functions deploy` (todas)
