// Bottom sheet "de onde vem a imagem" — câmera / galeria / cancelar.
//
// Substitui o ListTile cru do form antigo por dois tiles full-width
// pintados como cartões internos. Em vez de empilhar três linhas
// indistinguíveis, dá protagonismo a "Tirar foto" (a fluxo principal)
// e relega "Galeria" a segunda opção visual. Cancelar é um TextButton
// discreto na base, sem o típico `Icons.close` redundante.
//
// Estética: drag handle do tema, título eyebrow uppercase + frase
// curta, e os dois tiles em surfaceSunken com ícone "papel" à esquerda.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:flutter/material.dart';

Future<ImageOrigin?> showScanSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageOrigin>(
    context: context,
    builder: (ctx) => const _ScanSourceSheet(),
  );
}

class _ScanSourceSheet extends StatelessWidget {
  const _ScanSourceSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Text(
                'DE ONDE VEM O CUPOM',
                style: textTheme.labelSmall?.copyWith(
                  color: context.inkMuted,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.xs,
                AppSpacing.lg,
              ),
              child: Text(
                'Tire uma foto agora ou escolha uma imagem que já tem.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.inkMuted,
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              label: 'Tirar foto',
              detail: 'usa a câmera do celular',
              accent: true,
              onTap: () => Navigator.pop(context, ImageOrigin.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Escolher da galeria',
              detail: 'use uma foto já existente',
              onTap: () => Navigator.pop(context, ImageOrigin.gallery),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Tile "accent" usa o pareamento brand + accent (mesma identidade do
    // CTA do form). Tile secundário usa surfaceSunken + ink — menos
    // chamativo, mas mesmo footprint.
    final bg = accent ? AppColors.brand : context.surfaceSunken;
    final iconBg = accent ? AppColors.accent : context.surfaceRaised;
    final iconColor = accent ? AppColors.accentInk : AppColors.brand;
    final labelColor = accent ? AppColors.brandInk : context.ink;
    final detailColor = accent
        ? AppColors.brandInk.withValues(alpha: 0.6)
        : context.inkMuted;

    return Material(
      color: bg,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent
            ? AppColors.accent.withValues(alpha: 0.12)
            : context.hairline,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md + 2,
            AppSpacing.md + 2,
            AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body(
                        16,
                        weight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detail,
                      style: textTheme.bodySmall?.copyWith(color: detailColor),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: accent ? AppColors.accent : context.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
