// Botão "Continuar com Apple" — HIG Apple Sign In.
//
// Design conforme Apple Human Interface Guidelines:
//   - Fundo preto (#000000), texto branco, ícone Apple.
//   - Largura total do parent, altura 52px.
//   - Só renderiza se [AppleSignInService.isAvailable()] == true.
//
// Referência: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple

import 'package:autolog/features/auth/apple_sign_in_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';

// ============================================================================
// Provider de disponibilidade — cacheia o Future para evitar rebuild
// ============================================================================

/// Provider que verifica se Apple Sign In está disponível neste dispositivo.
/// Computado uma vez por scope de ProviderContainer.
final appleSignInAvailableProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(appleSignInServiceProvider);
  return service.isAvailable();
});

// ============================================================================
// Botão condicional
// ============================================================================

/// Botão "Continuar com Apple" que só aparece em dispositivos que suportam
/// Apple Sign In (iOS 13+).
///
/// Em Android ou na web, retorna [SizedBox.shrink] (sem espaço).
/// Lida com estados de loading via [loading] externo para sincronizar
/// com o estado de carregamento geral da tela.
class AppleButton extends ConsumerWidget {
  const AppleButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(appleSignInAvailableProvider);

    return availableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
      data: (isAvailable) {
        if (!isAvailable) return const SizedBox.shrink();
        return _AppleButtonContent(onPressed: onPressed, loading: loading);
      },
    );
  }
}

// ============================================================================
// Conteúdo do botão (HIG Apple)
// ============================================================================

class _AppleButtonContent extends StatelessWidget {
  const _AppleButtonContent({required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // HIG: fundo preto obrigatório no light mode
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black54,
          disabledForegroundColor: Colors.white54,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone Apple — SF Symbol via Unicode (U+F8FF só iOS),
                  // fallback: ícone customizado compatível com todas as plataformas.
                  const _AppleIcon(size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Continuar com Apple',
                    style: AppTypography.body(
                      14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// Ícone Apple — CustomPaint sem dependência de assets
// ============================================================================

/// Pinta o símbolo Apple (silhueta da maçã) usando CustomPainter.
/// Não usa assets externos para manter zero dependência de arquivos de imagem.
class _AppleIcon extends StatelessWidget {
  const _AppleIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppleIconPainter(size: size)),
    );
  }
}

/// Pinta a silhueta da maçã Apple em branco.
///
/// Coordenadas baseadas no path oficial da Apple (simplificado para flutter).
/// A "folha" (leaf) fica inclinada no canto superior direito.
class _AppleIconPainter extends CustomPainter {
  const _AppleIconPainter({required this.size});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final s = size;
    final path = Path();

    // Corpo da maçã (aproximação de bezier do ícone oficial)
    // Normalizado para [0,1] depois escalado por `s`.
    //
    // Origem no topo-centro, sentido horário.
    // Referência: https://codepen.io/tagawa3/pen/MWbONyV (forma simplificada)
    final p = Path();

    // Leaf (folha no topo-direita)
    p.moveTo(s * 0.56, s * 0.04);
    p.cubicTo(
      s * 0.56,
      s * 0.04, // cp1
      s * 0.76,
      s * 0.03, // cp2
      s * 0.76,
      s * 0.24, // end
    );
    p.cubicTo(s * 0.76, s * 0.24, s * 0.57, s * 0.24, s * 0.56, s * 0.04);

    // Corpo da maçã
    path.moveTo(s * 0.50, s * 0.30);

    // Lado esquerdo (sentido horário de topo → base)
    path.cubicTo(s * 0.28, s * 0.30, s * 0.12, s * 0.48, s * 0.14, s * 0.68);
    path.cubicTo(s * 0.16, s * 0.86, s * 0.28, s * 1.00, s * 0.38, s * 0.98);
    path.cubicTo(s * 0.45, s * 0.96, s * 0.48, s * 0.92, s * 0.50, s * 0.92);

    // Lado direito (base → topo)
    path.cubicTo(s * 0.52, s * 0.92, s * 0.55, s * 0.96, s * 0.62, s * 0.98);
    path.cubicTo(s * 0.72, s * 1.00, s * 0.84, s * 0.86, s * 0.86, s * 0.68);
    path.cubicTo(s * 0.88, s * 0.48, s * 0.72, s * 0.30, s * 0.50, s * 0.30);
    path.close();

    // Entalhe do topo (indentação característica)
    final notch = Path();
    notch.moveTo(s * 0.35, s * 0.30);
    notch.cubicTo(s * 0.40, s * 0.22, s * 0.50, s * 0.20, s * 0.50, s * 0.20);
    notch.cubicTo(s * 0.50, s * 0.20, s * 0.60, s * 0.22, s * 0.65, s * 0.30);

    // Combina corpo + recorta o entalhe
    canvas.drawPath(path, paint);
    canvas.drawPath(p, paint); // folha
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
