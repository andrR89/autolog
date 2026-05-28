import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expense_saver.dart';
import 'package:autolog/features/expenses/widgets/expense_category_picker.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/fuel/widgets/scan_cta_banner.dart';
import 'package:autolog/features/fuel/widgets/scan_feedback_banners.dart';
import 'package:autolog/features/fuel/widgets/scan_source_sheet.dart';
import 'package:autolog/features/fuel/widgets/vehicle_context_chip.dart';
import 'package:autolog/features/scan/expense_scan_service.dart';
import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:decimal/decimal.dart';
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

/// Valida odômetro opcional: vazio é OK, se preenchido deve ser int >= 0.
String? _validateOptionalOdometer(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null; // opcional
  final parsed = int.tryParse(raw.trim());
  if (parsed == null) return 'Use apenas números';
  if (parsed < 0) return 'Não pode ser negativo';
  return null;
}

/// Tela de formulário de despesa — criar ou editar.
///
/// [initial] == null → modo criar ("Nova despesa").
/// [initial] != null → modo editar ("Editar despesa").
///
/// Redesenhada na Tranche C: VehicleContextChip no topo, campos agrupados
/// em FormSectionCard, categoria via ExpenseCategoryPicker (pílulas),
/// DatePickerField do design system, botão sticky na barra inferior.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, required this.vehicle, this.initial});

  final Vehicle vehicle;
  final Expense? initial;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late ExpenseCategory _category;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _odometerCtrl;

  bool _saving = false;
  bool _scanning = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _date = e?.date ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.manutencao;
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toString().replaceAll('.', ',') : '',
    );
    _odometerCtrl = TextEditingController(text: e?.odometer?.toString() ?? '');
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _odometerCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DatePicker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Scan
  // ---------------------------------------------------------------------------

  /// Fluxo confirmatório: foto → IA → pré-preenche form → usuário revisa.
  /// Nunca bloqueia o form — erros viram banners informativos (Regras #3 e #3b).
  Future<void> _scan() async {
    final origin = await showScanSourceSheet(context);
    if (origin == null) return; // cancelado

    setState(() => _scanning = true);

    try {
      final imageSource = ref.read(imageSourceProvider);
      final preprocessor = ref.read(imagePreprocessorProvider);
      final scanService = ref.read(expenseScanServiceProvider);

      final bytes = await imageSource.obtainReceiptImage(origin: origin);
      if (bytes == null) return; // cancelado na captura

      final Uint8List prepared;
      try {
        prepared = preprocessor.prepareForUpload(bytes);
      } on ImageTooLargeException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A imagem ficou grande demais. Tente com menos zoom.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final scanned = await scanService.scan(prepared);

      if (!mounted) return;

      // Pré-preenche apenas campos não-nulos (Regra de Ouro #3).
      setState(() {
        if (scanned.amount != null) {
          _amountCtrl.text = scanned.amount!.toString().replaceAll('.', ',');
        }
        if (scanned.date != null) {
          _date = scanned.date!;
        }
        if (scanned.category != null) {
          _category = scanned.category!;
        }
        if (scanned.description != null && scanned.description!.isNotEmpty) {
          _descriptionCtrl.text = scanned.description!;
        }
      });

      showScanSuccessBanner(context);
    } on QuotaExhaustedException {
      if (mounted) {
        showQuotaExhaustedBanner(
          context,
          onSeePremium: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium chega em breve'),
                ),
              );
            }
          },
        );
      }
    } on ScanException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não conseguimos ler o comprovante. Tente outra foto ou preencha manualmente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não conseguimos ler o comprovante. Tente outra foto ou preencha manualmente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final saver = ref.read(expenseSaverProvider);

      final Decimal amount = parseDecimalPtBr(_amountCtrl.text);
      final int? odometer = _odometerCtrl.text.trim().isEmpty
          ? null
          : int.parse(_odometerCtrl.text.trim());

      if (_isEditing) {
        await saver.update(
          widget.initial!,
          date: _date,
          category: _category,
          description: _descriptionCtrl.text.trim(),
          amount: amount,
          odometer: odometer,
        );
      } else {
        await saver.create(
          vehicleId: widget.vehicle.id,
          date: _date,
          category: _category,
          description: _descriptionCtrl.text.trim(),
          amount: amount,
          odometer: odometer,
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vehicles/${widget.vehicle.id}/expenses');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar a despesa. Tente novamente.',
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
        title: Text(_isEditing ? 'Editar despesa' : 'Nova despesa'),
        leading: Tooltip(
          message: 'Voltar',
          child: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles/${widget.vehicle.id}/expenses');
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Contexto do veículo ──────────────────────────────────
                    // Lembrete passivo de qual carro está recebendo a despesa.
                    VehicleContextChip(vehicle: widget.vehicle),

                    // ── Scan CTA ─────────────────────────────────────────────
                    // Atalho opcional — o form manual continua disponível 100%
                    // (Regra de Ouro #3b). Disabled durante saving.
                    ScanCtaBanner(
                      onTap: _scan,
                      scanning: _scanning,
                    ),

                    // ── Seção 1: Quando e onde ───────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Quando e onde',
                      children: [
                        // Data — DatePickerField do DS (mesmo do fuel form).
                        DatePickerField(value: _date, onTap: _pickDate),

                        const SizedBox(height: AppSpacing.lg),

                        // Categoria — eyebrow + pílulas horizontais.
                        const _SectionFieldLabel('CATEGORIA'),
                        const SizedBox(height: AppSpacing.sm),
                        ExpenseCategoryPicker(
                          value: _category,
                          onChanged: (v) => setState(() => _category = v),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Descrição.
                        TextFormField(
                          controller: _descriptionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            hintText: 'Ex.: Troca de óleo',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              _validateRequired(v, fieldLabel: 'uma descrição'),
                        ),
                      ],
                    ),

                    // ── Seção 2: Valor e odômetro ────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Valor e odômetro',
                      children: [
                        // Valor — decimal pt-BR.
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(
                            labelText: r'Valor (R$)',
                            hintText: 'Ex.: 189,90',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              validateDecimalPositive(v, fieldLabel: 'o valor'),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Odômetro — opcional.
                        TextFormField(
                          controller: _odometerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Odômetro (km) — opcional',
                            hintText: 'Ex.: 45000',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: _validateOptionalOdometer,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Barra sticky de salvar ───────────────────────────────────────
            _SaveActionBar(
              onSave: _submit,
              saving: _saving || _scanning,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers de build
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

/// Barra sticky inferior: botão Salvar com surfaceRaised + hairline top.
class _SaveActionBar extends StatelessWidget {
  const _SaveActionBar({
    required this.onSave,
    required this.saving,
    required this.isEditing,
  });

  final VoidCallback onSave;
  final bool saving;
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
          onPressed: saving ? null : onSave,
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
              : Text(isEditing ? 'Salvar alterações' : 'Registrar despesa'),
        ),
      ),
    );
  }
}
