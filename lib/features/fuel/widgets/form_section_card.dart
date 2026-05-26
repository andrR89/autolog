// Container de seção do formulário — "card branco com hairline e eyebrow".
//
// Por que existe: o form atual amontoava 7 campos verticais sem hierarquia.
// Agrupar em duas seções ("Números do abastecimento" / "Quando, onde, como")
// dá ar de checklist organizado e cria âncoras visuais que o olhar percorre.
//
// Estética: superfície branca raised + hairline (default do DS, "flat com
// linha"), com um eyebrow uppercase de letra-pequena letter-spaced que
// referencia revistas editoriais. Sem ícone, sem subtítulo — o título já
// faz o trabalho. Padding interno generoso (xl) pra inputs respirarem.

import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.eyebrow,
    required this.children,
    this.trailing,
  });

  /// Texto do eyebrow ("NÚMEROS DO ABASTECIMENTO"). Será uppercase.
  final String eyebrow;

  /// Conteúdo da seção — geralmente lista vertical de inputs.
  final List<Widget> children;

  /// Widget opcional à direita do eyebrow (ex.: badge "auto" no total).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.inkMuted,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
