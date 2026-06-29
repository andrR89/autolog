// Banner-CTA do scan — a "tese central" do produto em forma de widget.
//
// "Tire uma foto. O app preenche o resto." vive aqui. Não é um IconButton
// discreto na AppBar — é um convite visível, em lima cítrica (o acento de
// "vai" do DS), posicionado bem no topo do formulário.
//
// Tem dois modos:
//   1. idle    → lima accent, ícone câmera, texto convidativo, seta ">"
//                "Escanear cupom" / "preenche tudo automaticamente"
//   2. scanning→ mesma silhueta, mas com texto "Lendo o cupom..." e três
//                pontinhos animados (heartbeat). Não fica oculto — o usuário
//                vê o trabalho acontecendo.
//
// Por que lima e não branco/brand: o DS reserva accent para FAB + scan CTA.
// Aqui é o lugar canônico. Aparecer em mais de 2 elementos na mesma tela
// quebra a regra — então a AppBar fica neutra, FAB não existe nesta tela,
// e o banner é a única voz lima. Coerente.

import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

class ScanCtaBanner extends StatelessWidget {
  const ScanCtaBanner({super.key, required this.onTap, required this.scanning});

  final VoidCallback onTap;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Material(
        color: AppColors.accent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: scanning ? null : onTap,
          splashColor: AppColors.brand.withValues(alpha: 0.08),
          highlightColor: AppColors.brand.withValues(alpha: 0.04),
          child: AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.standardCurve,
            switchOutCurve: AppMotion.standardCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: scanning
                ? const _ScanningContent(key: ValueKey('scanning'))
                : const _IdleContent(key: ValueKey('idle')),
          ),
        ),
      ),
    );
  }
}

// -------------------- Idle --------------------

class _IdleContent extends StatelessWidget {
  const _IdleContent({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 2,
        AppSpacing.md,
        AppSpacing.md + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quadrado-ícone "papel" para variar do icon-redondo padrão.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Escanear cupom',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.accentInk,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'tire uma foto, o app preenche o resto',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.accentInk.withValues(alpha: 0.7),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.accentInk,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Scanning --------------------

class _ScanningContent extends StatefulWidget {
  const _ScanningContent({super.key});

  @override
  State<_ScanningContent> createState() => _ScanningContentState();
}

class _ScanningContentState extends State<_ScanningContent>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // Sweep luminoso — uma "lâmina" branca translúcida atravessando o
        // banner da esquerda pra direita. Microanimação que comunica
        // "trabalhando" sem precisar de spinner Material.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: AppRadius.allMd,
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    final t = _sweep.value;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [
                        (t - 0.25).clamp(0.0, 1.0),
                        t.clamp(0.0, 1.0),
                        (t + 0.25).clamp(0.0, 1.0),
                      ],
                      // shimmer sobre accent lima — branco translúcido intencional;
                      // não existe token DS para "branco sobre lima", accentInk
                      // é escuro e quebraria o efeito visual.
                      colors: const [
                        Color(0x00FFFFFF),
                        Color(0x66FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ).createShader(rect);
                  },
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md + 2,
            AppSpacing.lg,
            AppSpacing.md + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "Olho que lê" — ícone com pulse sutil.
              FadeTransition(
                opacity: Tween<double>(begin: 0.55, end: 1.0).animate(_pulse),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Lendo o cupom',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.accentInk,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        _AnimatedDots(controller: _pulse),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Claude está olhando seu cupom agora',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.accentInk.withValues(alpha: 0.7),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        // 0.0 → " "    0.33 → "."    0.66 → ".."    1.0 → "..."
        final dots = '.' * ((t * 4).floor().clamp(0, 3));
        return Text(
          dots,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.accentInk,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        );
      },
    );
  }
}
