// Scaffold compartilhado para telas de autenticação.
//
// Layout de duas faixas:
//  - Faixa superior (brand escuro): hero com logo + tagline. Ocupa ~38% da tela.
//  - Faixa inferior (surface off-white): formulário + botões + link de toggle.
//
// Animação de entrada:
//  - Hero: fade + slide de cima para baixo (emphasizedCurve, 400ms).
//  - Formulário: fade + slide de baixo para cima (emphasizedCurve, 400ms, delay 80ms).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_logo.dart';

/// Scaffold base para login e signup — duas faixas com animação de entrada.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.formContent,
  });

  /// Título da tela abaixo do logo (ex: "Entre na sua conta").
  final String title;

  /// Conteúdo do formulário (inputs, botões, links). Montado pelo screen.
  final List<Widget> formContent;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Hero desce de cima
    _heroFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: AppMotion.emphasizedCurve),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, -0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.7, curve: AppMotion.emphasizedCurve),
          ),
        );

    // Form sobe de baixo (delay leve)
    _formFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 1.0, curve: AppMotion.emphasizedCurve),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.15, 1.0, curve: AppMotion.emphasizedCurve),
          ),
        );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    // Faixa brand: mínimo 200px, máximo 38% da tela
    final heroH = (screenH * 0.38).clamp(200.0, 320.0);

    // AnnotatedRegion garante ícones claros na status bar sobre o hero brand.
    // Não tem AppBar aqui, então não podemos usar systemOverlayStyle nela.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // ----------------------------------------------------------------
            // Faixa brand (topo escuro) — hero logo + tagline
            // ----------------------------------------------------------------
            FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: _HeroSection(height: heroH),
              ),
            ),

            // ----------------------------------------------------------------
            // Faixa form (bottom off-white) — conteúdo do formulário
            // ----------------------------------------------------------------
            Expanded(
              child: FadeTransition(
                opacity: _formFade,
                child: SlideTransition(
                  position: _formSlide,
                  child: _FormSection(
                    title: widget.title,
                    children: widget.formContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seção hero (faixa brand escuro)
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Stack(
        children: [
          // Pattern sutil de pontos — referência visual a recibo de combustível
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg),
              ),
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),

          // Conteúdo central: logo + tagline
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 34, logoTheme: AppLogoTheme.light),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tire uma foto.\nO app preenche o resto.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.brandInk.withValues(alpha: 0.70),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter: grid de pontos suave sobre o fundo brand
// ---------------------------------------------------------------------------

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandInk.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const radius = 1.2;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Seção form (faixa off-white)
// ---------------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        top: AppSpacing.xxl,
        bottom: AppSpacing.xxl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título da tela
          Text(
            title,
            style: AppTypography.display(
              22,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ...children,
        ],
      ),
    );
  }
}
