// Widget genérico de animação de contagem (count-up).
//
// Anima de 0 até [value] usando TweenAnimationBuilder. Útil para
// métricas hero que entram na tela e "contam" até o valor real,
// dando feedback visual imediato de que os dados carregaram.

import 'package:flutter/material.dart';

/// Anima de 0 até [value] em [duration], chamando [builder] a cada tick.
///
/// Ideal para métricas financeiras (ex: total gasto do mês) onde o
/// count-up comunica "os dados chegaram" sem precisar de skeleton extra.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  /// Valor final da contagem.
  final double value;

  /// Constrói o widget a partir do valor animado corrente.
  final Widget Function(BuildContext context, double animatedValue) builder;

  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      // TweenAnimationBuilder exige 3 parâmetros no builder (inclui child).
      builder: (context, animatedValue, _) => builder(context, animatedValue),
    );
  }
}
