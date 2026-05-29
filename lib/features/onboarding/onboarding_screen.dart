import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Dados dos slides
// ---------------------------------------------------------------------------

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.secondaryIcon,
  });

  final IconData icon;
  final IconData? secondaryIcon;
  final String title;
  final String subtitle;
}

const _slides = [
  _SlideData(
    icon: Icons.directions_car_rounded,
    title: 'Bem-vindo ao AutoLog',
    subtitle:
        'Acompanhe consumo, custos e lembretes do seu carro.\nTudo offline.',
  ),
  _SlideData(
    icon: Icons.local_gas_station_rounded,
    secondaryIcon: Icons.edit_note_rounded,
    title: 'Registre rápido',
    subtitle:
        'Cada abastecimento em 10 segundos.\nManual ou foto do cupom.',
  ),
  _SlideData(
    icon: Icons.insights_rounded,
    title: 'Veja o que importa',
    subtitle:
        'Consumo real, gasto por km, padrões —\natualizados a cada abastecimento.',
  ),
  _SlideData(
    icon: Icons.notifications_active_rounded,
    title: 'Nunca esqueça',
    subtitle:
        'IPVA, licenciamento, troca de óleo.\nLembretes automáticos.',
  ),
];

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _completing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markDoneAndNavigate() async {
    if (_completing) return;
    setState(() => _completing = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(userSettingsRepositoryProvider);
      await repo.setOnboardingSeen(userId);
    } catch (_) {
      // Em caso de falha (ex.: sem sessão), navega mesmo assim.
      // O flag será marcado na próxima tentativa.
    }

    if (mounted) context.go('/home');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _markDoneAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: context.surface,
      // Botão "Pular" no topo direito — discreto
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!isLast)
            TextButton(
              onPressed: _markDoneAndNavigate,
              child: Text(
                'Pular',
                style: AppTypography.body(
                  14,
                  weight: FontWeight.w500,
                  color: context.inkMuted,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // PageView com os slides
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _slides.length,
              itemBuilder: (context, index) =>
                  _OnboardingSlide(data: _slides[index]),
            ),
          ),

          // Área inferior: dots + botão CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              children: [
                // Indicador de dots
                _DotsIndicator(
                  count: _slides.length,
                  current: _currentPage,
                ),
                const SizedBox(height: 32),

                // CTA bottom-right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: _completing ? null : _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentInk,
                        minimumSize: const Size(140, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _completing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.accentInk,
                                ),
                              ),
                            )
                          : Text(
                              isLast ? 'Começar' : 'Próximo',
                              style: AppTypography.body(
                                16,
                                weight: FontWeight.w700,
                                color: AppColors.accentInk,
                              ),
                            ),
                    ),
                  ],
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
// Slide individual
// ---------------------------------------------------------------------------

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone(s) hero
          _HeroIcons(data: data),
          const SizedBox(height: 40),

          // Título
          Text(
            data.title,
            style: AppTypography.display(
              30,
              weight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Subtítulo
          Text(
            data.subtitle,
            style: AppTypography.body(
              17,
              weight: FontWeight.w400,
              height: 1.55,
              color: context.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ícones hero (suporte a 1 ou 2 ícones)
// ---------------------------------------------------------------------------

class _HeroIcons extends StatelessWidget {
  const _HeroIcons({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryIcon = data.secondaryIcon;

    if (secondaryIcon == null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          data.icon,
          size: 44,
          color: primaryColor,
        ),
      );
    }

    // Dois ícones lado a lado com leve sobreposição
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            data.icon,
            size: 38,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            secondaryIcon,
            size: 38,
            color: primaryColor.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Indicador de dots animados
// ---------------------------------------------------------------------------

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor
                : context.hairline,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
