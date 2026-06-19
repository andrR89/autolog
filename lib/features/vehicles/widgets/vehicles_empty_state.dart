// Empty state da garagem. Primeiro toque no app pra quem acabou de
// criar conta: tem que ser CONVIDATIVO, não "você não tem nada".
//
// Composição:
// - Quadrilátero off-white com hairline pontilhado evocando "vaga vazia".
// - Ícone de carro centralizado dentro, em peso leve.
// - Headline curta, calorosa ("Sua garagem está esperando").
// - Subhead com instrução prática.
// - CTA primário em accent — visualmente em quase rima com o FAB
//   da tela (mesmo verbo, mesmo destino) para reduzir hesitação.
//
// Decisão: o CTA aqui é deliberadamente REDUNDANTE com o FAB. Em
// empty state, o usuário ainda não conhece a convenção do FAB; o
// botão inline é mais óbvio.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class VehiclesEmptyState extends StatelessWidget {
  const VehiclesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Vaga de garagem" — frame com borda tracejada e ícone
              // grande centralizado. Não usamos asset pra ficar leve.
              _ParkingSpotFrame(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Sua garagem está esperando.',
                style: AppTypography.display(
                  26,
                  weight: FontWeight.w700,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Adicione seu primeiro carro pra começar a registrar '
                'abastecimentos, despesas e lembretes.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              // CTA único: FloatingActionButton "Novo veículo" no Scaffold
              // (evita 2 botões redundantes apontando pra mesma ação).
            ],
          ),
        ),
      ),
    );
  }
}

class _ParkingSpotFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: context.hairline,
        radius: AppRadius.lg,
      ),
      child: SizedBox(
        height: 140,
        child: Center(
          child: Icon(
            Icons.directions_car_filled_outlined,
            size: 64,
            color: context.ink.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// Pinta um retângulo arredondado com borda tracejada. Necessário porque
/// Flutter não tem dashed border nativo (`Border.all` é sólido).
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
