// Shared quota utilities for all edge functions.
// Fixes month-rollover bug: when a new month starts, a partial upsert (sending
// only one counter) would leave the other counters at their previous-month
// values, causing phantom quota exhaustion on the first request of each month.
//
// Solution: always read + write ALL three counters in every upsert, zeroing the
// ones that belong to the old month.

export interface QuotaSnapshot {
  month?: string;
  scan_count?: number;
  analysis_count?: number;
  chat_count?: number;
  is_premium?: boolean;
}

/// Reads the user's quota row and returns effective counts (zeroed if the
/// stored month differs from the current calendar month).
export async function readQuota(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
): Promise<{
  row: QuotaSnapshot | null;
  effective: { scan: number; analysis: number; chat: number };
  isPremium: boolean;
  currentMonth: string;
}> {
  const currentMonth = new Date().toISOString().slice(0, 7); // "YYYY-MM"

  const { data } = await supabase
    .from('usage_quota')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  const sameMonth = data?.month === currentMonth;

  return {
    row: data ?? null,
    effective: {
      scan: sameMonth ? (data?.scan_count ?? 0) : 0,
      analysis: sameMonth ? (data?.analysis_count ?? 0) : 0,
      chat: sameMonth ? (data?.chat_count ?? 0) : 0,
    },
    isPremium: data?.is_premium ?? false,
    currentMonth,
  };
}

/// Increments exactly one counter by 1 and writes all three counters to the
/// row, zeroing any that belong to the previous month.
export async function incrementQuota(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  params: {
    userId: string;
    currentMonth: string;
    effective: { scan: number; analysis: number; chat: number };
    isPremium: boolean;
    field: 'scan_count' | 'analysis_count' | 'chat_count';
  },
): Promise<void> {
  const { userId, currentMonth, effective, isPremium, field } = params;
  const payload = {
    user_id: userId,
    month: currentMonth,
    scan_count: effective.scan + (field === 'scan_count' ? 1 : 0),
    analysis_count: effective.analysis + (field === 'analysis_count' ? 1 : 0),
    chat_count: effective.chat + (field === 'chat_count' ? 1 : 0),
    is_premium: isPremium,
  };
  await supabase.from('usage_quota').upsert(payload);
}
