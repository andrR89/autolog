import 'package:autolog/data/local/converters.dart';
import 'package:drift/drift.dart';

/// Campos de sync compartilhados pelas 4 tabelas sincronizáveis.
/// Drift não suporta mixins de tabela diretamente — os campos são repetidos
/// em cada tabela conforme a documentação do Drift.

// ---------------------------------------------------------------------------
// vehicles
// ---------------------------------------------------------------------------

@DataClassName('VehicleRow')
class Vehicles extends Table {
  /// PK: UUID gerado no client.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get nickname => text()();
  TextColumn get make => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get uf => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get type =>
      text().map(const VehicleTypeConverter()).withDefault(const Constant('carro'))();
  IntColumn get engineDisplacementCc => integer().nullable()();
  TextColumn get tankCapacityL =>
      text().map(const DecimalConverter()).nullable()();
  IntColumn get horsepower => integer().nullable()();
  TextColumn get fipeCode => text().nullable()();
  TextColumn get fipeValue => text().map(const DecimalConverter()).nullable()();
  TextColumn get fipeReferenceMonth => text().nullable()();
  TextColumn get plate => text().nullable()();
  TextColumn get renavam => text().nullable()();
  TextColumn get chassi => text().nullable()();
  TextColumn get fuelType => text().map(const FuelTypeConverter())();
  IntColumn get initialOdometer => integer()();

  // Campos de sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// fuel_entries
// ---------------------------------------------------------------------------

@DataClassName('FuelEntryRow')
class FuelEntries extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get odometer => integer()();
  TextColumn get liters => text().map(const DecimalConverter())();
  TextColumn get pricePerLiter => text().map(const DecimalConverter())();
  TextColumn get totalCost => text().map(const DecimalConverter())();
  BoolColumn get fullTank => boolean()();
  TextColumn get fuelType => text().map(const FuelTypeConverter())();
  TextColumn get source => text().map(const FuelSourceConverter())();
  TextColumn get receiptImageUrl => text().nullable()();
  TextColumn get stationName => text().nullable()();
  TextColumn get stationBrand => text().nullable()();

  // Campos de sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// expenses
// ---------------------------------------------------------------------------

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().map(const ExpenseCategoryConverter())();
  TextColumn get description => text()();
  TextColumn get amount => text().map(const DecimalConverter())();
  IntColumn get odometer => integer().nullable()();

  // Campos de sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// reminders
// ---------------------------------------------------------------------------

@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get type => text().map(const ReminderTypeConverter())();
  TextColumn get title => text()();
  IntColumn get dueKm => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  // Campos de sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// fipe_cache — local-only, NÃO sincroniza com Supabase
// ---------------------------------------------------------------------------

@DataClassName('FipeCacheRow')
class FipeCache extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// fipe_history — local-only, NÃO sincroniza com Supabase
// ---------------------------------------------------------------------------

@DataClassName('FipeHistoryRow')
class FipeHistory extends Table {
  TextColumn get vehicleId => text()();
  TextColumn get month => text()(); // "YYYY-MM"
  TextColumn get value => text().map(const DecimalConverter())();
  DateTimeColumn get capturedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {vehicleId, month};
}

// ---------------------------------------------------------------------------
// user_profile — dados do usuário (CNH), local-first. PK = userId.
// ---------------------------------------------------------------------------

@DataClassName('UserProfileRow')
class UserProfile extends Table {
  /// PK: user_id (UUID do Supabase Auth — não vehicleId).
  TextColumn get userId => text()();
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

// ---------------------------------------------------------------------------
// fines — multas por veículo, sincronizadas
// ---------------------------------------------------------------------------

@DataClassName('FineRow')
class Fines extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get autoNumber => text().nullable()(); // número do auto
  DateTimeColumn get issuedAt => dateTime()(); // data infração
  TextColumn get description => text()();
  TextColumn get amount => text().map(const DecimalConverter())();
  DateTimeColumn get dueDate => dateTime().nullable()(); // prazo pagamento
  BoolColumn get paid => boolean().withDefault(const Constant(false))();
  IntColumn get points => integer().nullable()(); // pontos CNH

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// insurances — apólices de seguro por veículo, sincronizadas
// ---------------------------------------------------------------------------

@DataClassName('InsuranceRow')
class Insurances extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get insurer => text().nullable()(); // "Porto Seguro", "Bradesco"...
  TextColumn get policyNumber => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get premiumPaid =>
      text().map(const DecimalConverter()).nullable()();
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

// ---------------------------------------------------------------------------
// chat_messages — local-only, NÃO sincroniza com Supabase
// ---------------------------------------------------------------------------

@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get role => text()(); // 'user' | 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// notifications_log — local-only, Sprint 6.U. Registro de notificações já
// enviadas pra suportar dedupe (7d por categoria).
// ---------------------------------------------------------------------------

@DataClassName('NotificationLogRow')
class NotificationsLog extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get category => text()(); // 'consumption_drop' | 'cnh' | 'fiscal'
  DateTimeColumn get sentAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// fiscal_lookup_cache — local-only, NÃO sincroniza com Supabase
// ---------------------------------------------------------------------------

@DataClassName('FiscalLookupCacheRow')
class FiscalLookupCache extends Table {
  TextColumn get cacheKey => text()(); // "UF-digit-year" ex "SC-6-2026"
  TextColumn get value => text()(); // JSON serializado
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

// ---------------------------------------------------------------------------
// user_settings — preferências locais do usuário (theme mode etc).
// PK = userId. Local-only; não sincroniza com Supabase.
// ---------------------------------------------------------------------------

@DataClassName('UserSettingsRow')
class UserSettings extends Table {
  TextColumn get userId => text()();
  // 'themePref' armazena 'system' | 'light' | 'dark'.
  // Nota: 'themeMode' é reservado internamente pelo Drift; usar 'themePref'.
  TextColumn get themePref => text().withDefault(const Constant('system'))();

  // Preferências de notificações proativas (Sprint 6.W.4). Todas true = opt-out.
  BoolColumn get notifConsumptionDrop =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notifCnh => boolean().withDefault(const Constant(true))();
  BoolColumn get notifFiscal => boolean().withDefault(const Constant(true))();
  BoolColumn get notifRecapReady =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {userId};
}

// ---------------------------------------------------------------------------
// trips — agrupamento local de fuel_entries + expenses por intervalo de datas.
// Local-only no MVP; NÃO entra em GlobalSync.
// ---------------------------------------------------------------------------

@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// vehicle_members — membros compartilhados de um veículo (Sprint 6.Y).
// PK composta (vehicleId + userId). Sem soft delete — remoção é DELETE.
// Sync futuro: pós-MVP. No MVP, operação via Edge Fn atualiza local também.
// ---------------------------------------------------------------------------

@DataClassName('VehicleMemberRow')
class VehicleMembers extends Table {
  TextColumn get vehicleId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {vehicleId, userId};
}

// ---------------------------------------------------------------------------
// usage_quota — sem campos de sync (ver ARCHITECTURE §3 e spec §4)
// ---------------------------------------------------------------------------

@DataClassName('UsageQuotaRow')
class UsageQuota extends Table {
  /// PK: user_id (UUID do Supabase Auth).
  TextColumn get userId => text()();
  TextColumn get month => text()(); // "YYYY-MM"
  IntColumn get scanCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId};
}
