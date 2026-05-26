-- =============================================================================
-- AutoLog — Schema inicial (Sprint 0.4)
-- Tabelas espelho do modelo Drift local para sincronização via Supabase.
--
-- INSTRUÇÕES DE APLICAÇÃO:
--   Cole este arquivo no Supabase SQL Editor e execute de cima para baixo
--   em um projeto limpo. Requere extensão "pgcrypto" (habilitada por padrão).
--
-- CONVENÇÕES:
--   • IDs: uuid gerado no client (não serial).
--   • Dinheiro/volume: numeric (nunca float/double precision).
--   • Datas com fuso: timestamptz; só data (sem hora): date.
--   • Enums: text + CHECK com os wire values do Dart (lib/domain/models/enums.dart).
--   • sync_status: 'pending' | 'synced', default 'pending'.
--   • deleted_at: soft delete (nunca hard delete no MVP).
--   • RLS habilitado em todas as tabelas.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. vehicles
--    RLS: user_id = auth.uid()
-- ---------------------------------------------------------------------------
create table if not exists vehicles (
  id               uuid        primary key,
  user_id          uuid        not null references auth.users(id) on delete cascade,
  nickname         text        not null,
  make             text,
  model            text,
  plate            text,
  fuel_type        text        not null
                               check (fuel_type in ('gasolina', 'etanol', 'diesel', 'flex', 'gnv')),
  initial_odometer integer     not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  sync_status      text        not null default 'pending'
                               check (sync_status in ('pending', 'synced'))
);

alter table vehicles enable row level security;

-- Política: usuário só acessa seus próprios veículos.
create policy "vehicles: acesso apenas ao dono"
  on vehicles
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create index if not exists idx_vehicles_user_id    on vehicles (user_id);
create index if not exists idx_vehicles_updated_at on vehicles (updated_at);

-- ---------------------------------------------------------------------------
-- 2. fuel_entries (abastecimentos)
--    RLS: vehicle_id in (select id from vehicles where user_id = auth.uid())
--    NOTA: não tem user_id — modelo de dados fechado nas sprints 0.2/0.3.
-- ---------------------------------------------------------------------------
create table if not exists fuel_entries (
  id                uuid        primary key,
  vehicle_id        uuid        not null references vehicles(id) on delete cascade,
  date              timestamptz not null,
  odometer          integer     not null,
  liters            numeric     not null,
  price_per_liter   numeric     not null,
  total_cost        numeric     not null,
  full_tank         boolean     not null default true,
  fuel_type         text        not null
                                check (fuel_type in ('gasolina', 'etanol', 'diesel', 'flex', 'gnv')),
  source            text        not null
                                check (source in ('ai_scan', 'ocr', 'manual')),
  receipt_image_url text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  sync_status       text        not null default 'pending'
                                check (sync_status in ('pending', 'synced'))
);

alter table fuel_entries enable row level security;

-- Política via subquery em vehicles (sem denormalizar user_id).
create policy "fuel_entries: acesso via veículo do dono"
  on fuel_entries
  for all
  using (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  )
  with check (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  );

create index if not exists idx_fuel_entries_vehicle_id  on fuel_entries (vehicle_id);
create index if not exists idx_fuel_entries_updated_at  on fuel_entries (updated_at);

-- ---------------------------------------------------------------------------
-- 3. expenses (despesas gerais)
--    RLS: vehicle_id in (select id from vehicles where user_id = auth.uid())
-- ---------------------------------------------------------------------------
create table if not exists expenses (
  id           uuid        primary key,
  vehicle_id   uuid        not null references vehicles(id) on delete cascade,
  date         timestamptz not null,
  category     text        not null
                           check (category in (
                             'manutencao', 'lavagem', 'estacionamento',
                             'multa', 'seguro', 'ipva', 'outro'
                           )),
  description  text        not null,
  amount       numeric     not null,
  odometer     integer,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  sync_status  text        not null default 'pending'
                           check (sync_status in ('pending', 'synced'))
);

alter table expenses enable row level security;

create policy "expenses: acesso via veículo do dono"
  on expenses
  for all
  using (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  )
  with check (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  );

create index if not exists idx_expenses_vehicle_id  on expenses (vehicle_id);
create index if not exists idx_expenses_updated_at  on expenses (updated_at);

-- ---------------------------------------------------------------------------
-- 4. reminders (lembretes)
--    RLS: vehicle_id in (select id from vehicles where user_id = auth.uid())
-- ---------------------------------------------------------------------------
create table if not exists reminders (
  id           uuid        primary key,
  vehicle_id   uuid        not null references vehicles(id) on delete cascade,
  type         text        not null
                           check (type in ('por_km', 'por_data')),
  title        text        not null,
  due_km       integer,
  due_date     date,
  is_done      boolean     not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  sync_status  text        not null default 'pending'
                           check (sync_status in ('pending', 'synced'))
);

alter table reminders enable row level security;

create policy "reminders: acesso via veículo do dono"
  on reminders
  for all
  using (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  )
  with check (
    vehicle_id in (
      select id from vehicles where user_id = auth.uid()
    )
  );

create index if not exists idx_reminders_vehicle_id  on reminders (vehicle_id);
create index if not exists idx_reminders_updated_at  on reminders (updated_at);

-- ---------------------------------------------------------------------------
-- 5. usage_quota (controle de cota de scan por mês)
--    PK = user_id (uma linha por usuário).
--    RLS: user_id = auth.uid()
--    NOTA: sem updated_at/sync_status — gerenciado exclusivamente pelo backend
--          (Edge Function). O client só lê.
-- ---------------------------------------------------------------------------
create table if not exists usage_quota (
  user_id     uuid    primary key references auth.users(id) on delete cascade,
  month       text    not null,   -- formato "YYYY-MM", ex.: "2026-05"
  scan_count  integer not null default 0,
  is_premium  boolean not null default false
);

alter table usage_quota enable row level security;

-- Política: usuário lê/escreve só sua própria cota.
-- Escrita (insert/update) ocorre via Edge Function com service_role_key,
-- mas a policy de segurança é mantida para defense-in-depth.
create policy "usage_quota: acesso apenas ao próprio usuário"
  on usage_quota
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- =============================================================================
-- FIM DA MIGRATION 0001
-- Follow-up anotado: Google OAuth (precisa de Google Cloud + URL scheme iOS).
-- =============================================================================
