// Barra inferior fixa: total em destaque (esquerda) + botão Salvar (direita).
//
// Por que sticky e não inline: o total é o "resumo emocional" do
// abastecimento — quanto vai sair do bolso. Mantê-lo sempre visível enquanto
// o usuário digita litros e preço dá feedback imediato e elimina aquela
// sensação de "rolagem ansiosa" pra conferir o total antes de salvar. O
// botão Salvar fica grudado ao mesmo eixo visual, ergonomicamente
// alcançável pelo polegar.
//
// Layout:
//
//   ┌─────────────────────────────────────────────────────────────┐
//   │  TOTAL                                                       │
//   │  R$ 250,42                            [ Salvar abastecimento]│
//   └─────────────────────────────────────────────────────────────┘
//
// - Total em Bricolage 28/700 tabular, alinhado à esquerda.
// - Sem total ainda → mostra "—" em inkSoft, mesma "altura visual" (não
//   colapsa, mantém o ritmo da barra).
// - Botão FilledButton padrão do tema (52px alt, raio 14, brand).
// - Barra com hairline top e fundo surfaceRaised (sobe sutilmente do
//   off-white da tela).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class TotalActionBar extends StatelessWidget {
  const TotalActionBar({
    super.key,
    required this.totalDisplay,
    required this.onSave,
    required this.saving,
    required this.disabled,
    this.isEditing = false,
  });

  /// Total formatado em pt-BR ("R$ 250,42") ou string vazia se ainda
  /// não calculável.
  final String totalDisplay;

  final VoidCallback onSave;
  final bool saving;

  /// True quando o botão deve ficar desabilitado (validação bloqueante).
  final bool disabled;

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasTotal = totalDisplay.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border(top: AppBorders.hairline),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bloco do total.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.inkSoft,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: AppMotion.standard,
                    switchInCurve: AppMotion.standardCurve,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      hasTotal ? totalDisplay : '—',
                      key: ValueKey(hasTotal ? totalDisplay : '—'),
                      style: AppTypography.metric(
                        26,
                        weight: FontWeight.w700,
                        color: hasTotal ? AppColors.ink : AppColors.inkSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton(
              onPressed: (saving || disabled) ? null : onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandInk,
                      ),
                    )
                  : Text(isEditing ? 'Salvar alterações' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
