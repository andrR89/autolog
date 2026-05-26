# Sprint 6.N — Lembretes automáticos IPVA / licenciamento por UF

> Onda 2, sprint 2/10. **Sem IA**, sem edge function, sem cota.
> Tabela hardcoded de calendário fiscal BR + função pura + UI.

## Decisões pragmáticas
- **Tabela hardcoded** de calendário fiscal por UF e por final de placa. Cobre 27 UFs com aproximação. Fonte: melhor estimativa baseada em calendários típicos 2024-2026.
- **Disclaimer PT-BR explícito** na UI: "Confira a data com seu Detran" — o app sugere, não substitui.
- **Sem cota** — função pura, zero rede.
- Dedupe via `dedupeProposed` (6.G).
- Acessível a partir da `InsightsScreen` (3º botão).

## Tabela de calendário (`lib/features/insights/fiscal_calendar.dart`)

```dart
/// Mês típico (1-12) do vencimento conforme final da placa.
/// Quando a UF não distingue por placa, todos os finais apontam pro mesmo mês.
class FiscalScheduleByDigit {
  const FiscalScheduleByDigit(this.monthByLastDigit);
  /// Map de último dígito da placa (0-9) → mês 1-12.
  final Map<int, int> monthByLastDigit;

  /// Retorna o mês pro dígito; se não tem, usa fallback (mês mais comum).
  int monthFor(int? lastDigit) { ... }
}

class UfFiscalCalendar {
  const UfFiscalCalendar({required this.ipva, required this.licensing});
  final FiscalScheduleByDigit ipva;
  final FiscalScheduleByDigit licensing;
}

/// Tabela canônica. Estados ausentes usam [_defaultCalendar].
const Map<String, UfFiscalCalendar> brFiscalCalendar = { ... };
const UfFiscalCalendar _defaultCalendar = UfFiscalCalendar(
  ipva: FiscalScheduleByDigit({0:1,1:1,2:2,3:2,4:3,5:3,6:4,7:4,8:5,9:5}),
  licensing: FiscalScheduleByDigit({0:6,1:6,2:7,3:7,4:8,5:8,6:9,7:9,8:10,9:10}),
);
```

UFs com calendário específico (best-effort, valores típicos 2024-2026 — disclaimer no UI):
- **SP**: IPVA jan/fev/mar/abr/mai por final 1-2/3-4/5-6/7-8/9-0. Licenciamento jun-out.
- **RJ**: IPVA jan-mar dist. por final. Licenciamento abr-set.
- **MG**: IPVA mar-mai dist. por final. Licenciamento ago-nov.
- **PR**: IPVA mai (cota única). Licenciamento ago-dez.
- **RS**: IPVA fev-abr dist. por final. Licenciamento ago-nov.
- **SC**: IPVA fev. Licenciamento jul-nov dist.
- Demais 21 UFs: default acima.

## Função pura (`lib/features/insights/fiscal_calendar.dart`)

```dart
/// Extrai o último dígito da placa (Mercosul ou antigo). Null se inválida.
int? lastDigitOfPlate(String? plate);

/// Constrói lembretes propostos pra um veículo, ano fiscal corrente.
/// Não consulta dados externos. Pura.
List<ProposedReminder> suggestFiscalReminders({
  required String? uf,
  required String? plate,
  required int year, // ano fiscal: tipicamente DateTime.now().year ou next year
});
```

Output:
- 1 `ProposedReminder` IPVA com `title: "IPVA $year"`, `dueDate: DateTime(year, mes, 1)`, `rationale: "Calendário típico {UF}, confira no Detran."`.
- 1 `ProposedReminder` Licenciamento com `title: "Licenciamento $year"`, `dueDate: ...`, `rationale: ...`.
- Lista vazia se `uf == null` ou desconhecida e não há mesmo o default? — Não. UF nula usa default; lista volta com 2 propostas sempre. Único motivo pra lista vazia é se `year` for inválido.

## UI

### Tela `lib/features/insights/fiscal_plan_screen.dart`
Igual ao MaintenancePlanScreen mas:
- Carrega vehicle.
- Computa propostas via `suggestFiscalReminders(uf, plate, DateTime.now().year)`.
- Aplica `dedupeProposed` contra reminders ativos.
- Renderiza 2 cards (IPVA + Licenciamento) com botões Criar/Ignorar.
- Banner topo (info, cinza): "ℹ️ Datas baseadas em calendário típico. **Confira com seu Detran** — datas variam por ano e por dígito da placa."
- FAB "Criar todos restantes" (cria 1 ou 2).

### Botão na InsightsScreen
Adicionar 3ª seção: "FISCAL" com card "Lembretes IPVA + Licenciamento" → navega pra `/vehicles/:id/insights/fiscal`.

### Rota
`lib/core/router.dart`: rota nova `/vehicles/:vehicleId/insights/fiscal`.

## Testes

### `test/features/insights/fiscal_calendar_test.dart` (novo)

- `lastDigitOfPlate("ABC1234")` → 4; `lastDigitOfPlate("ABC1D23")` → 3 (Mercosul); inválido → null; null → null.
- `brFiscalCalendar['SP']` existe e tem IPVA por dígito conforme spec.
- `suggestFiscalReminders(uf:'SP', plate:'ABC1234', year:2026)` retorna 2 itens com dueDate certo (final 4 → mar?).
- `suggestFiscalReminders(uf:null, plate:null, year:2026)` retorna 2 itens com fallback default.
- `suggestFiscalReminders(uf:'ZZ', plate:'ABC1234', year:2026)` (UF inexistente) → usa default, retorna 2 itens.
- `suggestFiscalReminders(uf:'SP', plate:null, year:2026)` → usa mês "médio" (não joga erro, usa fallback do FiscalScheduleByDigit).
- Title formato: "IPVA 2026" / "Licenciamento 2026".
- DueDate formato: `DateTime.utc(2026, mes, 1)`.

## Critérios de aceite
- [ ] Todos testes verdes (530+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela fiscal navegável e funcional
- [ ] Disclaimer visível "Confira com seu Detran"
- [ ] Dedupe aplicado

## Não-objetivos
- Integração com Detran de qualquer estado (rejeitado anteriormente — APIs flaky).
- Cálculo de valor estimado IPVA por modelo (depende de FIPE + alíquota — futuro).
- Multas (sprint 6.O).
- Calendário 100% preciso por ano (precisaria atualização periódica — disclaimer cobre).
