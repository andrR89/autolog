// Hero metric para relatórios — exibe gasto do mês corrente em destaque,
// com count-up animado e comparação com o mês anterior (delta percentual).
//
// Anatomia:
//
//   ┌───────────────────────────────────────────────────────────┐
//   │  ▓ Painel verde-meia-noite (brand)                          │
//   │                                                             │
//   │    GASTO EM MAI/2026              ↗ Relatórios              │
//   │    R$ 1.234,56                                              │
//   │    –12% vs abr                                              │
//   │                                                             │
//   └───────────────────────────────────────────────────────────┘
//
// Sem dados do mês → mostra "—" sem animação de count-up.
// Sem dados do mês anterior → omite linha de delta.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/features/reports/monthly_spending.dart';
import 'package:autolog/features/reports/widgets/animated_counter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyHeroMetric extends StatelessWidget {
  const MonthlyHeroMetric({
    super.key,
    required this.vehicleNickname,
    required this.monthlyData,
  });

  final String vehicleNickname;
  final List<MonthlyTotal> monthlyData;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonthBucket = DateTime.utc(now.year, now.month, 1);
    final prevMonthBucket = DateTime.utc(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      1,
    );

    MonthlyTotal? thisMonth;
    MonthlyTotal? prevMonth;

    for (final d in monthlyData) {
      if (d.month == thisMonthBucket) thisMonth = d;
      if (d.month == prevMonthBucket) prevMonth = d;
    }

    final monthLabel = _monthLabel(now);

    return Container(
      width: double.infinity,
      color: AppColors.brand,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow — veículo + período
          Text(
            vehicleNickname.toUpperCase(),
            style: AppTypography.body(
              11,
              weight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.brandInk.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gasto em $monthLabel',
            style: AppTypography.body(
              13,
              weight: FontWeight.w500,
              color: AppColors.brandInk.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Hero: count-up do gasto mensal
          if (thisMonth != null)
            _AnimatedSpend(total: thisMonth.total)
          else
            Text(
              '—',
              style: AppTypography.metric(
                52,
                weight: FontWeight.w700,
                color: AppColors.brandInk.withValues(alpha: 0.4),
              ),
            ),

          // Delta vs mês anterior
          if (thisMonth != null && prevMonth != null)
            _DeltaBadge(current: thisMonth.total, previous: prevMonth.total),
          if (thisMonth == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Cadastre abastecimentos e despesas pra ver o gasto aqui.',
                style: AppTypography.body(
                  12,
                  color: AppColors.brandInk.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime dt) {
    const names = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${names[dt.month - 1]}/${dt.year}';
  }
}

/// Exibe R$ com animação de count-up.
class _AnimatedSpend extends StatelessWidget {
  const _AnimatedSpend({required this.total});

  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final totalDouble = total.toDouble();
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    return AnimatedCounter(
      value: totalDouble,
      duration: const Duration(milliseconds: 1000),
      builder: (context, value) {
        return Text(
          fmt.format(value),
          style: AppTypography.metric(
            46,
            weight: FontWeight.w700,
            color: AppColors.brandInk,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Badge de delta percentual vs mês anterior.
class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.current, required this.previous});

  final Decimal current;
  final Decimal previous;

  @override
  Widget build(BuildContext context) {
    if (previous == Decimal.zero) return const SizedBox.shrink();

    final prevDouble = previous.toDouble();
    final currDouble = current.toDouble();
    final delta = ((currDouble - prevDouble) / prevDouble) * 100;
    final isPositive = delta > 0;
    final isNeutral = delta.abs() < 0.5;

    final sign = isNeutral ? '' : (isPositive ? '+' : '');
    final label = '$sign${delta.toStringAsFixed(1)}% vs ${_prevMonthName()}';

    // Verde se gastou menos (delta negativo), vermelho se gastou mais
    final color = isNeutral
        ? AppColors.brandInk.withValues(alpha: 0.55)
        : isPositive
        ? AppColors.danger.withValues(alpha: 0.85)
        : AppColors.accent.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.body(13, weight: FontWeight.w600, color: color),
      ),
    );
  }

  String _prevMonthName() {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    const names = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return names[prevMonth - 1];
  }
}
