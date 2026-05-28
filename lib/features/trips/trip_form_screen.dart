import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/repositories/trip_repository.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Tela de formulário de viagem — criar ou editar.
///
/// [initial] == null → modo criar ("Nova viagem").
/// [initial] != null → modo editar ("Editar viagem").
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, required this.vehicle, this.initial});

  final Vehicle vehicle;
  final Trip? initial;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _startDate;
  late DateTime _endDate;

  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _startDate = t?.startDate ?? DateTime.now();
    _endDate = t?.endDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Se endDate ficou antes de startDate, ajusta.
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate end >= start (extra safety, datepicker already enforces).
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data de término deve ser igual ou posterior ao início.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(tripRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      if (_isEditing) {
        await repo.update(
          widget.initial!.copyWith(
            name: name,
            startDate: _startDate,
            endDate: _endDate,
            notes: notes,
          ),
        );
      } else {
        final now = DateTime.now().toUtc();
        await repo.create(
          Trip(
            id: const Uuid().v4(),
            vehicleId: widget.vehicle.id,
            name: name,
            startDate: _startDate,
            endDate: _endDate,
            notes: notes,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vehicles/${widget.vehicle.id}/trips');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a viagem. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

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
        title: Text(_isEditing ? 'Editar viagem' : 'Nova viagem'),
        leading: Tooltip(
          message: 'Voltar',
          child: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles/${widget.vehicle.id}/trips');
              }
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Nome ──────────────────────────────────────────────────
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome da viagem',
                        hintText: 'Ex.: Floripa, Trip pra serra',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o nome da viagem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Datas ─────────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Início',
                            value: dateFmt.format(_startDate),
                            onTap: _pickStartDate,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _DateField(
                            label: 'Término',
                            value: dateFmt.format(_endDate),
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Notas ─────────────────────────────────────────────────
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        hintText: 'Ex.: Viagem de férias em família',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Barra sticky de salvar ────────────────────────────────────────
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
                      : Text(_isEditing ? 'Salvar alterações' : 'Criar viagem'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: context.inkMuted,
          ),
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
