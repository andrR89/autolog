// Bottom sheet "de onde vem o CRLV" — câmera / galeria / arquivo (PDF).
//
// Estende o padrão do ScanSourceSheet do fuel form com uma terceira opção:
// seleção de arquivo (PDF ou imagem) via file_picker.
// Mantém o mesmo vocabulário visual (drag handle, eyebrow uppercase, _SourceTile).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

/// Origem da captura do CRLV.
enum CrlvSource { camera, gallery, file }

Future<CrlvSource?> showCrlvSourceSheet(BuildContext context) {
  return showModalBottomSheet<CrlvSource>(
    context: context,
    builder: (ctx) => const _CrlvSourceSheet(),
  );
}

class _CrlvSourceSheet extends StatelessWidget {
  const _CrlvSourceSheet();

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
        // SingleChildScrollView resolve overflows pequenos por arredondamento
        // ou devices com keyboard/notch ocupando espaço (regressão 26/05/2026,
        // sheet estourava 0.25px em alguns aparelhos).
        child: SingleChildScrollView(
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
                'DE ONDE VEM O CRLV',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
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
                'Tire uma foto, escolha da galeria ou selecione um PDF.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              label: 'Tirar foto',
              detail: 'usa a câmera do celular',
              accent: true,
              onTap: () => Navigator.pop(context, CrlvSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Escolher da galeria',
              detail: 'use uma foto já existente',
              onTap: () => Navigator.pop(context, CrlvSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.upload_file_outlined,
              label: 'Arquivo PDF ou imagem',
              detail: 'selecione do armazenamento',
              onTap: () => Navigator.pop(context, CrlvSource.file),
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

    final bg = accent ? AppColors.brand : AppColors.surfaceSunken;
    final iconBg = accent ? AppColors.accent : AppColors.surfaceRaised;
    final iconColor = accent ? AppColors.accentInk : AppColors.brand;
    final labelColor = accent ? AppColors.brandInk : AppColors.ink;
    final detailColor = accent
        ? AppColors.brandInk.withValues(alpha: 0.6)
        : AppColors.inkMuted;

    return Material(
      color: bg,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.hairline,
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
                color: accent ? AppColors.accent : AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
