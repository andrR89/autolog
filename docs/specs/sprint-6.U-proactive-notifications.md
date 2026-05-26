# Sprint 6.U — Notificações proativas (push local)

> Onda 2, sprint 9/10. Detector puro + agendamento de notificação local.
> Sem push remoto (FCM/APN sprint futura), só `flutter_local_notifications` já no projeto.

## Decisões pragmáticas
- **Notificações LOCAIS** apenas (já tem `flutter_local_notifications: ^18.0.1` no pubspec).
- Trigger: após salvar abastecimento OU ao abrir app — invoca `evaluateAndNotify(vehicleId)`.
- 3 detectores no MVP:
  1. **Consumo degradou >10%** vs janela anterior (usa `analyzeConsumptionTrend` do 6.Q).
  2. **CNH vence em 30-7 dias** (sweet spot pra avisar).
  3. **IPVA/Licenciamento vence em 30 dias** (calendário fiscal do 6.N).
- Dedupe: tabela local `notifications_log` registra cada notificação enviada → evita spam (1 por categoria a cada 7 dias).
- Tela de Settings com switches por categoria + "Habilitar notificações".

## Mudanças

### 1. Tabela `NotificationsLog` (local-only)
`lib/data/local/tables.dart`:
```dart
@DataClassName('NotificationLogRow')
class NotificationsLog extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get category => text()(); // 'consumption_drop' | 'cnh' | 'fiscal' | ...
  DateTimeColumn get sentAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Schema v9 → v10. Migration `if (from < 10) { createTable(notificationsLog); }`.

### 2. Detector puro (`lib/features/notifications/notification_evaluator.dart`)

```dart
class NotificationProposal {
  const NotificationProposal({
    required this.category,
    required this.title,
    required this.body,
  });
  final String category;
  final String title;
  final String body;
}

/// Avalia todos os detectores e devolve a primeira proposta acionável (ordem
/// de prioridade fixa: fiscal urgente > cnh urgente > consumo degradou).
/// Retorna null se nada pra notificar.
NotificationProposal? evaluateNotifications({
  required List<FuelEntry> fuelEntries,
  required UserProfile? userProfile,
  required List<NotificationLogRow> recentLog,
  required DateTime now,
  required String vehicleId,
  required String? vehicleUf,
  required String? vehiclePlate,
});
```

Heurísticas:
- **Consumption drop**: se `analyzeConsumptionTrend(entries).direction == down` E `deltaPercent.abs() > 10` E não notificou nos últimos 7 dias.
- **CNH urgente**: profile.cnhExpiresAt entre 7 e 30 dias da `now` E não notificou nos últimos 7 dias.
- **Fiscal urgente**: `suggestFiscalReminders(uf, plate, year)` (6.N) → se algum dueDate cai em 7-30 dias da `now`, gera proposta.

Dedupe: `recentLog` filtrado por `category` E `sentAt > now - 7d`.

### 3. Service com plugin
`lib/features/notifications/notification_service.dart`:

```dart
abstract class ProactiveNotificationService {
  Future<bool> ensurePermissionGranted();
  Future<void> schedule(NotificationProposal proposal, {required String vehicleId});
  Future<List<NotificationLogRow>> recentLog(String vehicleId);
}

class RealProactiveNotificationService implements ProactiveNotificationService {
  RealProactiveNotificationService(this._plugin, this._db);
  final FlutterLocalNotificationsPlugin _plugin;
  final AppDatabase _db;
  // initialize + schedule + persistir no notifications_log
}

class FakeProactiveNotificationService implements ProactiveNotificationService {
  // pra testes
}
```

### 4. Orquestrador
`lib/features/notifications/notification_orchestrator.dart`:

```dart
final notificationOrchestratorProvider = Provider((ref) {
  return NotificationOrchestrator(
    fuelRepo: ref.watch(fuelEntryRepositoryProvider),
    profileRepo: ref.watch(userProfileRepositoryProvider),
    vehicleRepo: ref.watch(vehicleRepositoryProvider),
    notifService: ref.watch(notificationServiceProvider),
  );
});

class NotificationOrchestrator {
  Future<void> evaluateAndNotify(String vehicleId, String userId) async {
    final v = await vehicleRepo.getById(vehicleId);
    if (v == null) return;
    final entries = await fuelRepo.listByVehicle(vehicleId);
    final profile = await profileRepo.getById(userId);
    final log = await notifService.recentLog(vehicleId);
    final proposal = evaluateNotifications(
      fuelEntries: entries, userProfile: profile,
      recentLog: log, now: DateTime.now(),
      vehicleId: vehicleId, vehicleUf: v.uf, vehiclePlate: v.plate,
    );
    if (proposal != null) {
      await notifService.schedule(proposal, vehicleId: vehicleId);
    }
  }
}
```

### 5. Trigger
`lib/features/fuel/fuel_entry_saver.dart`:
- Após save, chama `orchestrator.evaluateAndNotify(vehicleId, userId)` em fire-and-forget (não bloqueia UI).

### 6. Tela de Settings
`lib/features/settings/settings_screen.dart`:
- Acessada do menu/perfil.
- Switch global "Notificações proativas".
- Switches por categoria (sub-itens, desabilitados se global off): "Consumo subindo", "Vencimentos (CNH)", "Vencimentos fiscais (IPVA)".
- Persiste em SharedPreferences (simples — sem nova tabela).

`evaluateNotifications` recebe uma flag `NotificationPreferences` injetada (categorias desabilitadas pulam).

### 7. Permissões
- iOS: pedir permissão na primeira abertura ou no toggle "Habilitar".
- Android: 13+ requer permissão POST_NOTIFICATIONS — pedir no toggle.

### 8. Rota
`/settings` → `SettingsScreen`. Entry point: perfil/menu.

## Testes RED

### `test/features/notifications/notification_evaluator_test.dart`

- Sem dados → null.
- Consumo estável → null.
- Consumo piorou 12% → proposta `consumption_drop`.
- CNH vence em 20 dias → proposta `cnh`.
- CNH vence em 5 dias → null (passou da janela 30-7).
- CNH vence em 60 dias → null (fora da janela).
- IPVA vence em 20 dias → proposta `fiscal`.
- Múltiplos detectores: prioriza fiscal > cnh > consumo.
- Já notificou consumption_drop há 3 dias → null (dedupe 7d).
- Já notificou há 8 dias → renotifica.
- Sem profile + sem UF/placa → ainda checa consumo.

## Critérios de aceite
- [ ] Todos testes verdes (731+ + ~10 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Settings persiste preferências
- [ ] Schedule de notificação local funciona (smoke test no device)

## Não-objetivos
- Push remoto FCM/APN (sprint futura).
- Notificações ricas com ações inline.
- Notificações por horário do dia (futuro).
