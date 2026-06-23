// Paywall — tela de upgrade pra premium.
//
// Estado atual (sem RevenueCat):
//   - Mostra planos com preço placeholder
//   - CTA "Assinar" desabilitado com badge "Em breve"
//   - Botão "Já sou premium" / "Restaurar" abre uma snackbar explicando
//
// Quando BILLING_ENABLED=true (futuro):
//   - CTA aciona Purchases.purchase(package)
//   - "Restaurar" aciona Purchases.restorePurchases
//   - On success → entitlement atualiza e a tela fecha

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/observability/analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool _kBillingEnabled = bool.fromEnvironment(
  'BILLING_ENABLED',
  defaultValue: false,
);

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _selected = _Plan.yearly;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget — analytics nunca bloqueia render.
    // ignore: discarded_futures
    track(AnalyticsEvent.paywallView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
        actionsIconTheme: const IconThemeData(color: AppColors.brandInk),
        title: const Text('AutoLog Premium'),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tudo do AutoLog,\nsem limites.',
                      style: AppTypography.display(
                        34,
                        weight: FontWeight.w800,
                        height: 1.05,
                        color: AppColors.brandInk,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _FeatureLine(
                      icon: Icons.qr_code_scanner_outlined,
                      title: 'Scan de cupom ilimitado',
                      subtitle:
                          'Tire foto, app preenche tudo. Sem cota mensal.',
                    ),
                    const _FeatureLine(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Insights de IA ilimitados',
                      subtitle:
                          'Análises de histórico, previsões de manutenção '
                          'e plano fiscal sem limite.',
                    ),
                    const _FeatureLine(
                      icon: Icons.chat_outlined,
                      title: 'Chat com seu histórico',
                      subtitle:
                          'Pergunte qualquer coisa sobre seus dados — quantas '
                          'vezes quiser.',
                    ),
                    const _FeatureLine(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Sync entre dispositivos',
                      subtitle:
                          'Seus dados em todos os seus aparelhos, sempre '
                          'atualizados.',
                    ),
                    const _FeatureLine(
                      icon: Icons.favorite_outline,
                      title: 'Apoia o app indie',
                      subtitle:
                          'AutoLog é feito por uma pessoa só. Sua assinatura '
                          'paga a infra e mantém tudo grátis pra quem ainda '
                          'não pode pagar.',
                    ),
                    const SizedBox(height: 24),
                    _PlanCard(
                      plan: _Plan.monthly,
                      label: 'Mensal',
                      price: r'R$ 9,90/mês',
                      sub: 'Cancele quando quiser.',
                      selected: _selected == _Plan.monthly,
                      onTap: () => setState(() => _selected = _Plan.monthly),
                    ),
                    const SizedBox(height: 12),
                    _PlanCard(
                      plan: _Plan.yearly,
                      label: 'Anual',
                      price: r'R$ 79,90/ano',
                      sub: 'Economiza 33% vs mensal.',
                      badge: 'Mais escolhido',
                      selected: _selected == _Plan.yearly,
                      onTap: () => setState(() => _selected = _Plan.yearly),
                    ),
                    const SizedBox(height: 12),
                    _PlanCard(
                      plan: _Plan.lifetime,
                      label: 'Vitalício',
                      price: r'R$ 199,90 uma vez',
                      sub: 'Sem renovação. Pra sempre.',
                      selected: _selected == _Plan.lifetime,
                      onTap: () => setState(() => _selected = _Plan.lifetime),
                    ),
                  ],
                ),
              ),
            ),
            // Sticky footer com CTA
            Container(
              decoration: BoxDecoration(
                color: AppColors.brand,
                border: Border(
                  top: BorderSide(
                    color: AppColors.brandInk.withValues(alpha: 0.1),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _onSubscribe,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.brand,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      _kBillingEnabled ? 'Assinar' : 'Em breve',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _onRestore,
                    child: Text(
                      'Já sou Premium — restaurar',
                      style: TextStyle(
                        color: AppColors.brandInk.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubscribe() async {
    final messenger = ScaffoldMessenger.of(context);
    await track(AnalyticsEvent.paywallCta, props: {'plan': _selected.name});
    if (!_kBillingEnabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Pagamentos chegam na próxima atualização. Te avisamos por '
            'e-mail quando estiver disponível.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // TODO(billing): Purchases.purchasePackage(...)
  }

  Future<void> _onRestore() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Restauração estará disponível junto com pagamentos.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _Plan { monthly, yearly, lifetime }

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.brandInk.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.35,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.label,
    required this.price,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _Plan plan;
  final String label;
  final String price;
  final String sub;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Plano $label, $price',
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.brandInk.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.brandInk.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioMark(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.brandInk,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: AppColors.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: AppColors.brandInk.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.brandInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.accent
              : AppColors.brandInk.withValues(alpha: 0.35),
          width: 2,
        ),
        color: selected ? AppColors.accent : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, color: AppColors.brand, size: 14)
          : null,
    );
  }
}
