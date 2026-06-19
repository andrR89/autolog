// Banners de feedback pós-scan: sucesso ("dados extraídos") e cota esgotada.
//
// Por que MaterialBanner (e não Snackbar / Dialog): o feedback aparece
// **no topo do form** logo após o scan, e precisa coexistir com o form
// (o usuário revisa os campos preenchidos sem perder a mensagem). Não é
// transitório — fica até o usuário confirmar OK. MaterialBanner do
// Material 3 cumpre esse papel; aqui só damos estética AutoLog.
//
// Decisões visuais:
// - **Sucesso (pós-scan)**: cor `successSoft` (verde-cana suave), ícone
//   check, texto enfatiza "Revise antes de salvar" em ink/600. Sem cor
//   semanticamente forte (info/azul) porque o tom é "calor humano +
//   convite à revisão", não "info passiva".
// - **Cota esgotada**: cor `warningSoft` (âmbar), ícone hourglass-bottom.
//   Tom **convidativo, não punitivo** — copy "Você usou seus 5 scans do
//   mês" + CTA Premium em accent. Não usa danger (não é erro do usuário).

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

/// Mostra o banner "dados extraídos do cupom" e retorna seu controller.
ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
showScanSuccessBanner(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  late ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
  banner;
  banner = ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      backgroundColor: AppColors.successSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      ),
      content: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium?.copyWith(color: context.ink),
          children: [
            const TextSpan(text: 'Dados extraídos do cupom. '),
            TextSpan(
              text: 'Revise antes de salvar.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => banner.close(),
          style: TextButton.styleFrom(foregroundColor: AppColors.success),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
  return banner;
}

/// Banner âmbar pra quando a IA não conseguiu extrair nada do cupom
/// (foto borrada, ângulo ruim, ou não era um cupom). Convida a preencher
/// manualmente ou tentar outra foto.
ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
showScanEmptyBanner(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  late ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
  banner;
  banner = ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      backgroundColor: AppColors.warningSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.image_search_rounded,
          size: 18,
          color: AppColors.warning,
        ),
      ),
      content: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium?.copyWith(color: context.ink),
          children: const [
            TextSpan(text: 'Não consegui ler o cupom. '),
            TextSpan(
              text: 'Tente outra foto ou preencha manualmente.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => banner.close(),
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
  return banner;
}

/// Mostra o banner "sua cota acabou". [onSeePremium] é chamado quando o
/// usuário toca em "Ver Premium" (e o banner é fechado automaticamente).
ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
showQuotaExhaustedBanner(
  BuildContext context, {
  required VoidCallback onSeePremium,
}) {
  final textTheme = Theme.of(context).textTheme;
  late ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
  banner;
  banner = ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      backgroundColor: AppColors.warningSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.hourglass_bottom_rounded,
          size: 18,
          color: AppColors.warning,
        ),
      ),
      content: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium?.copyWith(color: context.ink),
          children: const [
            TextSpan(text: 'Seus '),
            TextSpan(
              text: '5 scans do mês',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text:
                  ' acabaram. Continue manualmente — ou vire Premium pra scans ilimitados.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => banner.close(), child: const Text('OK')),
        FilledButton(
          onPressed: () {
            banner.close();
            onSeePremium();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: AppColors.accent,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          child: const Text('Ver Premium'),
        ),
      ],
    ),
  );
  return banner;
}
