// Entitlements provider — fonte única de verdade pra "user é premium?".
//
// MVP (esta sprint): retorna `false` por padrão (free pra todos), mas
// expõe `entitlementsOverrideProvider` que tester/dev pode usar pra
// simular premium localmente sem alterar o DB.
//
// V1 (quando RevenueCat for adicionado):
//   - Subscribe ao `Purchases.addCustomerInfoUpdateListener`
//   - Persiste `is_premium` em `usage_quota` (single source of truth)
//   - Sync sobe is_premium pro Supabase via webhook RevenueCat
//   - Edge Functions já leem is_premium do usage_quota
//
// REGRA DE OURO: `is_premium` SEMPRE vem do backend pra gating de cota
// (Regra #5 do CLAUDE.md). Este provider é só pra UI — gating real
// continua no backend, não no client.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override pra dev/testes: setar pra `true` simula user premium.
/// Em produção mantém null (entitlements decidido pelo backend).
final entitlementsOverrideProvider = StateProvider<bool?>((_) => null);

/// True se o user atual tem entitlement premium.
///
/// Por enquanto, sempre `false` salvo override explícito. Será wirado ao
/// RevenueCat quando a integração for completada.
final isPremiumProvider = Provider<bool>((ref) {
  final override = ref.watch(entitlementsOverrideProvider);
  if (override != null) return override;
  // TODO(billing): substituir por leitura de usage_quota.is_premium
  // quando o webhook RevenueCat estiver setado em prod.
  return false;
});
