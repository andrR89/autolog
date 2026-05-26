// Calendário fiscal BR hardcoded (IPVA + Licenciamento) por UF e final de placa.
//
// Fonte: calendários típicos 2024-2026 por UF.
// Disclaimer obrigatório na UI: "Confira com seu Detran — datas variam por ano."
//
// Regras de Ouro respeitadas:
// - Sem rede, sem edge function, sem cota — função pura cliente.
// - Scan não interfere — fluxo manual sempre disponível.

import 'package:autolog/features/insights/history_insights.dart';

// ---------------------------------------------------------------------------
// Modelos de calendário
// ---------------------------------------------------------------------------

/// Mês típico (1-12) do vencimento conforme final da placa.
///
/// Quando a UF não distingue por placa, todos os finais apontam pro mesmo mês.
class FiscalScheduleByDigit {
  const FiscalScheduleByDigit(this.monthByLastDigit);

  /// Map de último dígito da placa (0-9) → mês 1-12.
  final Map<int, int> monthByLastDigit;

  /// Retorna o mês pro dígito; se não tem entrada, usa fallback (mês mais frequente).
  int monthFor(int? lastDigit) {
    if (lastDigit != null && monthByLastDigit.containsKey(lastDigit)) {
      return monthByLastDigit[lastDigit]!;
    }
    // Fallback: mês mais comum no map. Se vazio, retorna 1.
    if (monthByLastDigit.isEmpty) return 1;
    final freq = <int, int>{};
    for (final m in monthByLastDigit.values) {
      freq[m] = (freq[m] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class UfFiscalCalendar {
  const UfFiscalCalendar({required this.ipva, required this.licensing});

  final FiscalScheduleByDigit ipva;
  final FiscalScheduleByDigit licensing;
}

// ---------------------------------------------------------------------------
// Tabela canônica por UF
// ---------------------------------------------------------------------------

/// Tabela de calendário fiscal por UF. Estados ausentes usam [_defaultCalendar].
///
/// SP: IPVA jan-mai por final 1-2/3-4/5-6/7-8/9-0. Licenciamento jun-out.
/// RJ: IPVA jan-mar dist. por final. Licenciamento abr-set.
/// MG: IPVA mar-mai dist. por final. Licenciamento ago-nov.
/// PR: IPVA mai (cota única). Licenciamento ago-dez.
/// RS: IPVA fev-abr dist. por final. Licenciamento ago-nov.
/// SC: IPVA fev. Licenciamento jul-nov dist.
const Map<String, UfFiscalCalendar> brFiscalCalendar = {
  'SP': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      1: 1,
      2: 1,
      3: 2,
      4: 2,
      5: 3,
      6: 3,
      7: 4,
      8: 4,
      9: 5,
      0: 5,
    }),
    licensing: FiscalScheduleByDigit({
      1: 6,
      2: 6,
      3: 7,
      4: 7,
      5: 8,
      6: 8,
      7: 9,
      8: 9,
      9: 10,
      0: 10,
    }),
  ),
  'RJ': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      1: 1,
      2: 1,
      3: 1,
      4: 2,
      5: 2,
      6: 2,
      7: 3,
      8: 3,
      9: 3,
      0: 3,
    }),
    licensing: FiscalScheduleByDigit({
      1: 4,
      2: 4,
      3: 5,
      4: 5,
      5: 6,
      6: 6,
      7: 7,
      8: 7,
      9: 8,
      0: 9,
    }),
  ),
  'MG': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      1: 3,
      2: 3,
      3: 3,
      4: 4,
      5: 4,
      6: 4,
      7: 5,
      8: 5,
      9: 5,
      0: 5,
    }),
    licensing: FiscalScheduleByDigit({
      1: 8,
      2: 8,
      3: 9,
      4: 9,
      5: 9,
      6: 10,
      7: 10,
      8: 11,
      9: 11,
      0: 11,
    }),
  ),
  'PR': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      0: 5,
      1: 5,
      2: 5,
      3: 5,
      4: 5,
      5: 5,
      6: 5,
      7: 5,
      8: 5,
      9: 5,
    }),
    licensing: FiscalScheduleByDigit({
      1: 8,
      2: 8,
      3: 9,
      4: 9,
      5: 10,
      6: 10,
      7: 11,
      8: 11,
      9: 12,
      0: 12,
    }),
  ),
  'RS': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      1: 2,
      2: 2,
      3: 2,
      4: 3,
      5: 3,
      6: 3,
      7: 4,
      8: 4,
      9: 4,
      0: 4,
    }),
    licensing: FiscalScheduleByDigit({
      1: 8,
      2: 8,
      3: 9,
      4: 9,
      5: 9,
      6: 10,
      7: 10,
      8: 11,
      9: 11,
      0: 11,
    }),
  ),
  'SC': UfFiscalCalendar(
    ipva: FiscalScheduleByDigit({
      0: 2,
      1: 2,
      2: 2,
      3: 2,
      4: 2,
      5: 2,
      6: 2,
      7: 2,
      8: 2,
      9: 2,
    }),
    licensing: FiscalScheduleByDigit({
      1: 7,
      2: 7,
      3: 8,
      4: 8,
      5: 9,
      6: 9,
      7: 10,
      8: 10,
      9: 11,
      0: 11,
    }),
  ),
};

const UfFiscalCalendar _defaultCalendar = UfFiscalCalendar(
  ipva: FiscalScheduleByDigit({
    0: 1,
    1: 1,
    2: 2,
    3: 2,
    4: 3,
    5: 3,
    6: 4,
    7: 4,
    8: 5,
    9: 5,
  }),
  licensing: FiscalScheduleByDigit({
    0: 6,
    1: 6,
    2: 7,
    3: 7,
    4: 8,
    5: 8,
    6: 9,
    7: 9,
    8: 10,
    9: 10,
  }),
);

// ---------------------------------------------------------------------------
// Funções puras
// ---------------------------------------------------------------------------

/// Extrai o último dígito numérico da placa (Mercosul "ABC1D23" ou antiga "ABC1234").
///
/// Remove espaços e hífens antes de checar o último caractere.
/// Retorna null se a placa for nula, vazia ou o último char não for dígito.
int? lastDigitOfPlate(String? plate) {
  if (plate == null) return null;
  final cleaned = plate.replaceAll(RegExp(r'[\s\-]'), '').trim();
  if (cleaned.isEmpty) return null;
  final last = cleaned[cleaned.length - 1];
  return int.tryParse(last); // null se não-numérico
}

/// Constrói lembretes propostos pra um veículo, para o ano fiscal informado.
///
/// Sem consultas externas — função pura.
///
/// Retorna sempre 2 propostas: IPVA + Licenciamento.
/// UF nula ou desconhecida usa o calendário default.
List<ProposedReminder> suggestFiscalReminders({
  required String? uf,
  required String? plate,
  required int year,
}) {
  final ufUpper = uf?.toUpperCase();
  final calendar = (ufUpper != null && brFiscalCalendar.containsKey(ufUpper))
      ? brFiscalCalendar[ufUpper]!
      : _defaultCalendar;

  final digit = lastDigitOfPlate(plate);
  final ipvaMonth = calendar.ipva.monthFor(digit);
  final licMonth = calendar.licensing.monthFor(digit);

  // Se a UF veio mas não está no mapa, evita exibir um código inválido literal
  // ("Calendário típico ZZ — ...") no texto exibido ao usuário.
  final ufKnown = ufUpper != null && brFiscalCalendar.containsKey(ufUpper);
  final rationale = ufKnown
      ? 'Calendário típico $ufUpper — confira no Detran.'
      : 'Calendário típico — confira no Detran do seu estado.';

  return [
    ProposedReminder(
      title: 'IPVA $year',
      dueDate: DateTime.utc(year, ipvaMonth, 1),
      rationale: rationale,
    ),
    ProposedReminder(
      title: 'Licenciamento $year',
      dueDate: DateTime.utc(year, licMonth, 1),
      rationale: rationale,
    ),
  ];
}
