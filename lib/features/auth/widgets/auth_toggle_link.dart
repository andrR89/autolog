// Link de alternância entre login e signup.
//
// Exibe uma linha com texto e um TextButton em accent para navegar
// entre as duas telas de autenticação.

import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';

/// Linha "Não tem conta? Cadastre-se" ou "Já tem conta? Entrar".
class AuthToggleLink extends StatelessWidget {
  const AuthToggleLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  /// Texto antes do botão (ex: "Não tem conta?").
  final String prompt;

  /// Label do botão (ex: "Cadastre-se").
  final String actionLabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: AppTypography.body(
            14,
            weight: FontWeight.w400,
            color: AppColors.inkMuted,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brand,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: AppTypography.body(
              14,
              weight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
        ),
      ],
    );
  }
}
