# Pendências de Teste — AutoLog (18/06/2026, pós-reteste premium)

> Detalhe completo em `docs/ACHADOS-TESTE-2026-06-18.md` (seções 0.00 e 0.0).

## 1. ✅ RESOLVIDO — Sync (RLS recursiva no Supabase)
- Era: `vehicles: PostgrestException(... infinite recursion detected in policy for relation "vehicles", code: 42P17 ...)` — RLS recursiva.
- **Corrigido** pela migration `0014_fix_rls_recursion.sql`. Retestado em 19/06: indicador vai pra **synced**, sem erro ao forçar sync. Bloco 10 destravado.
- Resta (não-bloqueante): validar o ciclo completo offline↔online em **device físico** com rede instável; e (opcional) mensagem PT-BR amigável no lugar do `Bad state` cru.

## 2. Não exercível neste build (camada ainda não existe)
- **Cota / gating premium (Bloco 4):** sem UI de assinatura/cota/paywall/badge. O scan premium funciona, mas a diferenciação free×premium não dá pra validar até existir a camada de billing/cota na UI (sprint de RevenueCat).

## 3. Não testável no ambiente (limitação de simulador/conta)
- Login social Google/Apple (OAuth não completa no simulador).
- Disparo de notificação local (não dá pra avançar o relógio com segurança).
- Debounce de busca (300 ms) e paginação >25 registros (dataset só tem ~4 abastecimentos).

## 4. Cosmético remanescente (menor, não bloqueia)
- Eixo X dos LineCharts de Relatórios repete "mai" várias vezes.
- Banner do scan é verde (roteiro pedia amarelo).

---

**Resumo:** o grande pendente agora é **um bug de verdade no sync** (falha pra todas as entidades, com backend ligado). O resto é camada ainda não construída (cota/billing) ou limitação de ambiente.
