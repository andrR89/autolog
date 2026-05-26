# Sprint 6.G — Insights de IA (análise sob demanda)

> Última peça do trio pré-monetização (6.E ✅ / 6.F ✅ / 6.G).
> Analisa o histórico do veículo via Haiku e sugere padrões + lembretes proativos.

## Decisões do Diretor
- **Trigger sob demanda** — user toca "Analisar histórico", roda 1 chamada.
- **Cota nova `analysis_count`** em `usage_quota`: **3/mês free**, ilimitado premium.
- **Dedupe**: nunca propor lembrete que já existe (mesmo título norm. + data ± 14 dias).
- Backend valida cota server-side (Regra de Ouro #5).

## Arquivos novos

### `lib/features/insights/history_insights.dart` (freezed)
```dart
@freezed
abstract class HistoryInsights with _$HistoryInsights {
  const factory HistoryInsights({
    required List<DetectedPattern> patterns,
    required List<ProposedReminder> proposedReminders,
  }) = _HistoryInsights;
  factory HistoryInsights.fromJson(Map<String, dynamic> json) =>
      _$HistoryInsightsFromJson(json);
}

@freezed
abstract class DetectedPattern with _$DetectedPattern {
  const factory DetectedPattern({
    required String category,    // ex: "ipva", "manutencao_periodica"
    required String cadence,     // 'yearly' | 'monthly' | 'every_N_km' | 'unknown'
    DateTime? nextDue,
    @Default(0.0) double confidence,
    String? rationale,
  }) = _DetectedPattern;
  factory DetectedPattern.fromJson(Map<String, dynamic> json) =>
      _$DetectedPatternFromJson(json);
}

@freezed
abstract class ProposedReminder with _$ProposedReminder {
  const factory ProposedReminder({
    required String title,
    DateTime? dueDate,
    int? dueKm,
    @Default('') String rationale,
  }) = _ProposedReminder;
  factory ProposedReminder.fromJson(Map<String, dynamic> json) =>
      _$ProposedReminderFromJson(json);
}
```

### `lib/features/insights/insights_service.dart`
Espelho de `RealExpenseScanService` (sem imagem, com `vehicleId`):
```dart
abstract class InsightsService {
  Future<HistoryInsights> analyze(String vehicleId);
}

class RealInsightsService implements InsightsService {
  RealInsightsService(this._invoker);
  final EdgeFunctionInvoker _invoker;

  @override
  Future<HistoryInsights> analyze(String vehicleId) async {
    try {
      final body = await _invoker.invoke('analyze-history', {
        'vehicle_id': vehicleId,
      });
      return HistoryInsights.fromJson(body);
    } on QuotaExhaustedException { rethrow; }
    on ScanException { rethrow; }
    catch (e) {
      throw ScanException('Falha ao analisar histórico', cause: e);
    }
  }
}

class MockInsightsService implements InsightsService { ... }

final insightsServiceProvider = Provider<InsightsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealInsightsService(SupabaseEdgeFunctionInvoker(client));
});
```
Reusa `EdgeFunctionInvoker`, `QuotaExhaustedException`, `ScanException`.

### `lib/features/insights/dedupe.dart` — Lógica pura de dedupe
```dart
/// Filtra propostas que já existem como Reminder ativo.
/// Match = título normalizado igual E (dueDate dentro de ±14 dias OU dueKm igual).
/// Normalização de título: trim + lowercase + remove acentos.
List<ProposedReminder> dedupeProposed(
  List<ProposedReminder> proposed,
  List<Reminder> existing,
);

String normalizeTitle(String title);
```

### `supabase/functions/analyze-history/index.ts`
- Auth via JWT igual `scan-receipt`.
- Quota check em `usage_quota.analysis_count` (limit 3/mês free).
- Busca vehicle + último 36 meses de expenses + últimos 36 meses de fuel_entries.
- Monta prompt PT-BR estruturado com os dados em formato compacto.
- Chama Claude Haiku 4.5 com max_tokens 2048 (output maior que scan).
- Parse defensivo + validação shape.
- Incrementa `analysis_count` só em sucesso útil (`patterns.length > 0 || proposed_reminders.length > 0`).
- Response shape compatível com `HistoryInsights.fromJson`.

### Tela `lib/features/insights/insights_screen.dart`
- Acionada a partir do vehicle detail (botão "Insights" no header ou seção dedicada — escolher o que for menos invasivo).
- Estado inicial: empty state explicando + CTA "Analisar agora" (mostra cota restante).
- Loading: shimmer/spinner.
- Sucesso: 
  - Seção "Padrões detectados" (cards com cadência + confiança)
  - Seção "Lembretes sugeridos" (cards com proposta + botões Criar / Ignorar)
- `QuotaExhaustedException`: banner PT-BR "Cota mensal de análises esgotada — vire premium pra ilimitado."
- `ScanException`: snackbar "Não conseguimos analisar agora. Tente de novo em alguns minutos."
- Criar lembrete: usa `ReminderRepository` existente. Idempotência: passa pelo `dedupeProposed` antes de oferecer.

## Migration Supabase (`supabase/migrations/0003_insights_quota.sql`)
```sql
ALTER TABLE public.usage_quota
  ADD COLUMN IF NOT EXISTS analysis_count integer NOT NULL DEFAULT 0;
```

## Testes

### `test/features/insights/history_insights_test.dart` (novo)
Parse defensivo idêntico ao `scanned_expense_test`:
- JSON completo
- patterns/proposed_reminders vazios
- campos extras ignorados
- roundtrip JSON

### `test/features/insights/insights_service_test.dart` (novo)
- Invoca `analyze-history` com `vehicle_id` correto
- Retorna `HistoryInsights` parseado
- 429 → propaga `QuotaExhaustedException`
- Erro genérico → `ScanException` com mensagem PT-BR

### `test/features/insights/dedupe_test.dart` (novo)
- Lista vazia em ambos → retorna proposed inalterado
- Match exato de título + dueDate → filtra
- Match de título mas dueDate fora de ±14 dias → mantém
- Match de título + dueKm igual → filtra
- Match case-insensitive + acento-insensitive ("IPVA" === "ipva", "Revisão" === "revisao")
- `normalizeTitle("  IPVA 2026  ") == "ipva 2026"`
- Reminders deletados (`deletedAt != null`) ignorados

## Critérios de aceite
- [ ] Todos os testes verdes
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela navegável e funcional com `MockInsightsService` overrideado
- [ ] Migration 0003 e edge function `analyze-history` documentados pra deploy manual

## Não-objetivos
- Push notifications proativas (depende de notifs já configuradas — backlog).
- Análise multi-veículo numa só chamada (1 por vez no MVP).
- Insights além de despesas+abastecimentos (não considera leituras de odômetro avulsas).
- UI rica de gráficos (a Sprint 4 já cobriu reports — insights é texto + cards).
