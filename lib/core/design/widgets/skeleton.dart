// Skeleton loading primitives — AutoLog design system.
//
// Uso:
//   - SkeletonBox({width, height, borderRadius}) — caixa com pulso.
//   - SkeletonLine({width, height}) — linha de texto com pulso (height=14 default).
//
// Animação: AnimatedOpacity ~1.2s loop infinito (0.35→1.0→0.35).
// Cor base: context.hairline (dark-aware via DynamicColors).
// Sem dependência de pub.dev extra — usa animação nativa do Flutter.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

// ============================================================================
// _SkeletonPulse — widget interno que controla a animação
// ============================================================================

class _SkeletonPulse extends StatefulWidget {
  const _SkeletonPulse({required this.child});

  final Widget child;

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

// ============================================================================
// SkeletonBox — caixa retangular com pulso
// ============================================================================

/// Caixa de skeleton com pulso. Usada para substituir cards e imagens
/// durante o carregamento.
///
/// [width] e [height] são obrigatórios.
/// [borderRadius] padrão: AppRadius.allMd.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return _SkeletonPulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.hairline,
          borderRadius: borderRadius ?? AppRadius.allMd,
        ),
      ),
    );
  }
}

// ============================================================================
// SkeletonLine — linha de texto com pulso
// ============================================================================

/// Linha de skeleton com pulso. Substitui linhas de texto durante carregamento.
///
/// [width] padrão: double.infinity (ocupa toda a largura disponível).
/// [height] padrão: 14 (altura típica de linha de texto).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 14});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _SkeletonPulse(
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: context.hairline,
          borderRadius: AppRadius.allSm,
        ),
      ),
    );
  }
}

// ============================================================================
// SkeletonFuelCard — skeleton de card de abastecimento
// ============================================================================

/// Skeleton de um FuelEntryCard. Replica a estrutura visual do card real:
/// data eyebrow · título · valor + chip.
class SkeletonFuelCard extends StatelessWidget {
  const SkeletonFuelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow date
          SkeletonLine(width: 80, height: 11),
          SizedBox(height: AppSpacing.sm),
          // Título + valor
          Row(
            children: [
              Expanded(child: SkeletonLine(height: 16)),
              SizedBox(width: AppSpacing.lg),
              SkeletonLine(width: 64, height: 16),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // Chip + odômetro
          Row(
            children: [
              SkeletonBox(
                width: 56,
                height: 22,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
              ),
              SizedBox(width: AppSpacing.sm),
              SkeletonLine(width: 80, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SkeletonInsightCard — skeleton de card de insights
// ============================================================================

/// Skeleton de um card de insight/padrão detectado.
class SkeletonInsightCard extends StatelessWidget {
  const SkeletonInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonLine(height: 16)),
              SizedBox(width: AppSpacing.lg),
              SkeletonBox(width: 48, height: 20, borderRadius: AppRadius.allSm),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(width: 120, height: 12),
          SizedBox(height: AppSpacing.xs),
          SkeletonLine(height: 12),
        ],
      ),
    );
  }
}

// ============================================================================
// SkeletonKpiCard — skeleton de card de KPI (dashboard / hero)
// ============================================================================

/// Skeleton de um card de KPI (número grande + label). Usado no dashboard/hero.
class SkeletonKpiCard extends StatelessWidget {
  const SkeletonKpiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 80, height: 12),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(width: 120, height: 28),
          SizedBox(height: AppSpacing.xs),
          SkeletonLine(width: 64, height: 12),
        ],
      ),
    );
  }
}
