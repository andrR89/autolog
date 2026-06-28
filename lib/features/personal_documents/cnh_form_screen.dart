import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/personal_documents/document_validators.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de cadastro/edição dos dados de CNH do usuário.
class CnhFormScreen extends ConsumerStatefulWidget {
  const CnhFormScreen({super.key, this.initial});

  /// Perfil existente (edição) ou null (criação).
  final UserProfile? initial;

  @override
  ConsumerState<CnhFormScreen> createState() => _CnhFormScreenState();
}

class _CnhFormScreenState extends ConsumerState<CnhFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cnhNumberCtrl;
  String? _cnhCategory;
  DateTime? _cnhExpiresAt;

  bool _saving = false;

  static const _categories = ['A', 'B', 'AB', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _cnhNumberCtrl = TextEditingController(text: p?.cnhNumber ?? '');
    _cnhCategory = p?.cnhCategory;
    _cnhExpiresAt = p?.cnhExpiresAt;
  }

  @override
  void dispose() {
    _cnhNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _cnhExpiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) {
      setState(() => _cnhExpiresAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // CNH é um agregado opcional, mas salvar com tudo vazio cria registro
    // fantasma sem feedback — bloqueia o submit cedo (UX 19/06).
    final numberFilled = _cnhNumberCtrl.text.trim().isNotEmpty;
    final hasAnything =
        numberFilled || _cnhCategory != null || _cnhExpiresAt != null;
    if (!hasAnything) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha ao menos um campo (número, categoria ou validade).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(userProfileRepositoryProvider);

      final existing = await repo.getOrCreate(userId);
      await repo.update(
        existing.copyWith(
          cnhNumber: numberFilled ? _cnhNumberCtrl.text.trim() : null,
          cnhCategory: _cnhCategory,
          cnhExpiresAt: _cnhExpiresAt,
          syncStatus: SyncStatus.pending,
        ),
      );

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/personal-documents');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: context.hairline,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: const Text('CNH'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/personal-documents');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ResponsiveBody(
                maxWidth: ResponsiveWidths.form,
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSectionCard(
                      eyebrow: 'Dados da CNH',
                      children: [
                        // Número da CNH
                        TextFormField(
                          controller: _cnhNumberCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número da CNH (opcional)',
                            hintText: 'Ex.: 01234567891',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: validateCnhNumber,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Categoria
                        DropdownButtonFormField<String>(
                          initialValue: _cnhCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoria (opcional)',
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('Categoria $c'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _cnhCategory = v),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Vencimento
                        _ExpiresAtField(
                          value: _cnhExpiresAt,
                          onTap: _pickDate,
                          onClear: () =>
                              setState(() => _cnhExpiresAt = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            ),

            // Barra sticky
            SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceRaised,
                  border: Border(top: BorderSide(color: context.hairline)),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandInk,
                          ),
                        )
                      : const Text('Salvar CNH'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiresAtField extends StatelessWidget {
  const _ExpiresAtField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.event_rounded, size: 18),
        label: const Text('Vencimento (opcional)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.inkMuted,
          side: BorderSide(color: context.hairline),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          minimumSize: const Size(double.infinity, 48),
          alignment: Alignment.centerLeft,
        ),
      );
    }
    return DatePickerField(value: value!, onTap: onTap);
  }
}

