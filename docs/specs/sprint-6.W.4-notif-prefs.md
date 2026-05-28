# Sprint 6.W.4 — Notif prefs persistentes

> Extende `UserSettings` (já existente) com switches por categoria de
> notificação proativa. Settings ganha seção "Notificações".

## Decisões
- 4 categorias de notif (do `notification_evaluator`):
  - `consumption_drop` — consumo piorou >10%
  - `cnh` — habilitação vencendo
  - `fiscal` — IPVA/Licenciamento vencendo
  - `recap_ready` — recap do mês anterior pronto
- Defaults: TODAS ligadas (opt-out, não opt-in).
- Schema v14 — adicionar 4 bool columns ao `UserSettings`.

## Mudanças

### 1. Schema v14
`lib/data/local/tables.dart`:
```dart
class UserSettings extends Table {
  TextColumn get userId => text()();
  TextColumn get themePref => text().withDefault(const Constant('system'));
  BoolColumn get notifConsumptionDrop => boolean().withDefault(const Constant(true))();
  BoolColumn get notifCnh => boolean().withDefault(const Constant(true))();
  BoolColumn get notifFiscal => boolean().withDefault(const Constant(true))();
  BoolColumn get notifRecapReady => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {userId};
}
```

`lib/data/local/database.dart`:
- Bump `schemaVersion` 13 → 14.
- Migration:
```dart
if (from < 14) {
  await m.addColumn(userSettings, userSettings.notifConsumptionDrop);
  await m.addColumn(userSettings, userSettings.notifCnh);
  await m.addColumn(userSettings, userSettings.notifFiscal);
  await m.addColumn(userSettings, userSettings.notifRecapReady);
}
```

Atualizar tests de schema antigos: `schemaVersion == 14`.

### 2. Modelo `NotificationPreferences`
`lib/domain/repositories/user_settings_repository.dart`:
```dart
class NotificationPreferences {
  const NotificationPreferences({
    this.consumptionDrop = true,
    this.cnh = true,
    this.fiscal = true,
    this.recapReady = true,
  });
  final bool consumptionDrop, cnh, fiscal, recapReady;

  bool enabled(String category) => switch (category) {
    'consumption_drop' => consumptionDrop,
    'cnh' => cnh,
    'fiscal' => fiscal,
    'recap_ready' => recapReady,
    _ => true,
  };
}
```

### 3. Estender repository
`UserSettingsRepository` + Drift impl:
- `Future<NotificationPreferences> getNotifPrefs(String userId)`
- `Future<void> setNotifPref(String userId, String category, bool enabled)`
- `Stream<NotificationPreferences> watchNotifPrefs(String userId)`

### 4. Evaluator filtra por prefs
`lib/features/notifications/notification_evaluator.dart`:
- Adicionar param opcional `NotificationPreferences? preferences`.
- Antes de retornar uma `NotificationProposal`, checar `preferences?.enabled(category) ?? true`. Se false, pular pra próxima categoria.

### 5. Orchestrator passa prefs
`lib/features/notifications/notification_orchestrator.dart`:
- Receber `userSettingsRepository` no constructor.
- Em `evaluateAndNotify`, ler `prefs = await userSettingsRepo.getNotifPrefs(userId)` e passar pro `evaluateNotifications`.

### 6. Settings screen
`lib/features/settings/settings_screen.dart`:
- Nova `_NotificationsCard` abaixo do `_AppearanceCard`.
- 4 `SwitchListTile`:
  - "Consumo piorando"
  - "CNH próxima do vencimento"
  - "IPVA / Licenciamento próximo"
  - "Recap mensal pronto"
- Toggle dispara `repo.setNotifPref(...)`.

## Testes
- `test/data/local/user_settings_v14_test.dart` — schema bump + migration.
- `test/data/repositories/user_settings_notif_prefs_test.dart` — get/set/watch.
- `test/features/notifications/notification_evaluator_test.dart` — adicionar grupo cobrindo prefs:
  - prefs.consumption_drop = false → consumo piorou mas não notifica (cai pra null).
  - prefs.fiscal = false → fiscal urgente mas pula pra cnh.

## Critérios
- Suite verde (844 + ~15 novos)
- analyze 0, iOS build OK
