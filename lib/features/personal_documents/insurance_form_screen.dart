import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/personal_documents/document_validators.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Tela de formulário de apólice de seguro — criar ou editar.
class InsuranceFormScreen extends ConsumerStatefulWidget {
  const InsuranceFormScreen({super.key, this.initial});

  /// Apólice existente (edição) ou null (criação).
  final Insurance? initial;

  @override
  ConsumerState<InsuranceFormScreen> createState() =>
      _InsuranceFormScreenState();
}

class _InsuranceFormScreenState extends ConsumerState<InsuranceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _vehicleId;
  late final TextEditingController _insurerCtrl;
  late final TextEditingController _policyNumberCtrl;
  DateTime? _startsAt;
  DateTime? _endsAt;
  late final TextEditingController _premiumPaidCtrl;
  late final TextEditingController _notesCtrl;

  bool _saving = false;
  List<Vehicle> _vehicles = [];
  bool _vehiclesLoading = true;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _vehicleId = i?.vehicleId;
    _insurerCtrl = TextEditingController(text: i?.insurer ?? '');
    _policyNumberCtrl = TextEditingController(text: i?.policyNumber ?? '');
    _startsAt = i?.startsAt;
    _endsAt = i?.endsAt;
    _premiumPaidCtrl = TextEditingController(
      text: i?.premiumPaid != null
          ? i!.premiumPaid.toString().replaceAll('.', ',')
          : '',
    );
    _notesCtrl = TextEditingController(text: i?.notes ?? '');
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
        if (_vehicleId == null && vehicles.length == 1) {
          _vehicleId = vehicles.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _insurerCtrl.dispose();
    _policyNumberCtrl.dispose();
    _premiumPaidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickEndsAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ??
          (_startsAt != null
              ? _startsAt!.add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _endsAt = picked);
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
    if (_startsAt == null || _endsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o período de vigência.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(insuranceRepositoryProvider);
      final premiumPaid = parseAmountOptional(_premiumPaidCtrl.text);

      if (_isEditing) {
        await repo.update(
          widget.initial!.copyWith(
            vehicleId: _vehicleId!,
            insurer: _insurerCtrl.text.trim().isEmpty
                ? null
                : _insurerCtrl.text.trim(),
            policyNumber: _policyNumberCtrl.text.trim().isEmpty
                ? null
                : _policyNumberCtrl.text.trim(),
            startsAt: _startsAt!,
            endsAt: _endsAt!,
            premiumPaid: premiumPaid,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            syncStatus: SyncStatus.pending,
          ),
        );
      } else {
        await repo.create(
          Insurance(
            id: const Uuid().v4(),
            vehicleId: _vehicleId!,
            insurer: _insurerCtrl.text.trim().isEmpty
                ? null
                : _insurerCtrl.text.trim(),
            policyNumber: _policyNumberCtrl.text.trim().isEmpty
                ? null
                : _policyNumberCtrl.text.trim(),
            startsAt: _startsAt!,
            endsAt: _endsAt!,
            premiumPaid: premiumPaid,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.hairline,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Text(_isEditing ? 'Editar apólice' : 'Nova apólice'),
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FormSectionCard(
                            eyebrow: 'Veículo e seguradora',
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

                              // Seguradora
                              TextFormField(
                                controller: _insurerCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Seguradora (opcional)',
                                  hintText: 'Ex.: Porto Seguro',
                                ),
                                textCapitalization:
                                    TextCapitalization.words,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Número da apólice
                              TextFormField(
                                controller: _policyNumberCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Número da apólice (opcional)',
                                  hintText: 'Ex.: 123456789',
                                ),
                              ),
                            ],
                          ),

                          FormSectionCard(
                            eyebrow: 'Vigência',
                            children: [
                              // Início
                              _DateField(
                                label: 'INÍCIO DA VIGÊNCIA',
                                value: _startsAt,
                                onTap: _pickStartsAt,
                                isRequired: true,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Fim
                              _DateField(
                                label: 'FIM DA VIGÊNCIA',
                                value: _endsAt,
                                onTap: _pickEndsAt,
                                isRequired: true,
                              ),
                            ],
                          ),

                          FormSectionCard(
                            eyebrow: 'Valor e observações',
                            children: [
                              // Prêmio pago
                              TextFormField(
                                controller: _premiumPaidCtrl,
                                decoration: const InputDecoration(
                                  labelText: r'Prêmio pago (R$) — opcional',
                                  hintText: 'Ex.: 1.200,00',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: validateAmountOptional,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Notas
                              TextFormField(
                                controller: _notesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Observações (opcional)',
                                  hintText:
                                      r'Ex.: Franquia R$ 2.000, cobre terceiros',
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLines: 3,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),

                  // Barra sticky
                  SafeArea(
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
                                    : 'Registrar apólice',
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.isRequired,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (value != null) {
      return DatePickerField(value: value!, onTap: onTap);
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.event_rounded, size: 18),
      label: Text(isRequired ? '$label *' : label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkMuted,
        side: const BorderSide(color: AppColors.hairline),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
