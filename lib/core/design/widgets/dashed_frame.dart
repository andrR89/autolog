// Moldura tracejada usada em empty states do app (Garagem, Despesas,
// Lembretes, Histórico de abastecimento).
//
// Antes existiam 4 cópias quase idênticas — esta é a fonte única. Mantém o
// tom "vaga vazia / placeholder convidativo".

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

/// Moldura tracejada com ícone centralizado, padrão de empty state.
///
/// Largura = pai (geralmente um Column stretch dentro de ConstrainedBox 360).
/// Altura padrão = 130 (espelha o que as 4 cópias usavam).
class DashedFrame extends StatelessWidget {
  const DashedFrame({
    super.key,
    required this.icon,
    this.height = 130,
    this.iconSize = 56,
    this.iconAlpha = 0.30,
  });

  final IconData icon;
  final double height;
  final double iconSize;
  final double iconAlpha;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRoundedRectPainter(
        color: context.hairline,
        radius: AppRadius.lg,
      ),
      child: SizedBox(
        height: height,
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: context.ink.withValues(alpha: iconAlpha),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter exposto pra casos especiais (ex.: forma custom dentro do
/// frame). Quem só precisa de ícone usa [DashedFrame].
class DashedRoundedRectPainter extends CustomPainter {
  DashedRoundedRectPainter({required this.color, required this.radius});

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
  bool shouldRepaint(covariant DashedRoundedRectPainter old) =>
      old.color != color || old.radius != radius;
}
