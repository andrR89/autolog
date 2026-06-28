import 'dart:async';

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/fuel/widgets/inline_validation_chip.dart';
import 'package:autolog/features/fuel/widgets/vehicle_context_chip.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:autolog/features/reminders/reminder_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Valida que o campo não está vazio.
String? _validateRequired(String? value, {required String fieldLabel}) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe $fieldLabel';
  }
  return null;
}

/// Tela de formulário de lembrete — criar ou editar.
///
/// [initial] == null → modo criar ("Novo lembrete").
/// [initial] != null → modo editar ("Editar lembrete").
///
/// Redesenhada na Tranche C: VehicleContextChip no topo, campos agrupados
/// em FormSectionCard, InlineValidationChip para dueKm, DatePickerField
/// do DS, botão sticky na barra inferior. Switch "Concluído" só em edição.
class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({super.key, required this.vehicle, this.initial});

  final Vehicle vehicle;
  final Reminder? initial;

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late ReminderType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dueKmCtrl;
  DateTime? _dueDate;
  late bool _isDone;

  bool _saving = false;
  String? _dueKmError;

  Timer? _dueKmDebounce;

  // Recorrência
  bool _recorrente = false;
  int? _intervalDays;
  late final TextEditingController _intervalKmCtrl;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _type = r?.type ?? ReminderType.porKm;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _dueKmCtrl = TextEditingController(text: r?.dueKm?.toString() ?? '');
    // Para criação, data alvo padrão = hoje + 30 dias.
    _dueDate = r?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _isDone = r?.isDone ?? false;

    // Recorrência — carrega do lembrete existente se houver.
    final hasInterval = (r?.intervalDays != null) || (r?.intervalKm != null);
    _recorrente = hasInterval;
    _intervalDays = r?.intervalDays;
    _intervalKmCtrl = TextEditingController(
      text: r?.intervalKm?.toString() ?? '',
    );

    _dueKmCtrl.addListener(_onDueKmChanged);
  }

  @override
  void dispose() {
    _dueKmDebounce?.cancel();
    _dueKmCtrl.removeListener(_onDueKmChanged);
    _titleCtrl.dispose();
    _dueKmCtrl.dispose();
    _intervalKmCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validação bloqueante de dueKm — Sprint 4.5
  // ---------------------------------------------------------------------------

  void _onDueKmChanged() {
    _dueKmDebounce?.cancel();
    _dueKmDebounce = Timer(const Duration(milliseconds: 600), () {
      _runDueKmValidation();
    });
  }

  Future<void> _runDueKmValidation() async {
    if (_type != ReminderType.porKm) {
      if (mounted) setState(() => _dueKmError = null);
      return;
    }

    final raw = _dueKmCtrl.text.trim();
    final candidate = int.tryParse(raw);
    if (candidate == null) {
      // Campo vazio ou formato inválido — o validador required cuida disso.
      if (mounted) setState(() => _dueKmError = null);
      return;
    }

    try {
      final repo = ref.read(fuelEntryRepositoryProvider);
      final entries = await repo.listByVehicle(widget.vehicle.id);
      final error = validateDueKm(
        dueKm: candidate,
        vehicleInitialOdometer: widget.vehicle.initialOdometer,
        entries: entries,
      );
      if (mounted) {
        setState(() => _dueKmError = error);
      }
    } catch (_) {
      // Falha silenciosa — libera o botão em caso de erro ao carregar entries.
      if (mounted) setState(() => _dueKmError = null);
    }
  }

  // ---------------------------------------------------------------------------
  // DatePicker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // Validação manual de campos condicionais.
    bool valid = _formKey.currentState!.validate();

    if (_type == ReminderType.porKm) {
      final kmText = _dueKmCtrl.text.trim();
      if (kmText.isEmpty ||
          int.tryParse(kmText) == null ||
          int.parse(kmText) < 0) {
        valid = false;
        // A validação inline no TextFormField já exibe a mensagem de erro.
      }
    } else {
      if (_dueDate == null) {
        valid = false;
      }
    }

    if (!valid) return;

    setState(() => _saving = true);

    try {
      final saver = ref.read(reminderSaverProvider);

      // Garante que o campo oposto seja null.
      final int? dueKm = _type == ReminderType.porKm
          ? int.parse(_dueKmCtrl.text.trim())
          : null;
      final DateTime? dueDate = _type == ReminderType.porData ? _dueDate : null;

      // Intervalos de recorrência — null se switch desligado ou campo não aplicável.
      int? intervalDays;
      int? intervalKm;
      if (_recorrente) {
        if (_type == ReminderType.porData && _intervalDays != null) {
          intervalDays = _intervalDays;
        }
        if (_type == ReminderType.porKm) {
          final raw = _intervalKmCtrl.text.trim();
          intervalKm = int.tryParse(raw);
        }
      }

      if (_isEditing) {
        await saver.update(
          widget.initial!,
          type: _type,
          title: _titleCtrl.text.trim(),
          dueKm: dueKm,
          dueDate: dueDate,
          isDone: _isDone,
          intervalDays: intervalDays,
          intervalKm: intervalKm,
        );
      } else {
        await saver.create(
          vehicleId: widget.vehicle.id,
          type: _type,
          title: _titleCtrl.text.trim(),
          dueKm: dueKm,
          dueDate: dueDate,
          isDone: false,
          intervalDays: intervalDays,
          intervalKm: intervalKm,
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vehicles/${widget.vehicle.id}/reminders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o lembrete. Tente novamente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: context.hairline,
        // Status bar com ícones escuros — fundo é o surface off-white.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Text(_isEditing ? 'Editar lembrete' : 'Novo lembrete'),
        leading: Tooltip(
          message: 'Voltar',
          child: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles/${widget.vehicle.id}/reminders');
              }
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable content.
            Expanded(
              child: ResponsiveBody(
                maxWidth: ResponsiveWidths.form,
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Contexto do veículo ──────────────────────────────────
                    VehicleContextChip(vehicle: widget.vehicle),

                    // ── Seção 1: O que lembrar ───────────────────────────────
                    FormSectionCard(
                      eyebrow: 'O que lembrar',
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            hintText: 'Ex.: Troca de óleo',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              _validateRequired(v, fieldLabel: 'o título'),
                        ),
                      ],
                    ),

                    // ── Seção 2: Quando ──────────────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Quando',
                      children: [
                        // Tipo: porKm / porData — segmentado estilizado.
                        const _SectionFieldLabel('TIPO DE LEMBRETE'),
                        const SizedBox(height: AppSpacing.sm),
                        _ReminderTypeSegmented(
                          value: _type,
                          onChanged: (t) {
                            setState(() {
                              _type = t;
                              // Limpa o campo oposto ao trocar de tipo.
                              if (_type == ReminderType.porKm) {
                                _dueDate = null;
                                _dueKmError = null;
                              } else {
                                _dueKmCtrl.clear();
                                _dueKmError = null;
                              }
                            });
                            // Ao selecionar porKm, valida imediatamente.
                            if (_type == ReminderType.porKm) {
                              _runDueKmValidation();
                            }
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Campo condicional por tipo — animado com
                        // AnimatedSwitcher para suavizar a troca.
                        AnimatedSwitcher(
                          duration: AppMotion.standard,
                          switchInCurve: AppMotion.standardCurve,
                          switchOutCurve: AppMotion.standardCurve,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _type == ReminderType.porKm
                              ? _DueKmField(
                                  key: const ValueKey('due_km'),
                                  controller: _dueKmCtrl,
                                  error: _dueKmError,
                                )
                              : _DueDateField(
                                  key: const ValueKey('due_date'),
                                  dueDate: _dueDate,
                                  onTap: _pickDate,
                                ),
                        ),

                        // Switch "Concluído" — só em modo edição.
                        if (_isEditing) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _DoneToggle(
                            value: _isDone,
                            onChanged: (v) => setState(() => _isDone = v),
                          ),
                        ],
                      ],
                    ),

                    // ── Seção 3: Recorrência ─────────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Recorrência',
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Repetir automaticamente'),
                          subtitle: const Text(
                            'Quando marcar como feito, criamos o próximo automaticamente',
                          ),
                          value: _recorrente,
                          onChanged: (v) => setState(() {
                            _recorrente = v;
                            if (!v) {
                              _intervalDays = null;
                              _intervalKmCtrl.clear();
                            }
                          }),
                        ),
                        if (_recorrente) ...[
                          const SizedBox(height: AppSpacing.md),
                          // Por data: dropdown de presets de dias.
                          if (_type == ReminderType.porData)
                            _IntervalDaysDropdown(
                              value: _intervalDays,
                              onChanged: (v) =>
                                  setState(() => _intervalDays = v),
                            ),
                          // Por km: campo numérico livre.
                          if (_type == ReminderType.porKm)
                            TextFormField(
                              controller: _intervalKmCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Repetir a cada (km)',
                                hintText: '10000',
                                suffixText: 'km',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            ),

            // ── Barra sticky de salvar ───────────────────────────────────────
            _SaveActionBar(
              onSave: _submit,
              saving: _saving,
              disabled: _dueKmError != null,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets de build
// ---------------------------------------------------------------------------

/// Eyebrow label para campo interno de seção.
class _SectionFieldLabel extends StatelessWidget {
  const _SectionFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.inkSoft,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Seletor de tipo de lembrete — duas pílulas horizontais (porKm / porData).
/// Espelha a estética do FuelTypeSegmented mas com apenas dois itens.
class _ReminderTypeSegmented extends StatelessWidget {
  const _ReminderTypeSegmented({required this.value, required this.onChanged});

  final ReminderType value;
  final ValueChanged<ReminderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          icon: Icons.speed_rounded,
          label: 'Por quilômetro',
          selected: value == ReminderType.porKm,
          onTap: () => onChanged(ReminderType.porKm),
        ),
        const SizedBox(width: AppSpacing.sm),
        _TypeChip(
          icon: Icons.event_rounded,
          label: 'Por data',
          selected: value == ReminderType.porData,
          onTap: () => onChanged(ReminderType.porData),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? AppColors.brand.withValues(alpha: 0.10)
          : context.surfaceSunken,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brand.withValues(alpha: 0.10),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.pill),
            ),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.brand : context.inkMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.brand : context.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de quilometragem alvo (porKm) com InlineValidationChip.
class _DueKmField extends StatelessWidget {
  const _DueKmField({super.key, required this.controller, required this.error});

  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Quilometragem alvo (km)',
            hintText: 'Ex.: 50000',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Informe a quilometragem alvo';
            }
            final parsed = int.tryParse(v.trim());
            if (parsed == null || parsed < 0) {
              return 'Informe a quilometragem alvo';
            }
            return null;
          },
        ),
        // InlineValidationChip — mensagem PT-BR do validateDueKm.
        InlineValidationChip(message: error),
      ],
    );
  }
}

/// Campo de data alvo (porData) — usa DatePickerField do DS.
class _DueDateField extends StatelessWidget {
  const _DueDateField({super.key, required this.dueDate, required this.onTap});

  final DateTime? dueDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Se não houver data (ao trocar para porData), usa hoje + 30 como fallback
    // visual (o valor real é controlado pelo estado pai).
    final effectiveDate =
        dueDate ?? DateTime.now().add(const Duration(days: 30));
    return DatePickerField(value: effectiveDate, onTap: onTap);
  }
}

/// Toggle "Concluído" — substituição do SwitchListTile cru, com visual
/// coerente com FullTankToggle (mesmo padrão: fundo colorido + ícone).
/// Aparece apenas no modo edição.
class _DoneToggle extends StatelessWidget {
  const _DoneToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bgColor = value
        ? AppColors.successSoft
        : context.surfaceSunken.withValues(alpha: 0.65);
    final iconColor = value ? AppColors.success : context.inkMuted;

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: value
              ? AppColors.success.withValues(alpha: 0.18)
              : context.hairline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          splashColor: value
              ? AppColors.success.withValues(alpha: 0.08)
              : context.hairline,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md + 2,
              AppSpacing.sm,
              AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.success.withValues(alpha: 0.15)
                        : context.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    value
                        ? Icons.check_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value ? 'Lembrete concluído' : 'Marcar como concluído',
                        style: textTheme.titleSmall?.copyWith(
                          color: context.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value
                            ? 'Este lembrete foi atendido.'
                            : 'O lembrete continua ativo.',
                        style: textTheme.bodySmall?.copyWith(
                          color: context.inkMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dropdown de intervalo em dias
// ---------------------------------------------------------------------------

/// Dropdown de presets de intervalo em dias para lembretes recorrentes por data.
///
/// Opções: 30, 90, 180, 365 dias; mais "Personalizado" que habilita campo livre.
class _IntervalDaysDropdown extends StatefulWidget {
  const _IntervalDaysDropdown({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_IntervalDaysDropdown> createState() => _IntervalDaysDropdownState();
}

class _IntervalDaysDropdownState extends State<_IntervalDaysDropdown> {
  static const _presets = [30, 90, 180, 365];
  late bool _isCustom;
  late final TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.value != null && !_presets.contains(widget.value);
    _customCtrl = TextEditingController(
      text: _isCustom ? widget.value.toString() : '',
    );
    _customCtrl.addListener(_onCustomChanged);
  }

  @override
  void dispose() {
    _customCtrl.removeListener(_onCustomChanged);
    _customCtrl.dispose();
    super.dispose();
  }

  void _onCustomChanged() {
    final v = int.tryParse(_customCtrl.text.trim());
    widget.onChanged(v);
  }

  String _presetLabel(int days) {
    return switch (days) {
      30 => '30 dias (mensal)',
      90 => '90 dias (trimestral)',
      180 => '180 dias (semestral)',
      365 => '365 dias (anual)',
      _ => '$days dias',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isPreset = !_isCustom;
    final dropdownValue = isPreset ? widget.value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _isCustom ? null : dropdownValue,
          decoration: const InputDecoration(labelText: 'Repetir a cada'),
          items: [
            for (final p in _presets)
              DropdownMenuItem(value: p, child: Text(_presetLabel(p))),
            const DropdownMenuItem(value: null, child: Text('Personalizado')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _isCustom = false;
                _customCtrl.clear();
              });
              widget.onChanged(v);
            } else {
              setState(() => _isCustom = true);
              widget.onChanged(null);
            }
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _customCtrl,
            decoration: const InputDecoration(
              labelText: 'Intervalo personalizado (dias)',
              hintText: 'Ex.: 45',
              suffixText: 'dias',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ],
    );
  }
}

/// Barra sticky inferior: botão Salvar com surfaceRaised + hairline top.
class _SaveActionBar extends StatelessWidget {
  const _SaveActionBar({
    required this.onSave,
    required this.saving,
    required this.disabled,
    required this.isEditing,
  });

  final VoidCallback onSave;
  final bool saving;
  final bool disabled;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          onPressed: (saving || disabled) ? null : onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
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
              : Text(isEditing ? 'Salvar alterações' : 'Criar lembrete'),
        ),
      ),
    );
  }
}
