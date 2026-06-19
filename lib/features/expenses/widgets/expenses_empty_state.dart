// Empty state da lista de despesas.
//
// Convidativo, não vazio — mesmo tom de VehiclesEmptyState.
// Usa um frame tracejado com ícone de recibo, headline calorosa e CTA inline.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class ExpensesEmptyState extends StatelessWidget {
  const ExpensesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Scroll + Center: fica centralizado quando cabe; scrollável quando o
    // conteúdo é maior que o viewport (telas curtas, banner empurrando, etc).
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReceiptFrame(),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Sem despesas registradas ainda.',
                  style: AppTypography.display(
                    26,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Toque em "Nova despesa" pra começar a controlar os gastos do seu carro.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                // CTA único: FAB "Nova despesa" do Scaffold.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: context.hairline,
        radius: AppRadius.lg,
      ),
      child: SizedBox(
        height: 130,
        child: Center(
          child: Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: context.ink.withValues(alpha: 0.30),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;
  static const double _dashWidth = 6;
  static const double _dashSpace = 5;
  static const double _strokeWidth = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter old) =>
      old.color != color || old.radius != radius;
}
