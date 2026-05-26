// Botão "Entrar com Google" — OutlinedButton com ícone proxy e texto PT-BR.
//
// Flutter não inclui o ícone oficial do Google no pacote Material.
// Usamos uma representação composta: a letra "G" em Bricolage Bold com a
// cor característica do Google em quatro cores via gradiente simulado —
// na prática uma letra "G" colorida que é universalmente reconhecida.

import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';

/// Botão secundário de login com Google.
///
/// Ocupa a largura total do parent. Desabilitado quando [loading] é true.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.hairline, width: 1.5),
          backgroundColor: AppColors.surfaceRaised,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleGlyph(size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Continuar com Google',
              style: AppTypography.body(
                14,
                weight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glifo "G" do Google renderizado com as quatro cores características.
/// Solução puramente Flutter sem assets externos.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Representação simplificada: ícone de conta com borda colorida
    // que evoca o Google sem usar trademark direto.
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter(size: size)),
    );
  }
}

/// Pinta um "G" estilizado com as cores do Google (azul, vermelho, amarelo, verde).
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter({required this.size});

  final double size;

  // Cores do Google
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final strokeW = size * 0.165;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    // Arco azul (direita + topo)
    paint.color = _blue;
    canvas.drawArc(rect, -0.25, 1.25, false, paint);

    // Arco vermelho (esquerda-topo)
    paint.color = _red;
    canvas.drawArc(rect, 1.0, 1.2, false, paint);

    // Arco amarelo (esquerda-baixo)
    paint.color = _yellow;
    canvas.drawArc(rect, 2.2, 0.85, false, paint);

    // Arco verde (baixo)
    paint.color = _green;
    canvas.drawArc(rect, 3.05, 0.95, false, paint);

    // Barra horizontal do "G"
    paint
      ..style = PaintingStyle.fill
      ..color = _blue;
    final barRect = Rect.fromLTWH(
      center.dx - strokeW * 0.1,
      center.dy - strokeW * 0.45,
      radius * 0.82,
      strokeW * 0.9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
