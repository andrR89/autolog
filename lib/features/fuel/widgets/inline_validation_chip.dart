// Chip de erro de validação inline — substitui o Text vermelho cru.
//
// Quando aparece (e por que importa): logo abaixo do campo de odômetro
// quando a validação cronológica do Sprint 3.8 detecta conflito
// (entry anterior com odômetro maior, etc.). É bloqueante: o botão Salvar
// fica desabilitado enquanto este chip existe.
//
// Visualmente: usa `dangerSoft` fundo + `danger` texto+ícone (padrão DS
// para semânticas), com cantos suaves e ícone "alert-circle" — mais
// elegante que o `Text` vermelho de 12px do form antigo. Animação de
// entrada com fade+slide para não pular o layout bruto.

import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

class InlineValidationChip extends StatelessWidget {
  const InlineValidationChip({super.key, required this.message});

  /// Mensagem PT-BR. Null = não renderiza nada (espaço também desaparece).
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.standardCurve,
        switchOutCurve: AppMotion.standardCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: message == null
            ? const SizedBox(key: ValueKey('empty'), width: double.infinity)
            : Padding(
                key: ValueKey(message),
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: AppRadius.allSm,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          message!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
