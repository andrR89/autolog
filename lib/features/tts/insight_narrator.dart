// insight_narrator.dart — Converte dados de insights e recap em texto PT-BR
// para leitura via TTS.
//
// Funções puras, sem side-effects.

import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/recap/recap_data.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// narrateInsights
// ---------------------------------------------------------------------------

/// Gera texto contínuo em PT-BR descrevendo os padrões detectados e os
/// lembretes propostos de um [HistoryInsights].
///
/// Quando vazio, retorna "Sem insights ainda."
String narrateInsights(HistoryInsights r) {
  final buffer = StringBuffer();

  if (r.patterns.isEmpty && r.proposedReminders.isEmpty) {
    return 'Sem insights ainda.';
  }

  if (r.patterns.isNotEmpty) {
    if (r.patterns.length == 1) {
      buffer.write('Foi detectado um padrão no seu histórico. ');
    } else {
      buffer.write(
        'Foram detectados ${r.patterns.length} padrões no seu histórico. ',
      );
    }
    for (final p in r.patterns) {
      final cadenceLabel = switch (p.cadence) {
        'yearly' => 'anual',
        'monthly' => 'mensal',
        _ => p.cadence,
      };
      buffer.write('Padrão ${p.category}, cadência $cadenceLabel. ');
      if (p.rationale != null && p.rationale!.isNotEmpty) {
        buffer.write('${p.rationale} ');
      }
    }
  }

  if (r.proposedReminders.isNotEmpty) {
    if (r.proposedReminders.length == 1) {
      buffer.write('Há um lembrete sugerido. ');
    } else {
      buffer.write(
        'Há ${r.proposedReminders.length} lembretes sugeridos. ',
      );
    }
    for (final rem in r.proposedReminders) {
      buffer.write('Lembrete: ${rem.title}. ');
      if (rem.rationale.isNotEmpty) {
        buffer.write('${rem.rationale} ');
      }
    }
  }

  return buffer.toString().trim();
}

// ---------------------------------------------------------------------------
// narrateRecapSlide
// ---------------------------------------------------------------------------

/// Gera uma frase descritiva para o slide de índice [index] do [RecapData].
///
/// Índices esperados (mesma ordem de _buildSlides no recap_screen.dart):
/// - 0: hero
/// - 1: total gasto
/// - 2: km rodados
/// - 3: consumo médio (se disponível) ou consumo vazio
/// - 4+: preços, posto favorito, categoria top
String narrateRecapSlide(int index, RecapData r) {
  final periodLabel =
      r.period == RecapPeriod.week ? 'da semana' : 'do mês';

  switch (index) {
    case 0:
      // Hero
      final fmt = DateFormat('MMMM', 'pt_BR');
      if (r.period == RecapPeriod.month) {
        return 'Seu mês em movimento. ${fmt.format(r.start)}.';
      }
      return 'Sua semana em movimento.';

    case 1:
      // Total gasto
      final fmtCurrency = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: r'R$',
        decimalDigits: 2,
      );
      return 'Você gastou ${fmtCurrency.format(r.totalSpent.toDouble())} $periodLabel, '
          'em ${r.fuelEntriesCount} abastecimento${r.fuelEntriesCount != 1 ? 's' : ''} '
          'e ${r.expensesCount} despesa${r.expensesCount != 1 ? 's' : ''}.';

    case 2:
      // Km rodados
      if (r.kmDriven == 0) {
        return 'Não foi possível calcular os quilômetros rodados $periodLabel.';
      }
      return 'Você rodou ${r.kmDriven} quilômetros $periodLabel.';

    case 3:
      // Consumo médio
      if (r.avgConsumptionKmL != null) {
        final fmtNum = NumberFormat('0.0', 'pt_BR');
        return 'Seu consumo médio foi de ${fmtNum.format(r.avgConsumptionKmL!.toDouble())} quilômetros por litro.';
      }
      return 'Abasteça mais uma vez para calcular o consumo do período.';

    case 4:
      // Preços ou posto favorito
      if (r.cheapestPricePerLiter != null &&
          r.mostExpensivePricePerLiter != null) {
        final fmt = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: r'R$',
          decimalDigits: 2,
        );
        return 'O litro mais barato foi ${fmt.format(r.cheapestPricePerLiter!.toDouble())} '
            'e o mais caro foi ${fmt.format(r.mostExpensivePricePerLiter!.toDouble())}.';
      }
      if (r.favoriteStation != null) {
        return 'Seu posto favorito foi ${r.favoriteStation}.';
      }
      return 'Não há dados de preços para narrar.';

    case 5:
      // Posto favorito ou categoria top
      if (r.favoriteStation != null) {
        return 'Seu posto favorito foi ${r.favoriteStation}.';
      }
      if (r.topExpenseCategory != null) {
        return 'Você gastou mais com ${r.topExpenseCategory}.';
      }
      return 'Confira os detalhes na tela.';

    case 6:
      // Categoria top
      if (r.topExpenseCategory != null) {
        return 'Você gastou mais com ${r.topExpenseCategory}.';
      }
      return 'Confira os detalhes na tela.';

    default:
      return 'Confira os detalhes na tela.';
  }
}

// ---------------------------------------------------------------------------
// narrateFiscal
// ---------------------------------------------------------------------------

/// Gera frase descritiva para a lista de [proposals] do plano fiscal.
///
/// Quando vazia, retorna mensagem padrão.
String narrateFiscal(List<ProposedReminder> proposals) {
  if (proposals.isEmpty) {
    return 'Sem lembretes fiscais pendentes.';
  }

  final buffer = StringBuffer();

  if (proposals.length == 1) {
    buffer.write('Há um lembrete fiscal pendente. ');
  } else {
    buffer.write('Há ${proposals.length} lembretes fiscais pendentes. ');
  }

  for (final p in proposals) {
    buffer.write('${p.title}. ');
    if (p.dueDate != null) {
      final fmt = DateFormat('d \'de\' MMMM \'de\' y', 'pt_BR');
      buffer.write('Vence em ${fmt.format(p.dueDate!)}. ');
    }
  }

  return buffer.toString().trim();
}
