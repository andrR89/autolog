import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/personal_documents/document_validators.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Tela de formulário de multa — criar ou editar.
class FineFormScreen extends ConsumerStatefulWidget {
  const FineFormScreen({super.key, this.initial});

  /// Multa existente (edição) ou null (criação).
  final Fine? initial;

  @override
  ConsumerState<FineFormScreen> createState() => _FineFormScreenState();
}

class _FineFormScreenState extends ConsumerState<FineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _vehicleId;
  late final TextEditingController _autoNumberCtrl;
  late DateTime _issuedAt;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _amountCtrl;
  DateTime? _dueDate;
  late final TextEditingController _pointsCtrl;

  bool _saving = false;
  List<Vehicle> _vehicles = [];
  bool _vehiclesLoading = true;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _vehicleId = f?.vehicleId;
    _autoNumberCtrl = TextEditingController(text: f?.autoNumber ?? '');
    _issuedAt = f?.issuedAt ?? DateTime.now();
    _descriptionCtrl = TextEditingController(text: f?.description ?? '');
    _amountCtrl = TextEditingController(
      text: f != null ? f.amount.toString().replaceAll('.', ',') : '',
    );
    _dueDate = f?.dueDate;
    _pointsCtrl = TextEditingController(
      text: f?.points?.toString() ?? '',
    );
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final userId = ref.read(currentUserIdProvider);
    final repo = ref.read(vehicleRepositoryProvider);
    final vehicles = await repo.listByUser(userId);
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _vehiclesLoading = false;
        // Se só tem um veículo, pré-seleciona.
        if (_vehicleId == null && vehicles.length == 1) {
          _vehicleId = vehicles.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _autoNumberCtrl.dispose();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIssuedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _issuedAt = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um veículo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(fineRepositoryProvider);
      final amount = parseDecimalPtBr(_amountCtrl.text);
      final points = _pointsCtrl.text.trim().isEmpty
          ? null
          : int.parse(_pointsCtrl.text.trim());

      if (_isEditing) {
        await repo.update(
          widget.initial!.copyWith(
            vehicleId: _vehicleId!,
            autoNumber: _autoNumberCtrl.text.trim().isEmpty
                ? null
                : _autoNumberCtrl.text.trim(),
            issuedAt: _issuedAt,
            description: _descriptionCtrl.text.trim(),
            amount: amount,
            dueDate: _dueDate,
            points: points,
            syncStatus: SyncStatus.pending,
          ),
        );
      } else {
        await repo.create(
          Fine(
            id: const Uuid().v4(),
            vehicleId: _vehicleId!,
            autoNumber: _autoNumberCtrl.text.trim().isEmpty
                ? null
                : _autoNumberCtrl.text.trim(),
            issuedAt: _issuedAt,
            description: _descriptionCtrl.text.trim(),
            amount: amount,
            dueDate: _dueDate,
            paid: false,
            points: points,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            syncStatus: SyncStatus.pending,
          ),
        );
      }

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

  Future<void> _togglePaid() async {
    if (widget.initial == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(fineRepositoryProvider);
      await repo.togglePaid(widget.initial!.id);
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
            content: Text('Não foi possível atualizar. Tente novamente.'),
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
        title: Text(_isEditing ? 'Editar multa' : 'Nova multa'),
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
      body: _vehiclesLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                            eyebrow: 'Veículo e infração',
                            children: [
                              // Dropdown veículo
                              DropdownButtonFormField<String>(
                                initialValue: _vehicleId,
                                decoration: const InputDecoration(
                                  labelText: 'Veículo',
                                ),
                                items: _vehicles
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v.id,
                                        child: Text(v.nickname),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _vehicleId = v),
                                validator: (v) =>
                                    v == null ? 'Selecione um veículo' : null,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Número do auto
                              TextFormField(
                                controller: _autoNumberCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Número do auto (opcional)',
                                  hintText: 'Ex.: AA12345678',
                                ),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Data da infração
                              DatePickerField(
                                value: _issuedAt,
                                onTap: _pickIssuedAt,
                              ),
                            ],
                          ),

                          FormSectionCard(
                            eyebrow: 'Descrição e valor',
                            children: [
                              // Descrição
                              TextFormField(
                                controller: _descriptionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição',
                                  hintText: 'Ex.: Excesso de velocidade',
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLines: 2,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Informe uma descrição'
                                        : null,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Valor
                              TextFormField(
                                controller: _amountCtrl,
                                decoration: const InputDecoration(
                                  labelText: r'Valor (R$)',
                                  hintText: 'Ex.: 293,47',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: validateAmount,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Prazo pagamento
                              _DueDateField(
                                value: _dueDate,
                                onTap: _pickDueDate,
                                onClear: () =>
                                    setState(() => _dueDate = null),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Pontos
                              TextFormField(
                                controller: _pointsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Pontos na CNH (opcional)',
                                  hintText: 'Ex.: 7',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: validatePoints,
                              ),
                            ],
                          ),

                          // Botão marcar como pago/não pago em edição
                          if (_isEditing) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: OutlinedButton(
                                onPressed: _saving ? null : _togglePaid,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      widget.initial!.paid
                                          ? AppColors.warning
                                          : AppColors.success,
                                  side: BorderSide(
                                    color: widget.initial!.paid
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                  minimumSize:
                                      const Size(double.infinity, 48),
                                ),
                                child: Text(
                                  widget.initial!.paid
                                      ? 'Marcar como não pago'
                                      : 'Marcar como pago',
                                ),
                              ),
                            ),
                          ],

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
                            : Text(
                                _isEditing
                                    ? 'Salvar alterações'
                                    : 'Registrar multa',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
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
        label: const Text('Prazo de pagamento (opcional)'),
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
