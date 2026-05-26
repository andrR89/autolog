# Sprint 6.J — Histórico FIPE + gráfico

> Onda 1, sprint 3/5. Depende do 6.I (precisa `fipeCode` e `fipeValue`).
> Mostra evolução do valor FIPE ao longo do tempo.

## Decisões pragmáticas
- **Snapshot local-only no MVP** (não sincroniza entre devices). Cada consulta FIPE do user gera 1 ponto. Sync entre dispositivos + cron mensal automático ficam como TODO pós-MVP — listei em "Não-objetivos".
- **Lib de gráfico:** `fl_chart` (já está no projeto).
- **Snapshots automáticos:** ao aplicar resultado FIPE (`_applyFipeResult` do form), salva snapshot `(vehicleId, month, value)`. Idempotente — se já existe snapshot do mesmo mês, sobrescreve com o valor mais recente.

## Mudanças

### 1. Nova tabela `FipeHistory` (`lib/data/local/tables.dart`)
```dart
@DataClassName('FipeHistoryRow')
class FipeHistory extends Table {
  TextColumn get vehicleId => text()();
  TextColumn get month => text()();        // "YYYY-MM"
  TextColumn get value => text().map(const DecimalConverter())();
  DateTimeColumn get capturedAt => dateTime()(); // quando o snapshot foi salvo

  @override
  Set<Column> get primaryKey => {vehicleId, month};
}
```
PK composta `(vehicleId, month)` garante idempotência natural.

Adicionar `FipeHistory` ao `@DriftDatabase(tables: [...])`.

### 2. Schema v4 → v5
`lib/data/local/database.dart`
```dart
@override
int get schemaVersion => 5;

// no onUpgrade:
if (from < 5) {
  await m.createTable(fipeHistory);
}
```

### 3. Repository (`lib/data/repositories/fipe_history_repository.dart`)
```dart
abstract class FipeHistoryRepository {
  /// Upsert (idempotente por PK composta).
  Future<void> saveSnapshot({
    required String vehicleId,
    required String month,    // "YYYY-MM"
    required Decimal value,
  });

  /// Lista snapshots ordenados por mês ASC.
  Future<List<FipeSnapshot>> listByVehicle(String vehicleId);

  /// Últimos N meses preenchidos (ordem ASC). N=12 padrão.
  Future<List<FipeSnapshot>> recent(String vehicleId, {int months = 12});

  /// Stream pra reatividade no detalhe.
  Stream<List<FipeSnapshot>> watchByVehicle(String vehicleId);
}

class DriftFipeHistoryRepository implements FipeHistoryRepository { ... }
```

`FipeSnapshot` é um value object:
```dart
class FipeSnapshot {
  const FipeSnapshot({required this.month, required this.value});
  final String month;       // "YYYY-MM"
  final Decimal value;
}
```

### 4. Snapshot automático no form
`lib/features/vehicles/vehicle_form_screen.dart`

Logo após o `_applyFipeResult` preencher os controllers:
```dart
final repo = ref.read(fipeHistoryRepositoryProvider);
await repo.saveSnapshot(
  vehicleId: widget.vehicle?.id ?? _draftId,
  month: result.referenceMonth,
  value: result.priceValue,
);
```

Edge case: no modo "criar", o vehicleId ainda não existe — guarda o snapshot pendente em state local e dispara após o save do veículo. Solução simples: usa `_draftId = const Uuid().v4()` no `initState` e usa o mesmo id pra criar o veículo no submit (já é client-generated por padrão).

### 5. Widget de gráfico (`lib/features/vehicles/widgets/fipe_history_chart.dart`)

Card com:
- **Título:** "Valor FIPE"
- **Sub:** "{N pontos coletados}" pequeno
- **Conteúdo:**
  - 0 pontos → empty state PT-BR: "Atualize o valor FIPE no cadastro pra começar o histórico"
  - 1 ponto → card com o valor único + dica "1 ponto coletado em {mês}"
  - 2+ pontos → `fl_chart` LineChart 12m, eixo X mostra meses, eixo Y formato compacto. Tooltip ao tocar.
- **Delta YoY badge** (quando 13+ pontos): "+3,2%" verde ou "-8,1%" vermelho. Comparação valor do mês mais recente vs ~12 meses atrás (busca o snapshot mais próximo de currentMonth - 12).

Use AppColors, AppTypography, AppSpacing.

### 6. Integração no detalhe do veículo
Arquivo: `lib/features/fuel/fuel_history_screen.dart`

Antes do histórico de abastecimentos (ou abaixo do header do veículo), inserir `FipeHistoryChart(vehicleId: vehicle.id)`. Discreto — só aparece se o veículo tem `fipeCode` configurado.

### 7. Provider
```dart
final fipeHistoryRepositoryProvider = Provider<FipeHistoryRepository>((ref) {
  return DriftFipeHistoryRepository(ref.watch(appDatabaseProvider));
});

final fipeHistoryProvider =
    StreamProvider.family<List<FipeSnapshot>, String>((ref, vehicleId) {
  return ref.watch(fipeHistoryRepositoryProvider).watchByVehicle(vehicleId);
});
```

### 8. Migration Supabase
**Não há migration de servidor neste MVP** — `fipe_history` é local-only. (Pós-MVP: criar tabela `public.fipe_history(vehicle_id, month, value, captured_at)` + estender `GlobalSyncService` pra incluir.)

## Testes (todos RED até implementação)

### `test/data/local/fipe_history_schema_test.dart` (novo)
- `schemaVersion == 5`.
- Tabela `fipe_history` aceita insert + read.
- PK composta `(vehicleId, month)` recusa duplicata diferente OU upsert sobrescreve (decisão: usar `insertOnConflictUpdate` no repo).
- Migration v4→v5: cria a tabela; veículos existentes preservados.

### `test/data/repositories/fipe_history_repository_test.dart` (novo)
- `saveSnapshot` insere; segundo save mesmo (vehicleId, month) atualiza value.
- `listByVehicle` retorna ordenado por month ASC.
- `recent(months: 12)` retorna no máximo 12 snapshots mais recentes (sem ordering quebrado).
- Snapshots de outros veículos não vazam.
- `watchByVehicle` emite ao salvar novo snapshot.

### `test/features/vehicles/widgets/fipe_history_chart_test.dart` (widget test simples)
- 0 pontos → renderiza empty state.
- 1 ponto → renderiza valor único.
- 3 pontos → renderiza LineChart (verifica que o widget `LineChart` está presente).
- 13+ pontos → renderiza badge YoY com sinal e cor corretos.

## Critérios de aceite
- [ ] Todos os testes verdes (449+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Form salva snapshot automaticamente após aplicar resultado FIPE
- [ ] Detalhe do veículo mostra o gráfico quando há ≥ 1 snapshot

## Não-objetivos (pós-MVP)
- Sync de `fipe_history` entre dispositivos (PK composta requer ajuste no `GlobalSyncService`).
- Cron mensal automático no backend (Supabase pg_cron + edge function).
- Comparativo com FIPE de modelos similares ("seu Civic vs Corolla").
- Alerta proativo "valor caiu X% — momento bom de comprar/vender".
