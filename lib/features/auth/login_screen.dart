import 'package:autolog/features/auth/apple_sign_in_repository.dart';
import 'package:autolog/features/auth/auth_error_mapper.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/auth/validators.dart';
import 'package:autolog/features/auth/widgets/auth_widgets.dart';
import 'package:autolog/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';

/// Tela de login com e-mail/senha e opção Google OAuth.
///
/// Design: duas faixas (hero brand escuro + formulário off-white),
/// animação de entrada fade+slide, inputs temados pelo design system.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    try {
      await ref.read(appleSignInRepositoryProvider).signInWithApple();
    } on AppleSignInException catch (e) {
      // Cancelamento silencioso — não exibe snackbar de erro
      if (e.message == 'Login com Apple cancelado.') return;
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Erro ao iniciar login com Apple.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } on AuthException catch (e) {
      if (mounted) _showError(mapAuthErrorToUserMessage(e));
    } catch (_) {
      if (mounted) _showError('Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) _showError(mapAuthErrorToUserMessage(e));
    } catch (_) {
      if (mounted) _showError('Erro ao iniciar login com Google.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.authLoginTitle,
      formContent: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo e-mail
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: AppTypography.body(15, weight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Campo senha
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _signIn(),
                style: AppTypography.body(15, weight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: l10n.authPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.authPasswordShow
                        : l10n.authPasswordHide,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Botão entrar — proeminente, accent lima
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.brandInk,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.allMd,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandInk,
                          ),
                        )
                      : Text(
                          'Entrar',
                          style: AppTypography.body(
                            15,
                            weight: FontWeight.w700,
                            color: AppColors.brandInk,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Separador "ou"
              _OrDivider(),
              const SizedBox(height: AppSpacing.md),

              // Botão Google
              GoogleButton(onPressed: _signInWithGoogle, loading: _loading),
              const SizedBox(height: AppSpacing.md),

              // Botão Apple — visível apenas em iOS 13+ (AppleButton oculta automaticamente)
              AppleButton(onPressed: _signInWithApple, loading: _loading),

              // Espaço abaixo dos botões sociais (usa Visibility para não deixar
              // espaço duplo quando o botão Apple não aparece)
              const SizedBox(height: AppSpacing.xl),

              // Toggle para cadastro
              AuthToggleLink(
                prompt: 'Não tem conta? ',
                actionLabel: 'Cadastre-se',
                onTap: () => context.go('/signup'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Divisor "ou" centralizado.
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'ou',
            style: AppTypography.body(
              12,
              weight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.hairline)),
      ],
    );
  }
}
