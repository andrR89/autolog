# Sprint 6.O — Documentos pessoais (CNH, multas, seguro)

> Onda 2, sprint 3/10. Cluster de "documentos & compliance".
> Adiciona dados de CNH (vencimento) + tabela de multas + dados de apólice de seguro,
> tudo no escopo do **usuário** (não do veículo) — exceto multas (por veículo).

## Decisões pragmáticas

- **CNH** vai no perfil do usuário (novo). Será multi-vehicle ready (uma CNH serve todos os veículos do user).
- **Multas** vão por veículo (cada multa vincula a 1 veículo) — entidade nova, sincronizada via padrão (UUID client).
- **Seguro** vai por veículo (uma apólice por veículo por período) — entidade nova.
- **Lembretes automáticos** quando vencimento perto: CNH 30 dias antes; seguro 60 dias antes; multas com prazo de pagamento 7 dias antes.
- **Sem IA, sem scan** nessa sprint — entrada manual via forms. Pós-MVP: scan da CNH + scan de auto de infração.

## Mudanças

### 1. Tabela `UserProfile` (Drift) — dados do usuário, local-first
Novo arquivo: `lib/data/local/tables.dart` (adicionar):
```dart
@DataClassName('UserProfileRow')
class UserProfile extends Table {
  TextColumn get userId => text()();             // PK
  TextColumn get cnhNumber => text().nullable()();
  TextColumn get cnhCategory => text().nullable()(); // 'A','B','AB','C','D','E'
  DateTimeColumn get cnhExpiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {userId};
}
```

### 2. Tabela `Fines` (multas) — por veículo, sincronizada
```dart
@DataClassName('FineRow')
class Fines extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get autoNumber => text().nullable()();   // número do auto
  DateTimeColumn get issuedAt => dateTime()();         // data infração
  TextColumn get description => text()();
  TextColumn get amount => text().map(const DecimalConverter())();
  DateTimeColumn get dueDate => dateTime().nullable()(); // prazo pagamento
  BoolColumn get paid => boolean().withDefault(const Constant(false))();
  IntColumn get points => integer().nullable()();      // pontos CNH

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3. Tabela `Insurances` (apólices de seguro) — por veículo, sincronizada
```dart
@DataClassName('InsuranceRow')
class Insurances extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get insurer => text().nullable()();      // "Porto Seguro", "Bradesco"...
  TextColumn get policyNumber => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get premiumPaid => text().map(const DecimalConverter()).nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 4. Schema v6 → v7
`lib/data/local/database.dart`:
- Bump `schemaVersion` 6 → 7.
- Add 3 tabelas ao `@DriftDatabase(tables: [..., UserProfile, Fines, Insurances])`.
- `onUpgrade`:
```dart
if (from < 7) {
  await m.createTable(userProfile);
  await m.createTable(fines);
  await m.createTable(insurances);
}
```

### 5. Models freezed (`lib/domain/models/`)
3 arquivos novos:
- `user_profile.dart` (`UserProfile` com fields)
- `fine.dart` (`Fine`)
- `insurance.dart` (`Insurance`)

Cada um com `@freezed`, `@SyncStatusConverter()`, etc. — espelha pattern do `Reminder`.

### 6. Repositories
3 abstract + Drift impl:
- `lib/domain/repositories/user_profile_repository.dart` + `lib/data/repositories/user_profile_repository.dart`
- `lib/domain/repositories/fine_repository.dart` + `lib/data/repositories/fine_repository.dart`
- `lib/domain/repositories/insurance_repository.dart` + `lib/data/repositories/insurance_repository.dart`

CRUD básico + watch (Stream) + listByVehicle (pros que aplicam).

### 7. UI — Tela "Documentos pessoais" (nova)
Arquivo: `lib/features/personal_documents/personal_documents_screen.dart`

Tela top-level acessível do menu/aba. Layout:
- Seção **"Minha CNH"**: card com número/categoria/vencimento. Botão editar.
- Seção **"Apólices ativas"**: lista de cards (uma por insurance ativa de qualquer veículo). Vazia = empty state amigável.
- Seção **"Multas pendentes"**: lista de cards (uma por fine não paga). Vazia = "Sem multas — bom motorista 🏆".

Form sub-pages:
- `cnh_form_screen.dart`: campos número (11 dígitos), categoria (dropdown A/B/AB/C/D/E), vencimento (date picker).
- `fine_form_screen.dart`: vehicle (dropdown), número do auto, data infração, descrição, valor (Decimal), prazo pagamento, pontos.
- `insurance_form_screen.dart`: vehicle, seguradora, número apólice, vigência (início/fim), valor pago.

### 8. Lembretes automáticos
Função pura `lib/features/personal_documents/document_reminder_suggestions.dart`:
```dart
/// Gera ProposedReminders pra documentos com vencimento próximo.
List<ProposedReminder> suggestDocumentReminders({
  required UserProfile? profile,
  required List<Fine> unpaidFines,
  required List<Insurance> activeInsurances,
  required DateTime now,
});
```
Regras:
- CNH vence em X dias (X ≤ 30) → 1 ProposedReminder "Renovar CNH" com `dueDate = cnhExpiresAt - 30 dias`.
- Insurance vence em X dias (X ≤ 60) → 1 ProposedReminder "Renovar seguro {insurer}" com `dueDate = endsAt - 60 dias`.
- Fine com `dueDate` definido E não-paga E `dueDate - now ≤ 7 dias` → 1 ProposedReminder "Pagar multa {autoNumber}" com `dueDate = fine.dueDate - 7 dias`.

Integração: novo botão "Lembretes de documentos" na `PersonalDocumentsScreen` que aplica dedupe e oferece criar.

### 9. Rota e nav
- Adicionar rota `/personal-documents` em `lib/core/router.dart`.
- Adicionar item de navegação na barra principal (ou no drawer): "Documentos" com ícone `Icons.badge_outlined`.

### 10. Sync (8 entidades agora!)
- Atualizar `GlobalSyncService` pra incluir 3 novas (fines, insurances, user_profile).
- Cada uma tem facade + service (espelho do `fuel/expense/reminder` da Onda 1).
- `user_profile` tem PK = userId, então sync é trivial (1 row por user; upsert sempre).

Documentação adicional: spec a parte pra cada sync se preferir, mas pra MVP do 6.O implemente direto.

### 11. Supabase migrations
`supabase/migrations/0007_personal_documents.sql`:
```sql
CREATE TABLE IF NOT EXISTS public.user_profile (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  cnh_number text,
  cnh_category text,
  cnh_expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  sync_status text NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS public.fines (
  id uuid PRIMARY KEY,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  auto_number text,
  issued_at timestamptz NOT NULL,
  description text NOT NULL,
  amount text NOT NULL,
  due_date timestamptz,
  paid boolean NOT NULL DEFAULT false,
  points int,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  sync_status text NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS public.insurances (
  id uuid PRIMARY KEY,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  insurer text,
  policy_number text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  premium_paid text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  sync_status text NOT NULL DEFAULT 'pending'
);

-- RLS
ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insurances ENABLE ROW LEVEL SECURITY;

-- user_profile: user só vê o próprio
CREATE POLICY "user_profile_own" ON public.user_profile
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- fines/insurances: user vê os de veículos seus (via join)
CREATE POLICY "fines_own_via_vehicle" ON public.fines
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  );

CREATE POLICY "insurances_own_via_vehicle" ON public.insurances
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id = vehicle_id AND v.user_id = auth.uid())
  );
```

## Testes

### `test/data/local/personal_documents_schema_test.dart` (novo)
- `schemaVersion == 7`.
- 3 novas tabelas existem; inserts + reads funcionam.
- Migration v6 → v7: criar 3 tabelas, preservar dados anteriores.

### `test/data/repositories/fine_repository_test.dart` (novo)
- CRUD básico, soft delete, listByVehicle, watchUnpaid.

### `test/data/repositories/insurance_repository_test.dart` (novo)
- CRUD, listByVehicle, activeInsurances (vigência atual).

### `test/data/repositories/user_profile_repository_test.dart` (novo)
- getOrCreate, update, watch.

### `test/features/personal_documents/document_reminder_suggestions_test.dart` (novo)
- CNH expira em 25 dias → 1 proposta.
- CNH expira em 60 dias → 0 propostas (fora janela).
- Insurance expira em 30 dias → 1 proposta.
- Fine due em 5 dias E não paga → 1 proposta.
- Fine paid → 0 propostas mesmo com due próximo.
- Vários combinados.

## Critérios de aceite
- [ ] Todos testes verdes (547+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela "Documentos pessoais" navegável
- [ ] Forms de CNH/multa/seguro funcionais
- [ ] Sugestões de lembrete com dedupe

## Não-objetivos (próximos sprints / pós-MVP)
- Scan da CNH foto/PDF (pós-MVP).
- Scan do auto de infração (pós-MVP).
- Consulta automática no Detran (rejeitado).
- Comparador de seguradoras com cotação (futuro).
- Apólices históricas (já cobre: cria nova com vigência futura).
