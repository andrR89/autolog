-- Sprint 7.3 — LGPD: auditoria de exclusão de conta
-- Tabela de audit log para registrar solicitações de exclusão.
-- Nota: user_id NÃO tem FK para auth.users porque o usuário é deletado logo
-- após e a referência quebraria. Mantemos apenas o valor para auditoria.

create table if not exists public.account_deletion_audit (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null,   -- não é FK: auth.users é deletado depois
  requested_at timestamptz not null default now(),
  ip           text,
  user_agent   text
);

-- RLS habilitado: nenhuma policy de SELECT/INSERT para usuários normais.
-- Todas as operações passam pelo service_role da Edge Function.
alter table public.account_deletion_audit enable row level security;

-- Sem policies de acesso para roles autenticados — somente service_role pode
-- inserir/ler via bypass de RLS.
