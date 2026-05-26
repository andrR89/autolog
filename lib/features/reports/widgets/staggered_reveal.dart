// Widget de entrada com fade + slide em sequência (cascading stagger).
//
// Cada filho recebe um delay incremental (delayStep × index), criando
// o efeito de "cards entrando em sequência" sem precisar de pacote externo.
//
// Uso:
//   StaggeredReveal(
//     delayStep: const Duration(milliseconds: 80),
//     children: [...],
//   )

import 'package:flutter/material.dart';

/// Revela [children] em sequência com fade + slide vertical suave.
///
/// O primeiro filho entra após [initialDelay]; cada próximo após
/// [initialDelay] + [delayStep] × index.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.children,
    this.initialDelay = const Duration(milliseconds: 80),
    this.delayStep = const Duration(milliseconds: 90),
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = 24.0,
  });

  final List<Widget> children;

  /// Delay antes do primeiro filho começar a animar.
  final Duration initialDelay;

  /// Delay adicional para cada filho subsequente.
  final Duration delayStep;

  /// Duração da animação de cada filho.
  final Duration duration;

  final Curve curve;

  /// Quanto o item desliza verticalmente antes de entrar (em pixels, positivo = desce).
  final double slideOffset;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _opacities;
  late final List<Animation<double>> _slides;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(vsync: this, duration: widget.duration),
    );

    _opacities = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: widget.curve))
        .toList();

    _slides = _controllers
        .map(
          (c) => Tween<double>(
            begin: widget.slideOffset,
            end: 0,
          ).animate(CurvedAnimation(parent: c, curve: widget.curve)),
        )
        .toList();

    // Dispara cada animação com o delay correto
    for (var i = 0; i < widget.children.length; i++) {
      final delay = widget.initialDelay + widget.delayStep * i;
      Future.delayed(delay, () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) {
              return Opacity(
                opacity: _opacities[i].value,
                child: Transform.translate(
                  offset: Offset(0, _slides[i].value),
                  child: child,
                ),
              );
            },
            child: widget.children[i],
          ),
      ],
    );
  }
}
