# Sprint 6.Y — Compartilhar veículo (multi-user via RLS)

> Permite cônjuge/família acessarem o mesmo veículo. MVP simples:
> dono adiciona membro por email; membro vê o veículo + tudo dele.

## Decisões pragmáticas
- 2 papéis: **owner** (criador) e **member** (acesso leitura+escrita igual).
- Sem distinção editor/viewer no MVP (todos editam). Refinar depois.
- Convite por **email** (busca em `auth.users` server-side via edge fn).
- Sem fluxo de aceitar/recusar — adicionar é direto. UI clara que avisa.
- Schema servidor: nova tabela `vehicle_members(vehicle_id, user_id, role, created_at)`.
- RLS atualizada: `vehicles` e tabelas filhas (fuel/expense/reminder/fine/insurance) leem se `user_id == auth.uid()` OR `EXISTS vehicle_members`.
- Sync no client (vehicle_members local pra ver lista de membros offline). PK composta (vehicleId+userId).

## Mudanças

### 1. Migration Supabase `0010_vehicle_members.sql`
```sql
CREATE TABLE IF NOT EXISTS public.vehicle_members (
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (vehicle_id, user_id)
);

ALTER TABLE public.vehicle_members ENABLE ROW LEVEL SECURITY;

-- vehicle_members: dono do veículo gerencia membros; membro vê própria row
CREATE POLICY "vehicle_members_owner_manages" ON public.vehicle_members
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v
            WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v
            WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  );

CREATE POLICY "vehicle_members_self_read" ON public.vehicle_members
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Atualiza policy de vehicles: dono OU membro vê/edita
DROP POLICY IF EXISTS "Users see only their own vehicles" ON public.vehicles;
CREATE POLICY "vehicles_owner_or_member" ON public.vehicles
  FOR ALL TO authenticated USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = id AND vm.user_id = auth.uid())
  ) WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.vehicle_members vm
            WHERE vm.vehicle_id = id AND vm.user_id = auth.uid())
  );

-- Tabelas filhas (fuel_entries, expenses, reminders, fines, insurances):
-- atualizar policies pra também aceitar membros.
DROP POLICY IF EXISTS "Users see own fuel entries" ON public.fuel_entries;
CREATE POLICY "fuel_entries_via_vehicle" ON public.fuel_entries
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v
            WHERE v.id = vehicle_id AND
                  (v.user_id = auth.uid() OR
                   EXISTS (SELECT 1 FROM public.vehicle_members vm
                           WHERE vm.vehicle_id = v.id AND
                                 vm.user_id = auth.uid())))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v
            WHERE v.id = vehicle_id AND
                  (v.user_id = auth.uid() OR
                   EXISTS (SELECT 1 FROM public.vehicle_members vm
                           WHERE vm.vehicle_id = v.id AND
                                 vm.user_id = auth.uid())))
  );

-- Idem pra expenses, reminders, fines, insurances (mesmo pattern).
```

### 2. Edge fn `supabase/functions/share-vehicle/index.ts`
Body: `{vehicle_id, member_email}`.
- Auth JWT do user atual (owner).
- Verifica que user é dono do vehicle_id.
- Busca user pelo email em `auth.users` (via service role).
  - Se não existe: return 404 `email_not_found`.
- Insert em `vehicle_members(vehicle_id, user_id, role='member')`.
- Idempotente: insertOnConflictDoNothing.
- Return: `{ok: true, member_user_id: ...}`.

### 3. Schema Drift v15 — `vehicle_members` local (sync)
```dart
@DataClassName('VehicleMemberRow')
class VehicleMembers extends Table {
  TextColumn get vehicleId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'));
  DateTimeColumn get createdAt => dateTime()();
  // Sync simples — sem soft delete (DELETE direto).
  @override
  Set<Column> get primaryKey => {vehicleId, userId};
}
```

Schema v14 → v15. Migration `if (from < 15) createTable(vehicleMembers)`.

### 4. Modelo + Repository
- `lib/domain/models/vehicle_member.dart` (freezed: vehicleId, userId, role, createdAt).
- `lib/domain/repositories/vehicle_member_repository.dart` (abstract): listByVehicle, watchByVehicle, removeMember.
- `lib/data/repositories/vehicle_member_repository.dart` (Drift impl).

### 5. Service de compartilhamento
`lib/features/vehicles/share_vehicle_service.dart`:
- abstract `ShareVehicleService.shareWith(vehicleId, email)`.
- `RealShareVehicleService` invoca `share-vehicle` edge fn.
- Trata erros: `email_not_found` → `ShareEmailNotFoundException`; genérico → `ScanException`.

### 6. UI — Tela compartilhar
`lib/features/vehicles/share_vehicle_screen.dart`:
- AppBar "Compartilhar veículo".
- Header: nome do veículo + aviso "Pessoas adicionadas vão ver e editar este veículo".
- TextField email + botão "Adicionar". Loading + erros PT-BR.
- Lista de membros atuais (watchByVehicle), cada um com botão "Remover".

### 7. Entry point
Detail vehicle (`fuel_history_screen` ou onde tem menu de ações do veículo) — adicionar botão "Compartilhar".

### 8. Rota
`/vehicles/:vehicleId/share` → ShareVehicleScreen.

### 9. Atualizar `vehiclesProvider`
Lista de veículos do user JÁ vai funcionar via RLS (Supabase retorna donados+compartilhados). Mas o Drift local só tem os do user — precisa que sync puxe também os compartilhados.

`remote_vehicle_source.dart` — Supabase impl já faz `SELECT *` sem `.eq('user_id')` (RLS filtra). Vai trazer compartilhados automaticamente. **Nada a mudar no sync.**

### 10. Migration Drift v15 + tests
- `test/data/local/vehicle_members_schema_v15_test.dart`
- `test/data/repositories/vehicle_member_repository_test.dart`
- `test/features/vehicles/share_vehicle_service_test.dart`

## Critérios
- Suite verde (873 + ~20 novos)
- analyze 0, iOS build OK
- Migration 0010 + edge fn `share-vehicle` documentados pra deploy manual

## Não-objetivos
- Distinção editor/viewer (todos editam no MVP)
- Convite com aceitar/recusar (adicionar é direto)
- Email pro convidado avisar (sem SMTP)
