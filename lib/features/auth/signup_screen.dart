import 'package:autolog/features/auth/apple_sign_in_repository.dart';
import 'package:autolog/features/auth/auth_error_mapper.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/auth/validators.dart';
import 'package:autolog/features/auth/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';

/// Tela de cadastro com e-mail/senha e opção Google OAuth.
///
/// Design: idêntica ao LoginScreen (AuthScaffold + 2 faixas), apenas
/// título e ação do CTA diferem.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    try {
      await ref.read(appleSignInRepositoryProvider).signInWithApple();
    } on AppleSignInException catch (e) {
      if (e.message == 'Login com Apple cancelado.') return;
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Erro ao iniciar login com Apple.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada! Verifique seu e-mail para confirmar o cadastro.',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('user already registered') ||
          msg.contains('email address is already registered')) {
        _showError('Este e-mail já está cadastrado.');
      } else if (msg.contains('password should be at least')) {
        _showError('A senha deve ter ao menos 6 caracteres.');
      } else {
        _showError(mapAuthErrorToUserMessage(e));
      }
    } catch (_) {
      if (mounted) _showError('Erro ao criar conta. Tente novamente.');
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
    return AuthScaffold(
      title: 'Crie sua conta',
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
                autofillHints: const [AutofillHints.newUsername],
                style: AppTypography.body(15, weight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Campo senha
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _signUp(),
                style: AppTypography.body(15, weight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
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

              // Botão cadastrar — proeminente, brand escuro
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _signUp,
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
                          'Criar conta',
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

              const SizedBox(height: AppSpacing.xl),

              // Toggle para login
              AuthToggleLink(
                prompt: 'Já tem conta? ',
                actionLabel: 'Entrar',
                onTap: () => context.go('/login'),
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
