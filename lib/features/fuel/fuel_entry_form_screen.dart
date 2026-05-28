import 'dart:async';

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_entry_saver.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:autolog/features/fuel/station_brands.dart';
import 'package:autolog/features/fuel/widgets/date_picker_field.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/fuel/widgets/fuel_type_segmented.dart';
import 'package:autolog/features/fuel/widgets/full_tank_toggle.dart';
import 'package:autolog/features/fuel/widgets/inline_validation_chip.dart';
import 'package:autolog/features/fuel/widgets/scan_cta_banner.dart';
import 'package:autolog/features/fuel/widgets/scan_feedback_banners.dart';
import 'package:autolog/features/fuel/widgets/scan_source_sheet.dart';
import 'package:autolog/features/fuel/widgets/total_action_bar.dart';
import 'package:autolog/features/fuel/widgets/vehicle_context_chip.dart';
import 'package:autolog/features/scan/scan_controller.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de formulário de abastecimento — criar ou editar.
///
/// [initial] == null → modo criar ("Novo abastecimento").
/// [initial] != null → modo editar ("Editar abastecimento").
///
/// Redesenhada na Tranche B: compõe os widgets de design system (ScanCtaBanner,
/// FormSectionCard, VehicleContextChip, etc.) para o layout premium em dois
/// modos — manual (form organizado) e scan (banner animado + feedback pós-scan).
///
/// Sprint 2.3: tipos de combustível filtrados pelo veículo + cálculo 2→1 flexível.
class FuelEntryFormScreen extends ConsumerStatefulWidget {
  const FuelEntryFormScreen({super.key, required this.vehicle, this.initial});

  final Vehicle vehicle;
  final FuelEntry? initial;

  @override
  ConsumerState<FuelEntryFormScreen> createState() =>
      _FuelEntryFormScreenState();
}

class _FuelEntryFormScreenState extends ConsumerState<FuelEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _litersCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _totalCtrl;
  late FuelType _fuelType;
  late bool _fullTank;

  // Campos do posto (opcionais).
  late final TextEditingController _stationBrandCtrl;
  late final TextEditingController _stationNameCtrl;

  // Tipos de combustível filtrados pelo veículo.
  late final List<FuelType> _availableFuelTypes;

  // Fila dos dois campos tocados pelo usuário mais recentemente (tamanho máx. 2).
  // O campo que NÃO está nessa fila é o "auto-calculado".
  final List<FuelField> _lastTwoTouched = [];

  // Flag para evitar loop infinito: quando true, atualizações programáticas
  // dos controllers não disparam os listeners.
  bool _isUpdatingAuto = false;

  bool _saving = false;
  String? _validationError;
  bool _scannedFromCamera = false;

  Timer? _odometerDebounce;

  bool get _isEditing => widget.initial != null;

  // Campo que está sendo auto-calculado (o que NÃO está em _lastTwoTouched).
  FuelField? get _autoField {
    if (_lastTwoTouched.length < 2) return null;
    const all = FuelField.values;
    for (final f in all) {
      if (!_lastTwoTouched.contains(f)) return f;
    }
    return null;
  }

  // Total para exibição na TotalActionBar (derivado do controller).
  String get _totalDisplay {
    final raw = _totalCtrl.text.trim();
    if (raw.isEmpty) return '';
    try {
      final val = parseDecimalPtBr(raw);
      if (val <= Decimal.zero) return '';
      final formatted = double.parse(
        val.toString(),
      ).toStringAsFixed(2).replaceAll('.', ',');
      return 'R\$ $formatted';
    } on FormatException {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();

    // Tipos disponíveis para este veículo.
    _availableFuelTypes = availableFuelTypesFor(widget.vehicle.fuelType);

    final e = widget.initial;
    _date = e?.date ?? DateTime.now();
    _odometerCtrl = TextEditingController(
      text: e != null ? e.odometer.toString() : '',
    );
    _litersCtrl = TextEditingController(
      text: e != null ? e.liters.toString() : '',
    );
    _priceCtrl = TextEditingController(
      text: e != null ? e.pricePerLiter.toString() : '',
    );
    _totalCtrl = TextEditingController(
      text: e != null ? e.totalCost.toString() : '',
    );

    // Garante que o tipo inicial é compatível com o veículo.
    final initialFuelType = e?.fuelType ?? widget.vehicle.fuelType;
    _fuelType = _availableFuelTypes.contains(initialFuelType)
        ? initialFuelType
        : _availableFuelTypes.first;

    _fullTank = e?.fullTank ?? true;

    _stationBrandCtrl = TextEditingController(text: e?.stationBrand ?? '');
    _stationNameCtrl = TextEditingController(text: e?.stationName ?? '');

    // Em modo edição, os 3 campos estão preenchidos — nenhum é "auto" até o user tocar.
    // Sem necessidade de pré-popular _lastTwoTouched.

    _litersCtrl.addListener(() => _onFieldChanged(FuelField.liters));
    _priceCtrl.addListener(() => _onFieldChanged(FuelField.pricePerLiter));
    _totalCtrl.addListener(() => _onFieldChanged(FuelField.totalCost));
    _odometerCtrl.addListener(_onOdometerChanged);
  }

  @override
  void dispose() {
    _odometerDebounce?.cancel();
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _totalCtrl.dispose();
    _stationBrandCtrl.dispose();
    _stationNameCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Cálculo flexível 2→1
  // ---------------------------------------------------------------------------

  /// Mapeamento campo → controller correspondente.
  TextEditingController _ctrlFor(FuelField field) {
    switch (field) {
      case FuelField.liters:
        return _litersCtrl;
      case FuelField.pricePerLiter:
        return _priceCtrl;
      case FuelField.totalCost:
        return _totalCtrl;
    }
  }

  /// Lê o valor Decimal de um controller (null se vazio ou inválido).
  Decimal? _parseField(TextEditingController ctrl) {
    try {
      return parseDecimalPtBr(ctrl.text);
    } on FormatException {
      return null;
    }
  }

  /// Atualiza a fila _lastTwoTouched e recalcula o campo auto.
  void _onFieldChanged(FuelField field) {
    if (_isUpdatingAuto) return; // evita loop infinito

    // Atualiza a fila: remove o field se já estava, adiciona no fim.
    _lastTwoTouched.remove(field);

    final ctrl = _ctrlFor(field);
    // Só considera "touched" se o campo tem conteúdo.
    if (ctrl.text.isNotEmpty) {
      _lastTwoTouched.add(field);
      if (_lastTwoTouched.length > 2) {
        _lastTwoTouched.removeAt(0);
      }
    }

    // Monta o triplet com os valores atuais.
    final triplet = FuelTriplet(
      liters: _parseField(_litersCtrl),
      pricePerLiter: _parseField(_priceCtrl),
      totalCost: _parseField(_totalCtrl),
    );

    // Calcula o campo faltante.
    final result = computeMissingTriplet(triplet);

    // Atualiza o campo "auto" programaticamente sem disparar o listener.
    final auto = _autoField;
    if (auto != null) {
      final computed = switch (auto) {
        FuelField.liters => result.liters,
        FuelField.pricePerLiter => result.pricePerLiter,
        FuelField.totalCost => result.totalCost,
      };
      if (computed != null) {
        final autoCtrl = _ctrlFor(auto);
        final newText = computed.toString().replaceAll('.', ',');
        if (autoCtrl.text != newText) {
          _isUpdatingAuto = true;
          autoCtrl.text = newText;
          _isUpdatingAuto = false;
        }
      }
    }

    // Força rebuild para atualizar badge "auto" e totalDisplay na action bar.
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Validação bloqueante de odômetro (data ↔ odômetro) — Sprint 3.8
  // ---------------------------------------------------------------------------

  void _onOdometerChanged() {
    _odometerDebounce?.cancel();
    _odometerDebounce = Timer(const Duration(milliseconds: 600), () {
      _runValidation();
    });
  }

  Future<void> _runValidation() async {
    final raw = _odometerCtrl.text.trim();
    final candidate = int.tryParse(raw);
    if (candidate == null) {
      if (mounted) setState(() => _validationError = null);
      return;
    }

    try {
      final repo = ref.read(fuelEntryRepositoryProvider);
      final entries = await repo.listByVehicle(widget.vehicle.id);
      final error = validateOdometerForEntry(
        date: _date,
        odometer: candidate,
        initialOdometer: widget.vehicle.initialOdometer,
        existing: entries,
        excludeId: widget.initial?.id,
      );
      if (mounted) {
        setState(() => _validationError = error);
      }
    } catch (_) {
      // Falha silenciosa — libera o botão em caso de erro ao carregar entries.
      if (mounted) setState(() => _validationError = null);
    }
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
      // Dispara imediatamente (sem debounce) ao mudar a data.
      unawaited(_runValidation());
    }
  }

  // ---------------------------------------------------------------------------
  // Scan
  // ---------------------------------------------------------------------------

  Future<void> _scan() async {
    final origin = await showScanSourceSheet(context);

    if (origin == null) return;

    final receipt = await ref
        .read(scanControllerProvider.notifier)
        .scan(origin: origin);

    if (!mounted) return;

    final scanState = ref.read(scanControllerProvider);

    if (scanState is ScanQuotaExhausted) {
      showQuotaExhaustedBanner(
        context,
        onSeePremium: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Premium chega no Sprint 6')),
            );
          }
        },
      );
      return;
    }

    if (scanState is ScanError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanState.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (receipt == null) {
      // Cancelado silenciosamente.
      return;
    }

    // Pré-preenche os campos com os dados extraídos.
    // Usa vírgula como separador decimal (pt-BR), consistente com parseDecimalPtBr.
    setState(() {
      if (receipt.liters != null) {
        _litersCtrl.text = receipt.liters!.toString().replaceAll('.', ',');
      }
      if (receipt.pricePerLiter != null) {
        _priceCtrl.text = receipt.pricePerLiter!.toString().replaceAll(
          '.',
          ',',
        );
      }
      if (receipt.fuelType != null) {
        // Garante compatibilidade com o veículo.
        final scannedType = receipt.fuelType!;
        _fuelType = _availableFuelTypes.contains(scannedType)
            ? scannedType
            : _fuelType;
      }
      if (receipt.date != null) {
        _date = receipt.date!;
      }
      _scannedFromCamera = true;
    });

    // Exibe banner PT-BR solicitando revisão antes de salvar.
    if (mounted) {
      showScanSuccessBanner(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  /// Valida que pelo menos 2 dos 3 campos estão preenchidos e positivos.
  /// Retorna null se válido; mensagem de erro PT-BR se inválido.
  String? _validateTriplet() {
    final liters = _parseField(_litersCtrl);
    final price = _parseField(_priceCtrl);
    final total = _parseField(_totalCtrl);

    final filled = [
      liters,
      price,
      total,
    ].where((v) => v != null && v > Decimal.zero).length;
    if (filled < 2) {
      return 'Preencha ao menos 2 dos 3 campos: litros, preço/litro e total.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tripletError = _validateTriplet();
    if (tripletError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripletError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final saver = ref.read(fuelEntrySaverProvider);

      final odometer = int.parse(_odometerCtrl.text.trim());

      // Obtém os valores dos campos (null se não preenchido/inválido).
      Decimal? liters = _parseField(_litersCtrl);
      Decimal? price = _parseField(_priceCtrl);
      Decimal? total = _parseField(_totalCtrl);

      // Completa o campo faltante via computeMissingTriplet.
      final computed = computeMissingTriplet(
        FuelTriplet(liters: liters, pricePerLiter: price, totalCost: total),
      );
      liters = computed.liters ?? liters!;
      price = computed.pricePerLiter ?? price!;
      total = computed.totalCost ?? total ?? (liters * price);

      // Campos opcionais de posto (null quando vazio).
      final stationBrand = _stationBrandCtrl.text.trim().isEmpty
          ? null
          : _stationBrandCtrl.text.trim();
      final stationName = _stationNameCtrl.text.trim().isEmpty
          ? null
          : _stationNameCtrl.text.trim();

      if (_isEditing) {
        await saver.update(
          widget.initial!,
          date: _date,
          odometer: odometer,
          liters: liters,
          pricePerLiter: price,
          totalCost: total,
          fullTank: _fullTank,
          fuelType: _fuelType,
          stationName: stationName,
          stationBrand: stationBrand,
        );
      } else {
        await saver.create(
          vehicleId: widget.vehicle.id,
          date: _date,
          odometer: odometer,
          liters: liters,
          pricePerLiter: price,
          totalCost: total,
          fullTank: _fullTank,
          fuelType: _fuelType,
          source: _scannedFromCamera ? FuelSource.aiScan : FuelSource.manual,
          vehicle: widget.vehicle,
          stationName: stationName,
          stationBrand: stationBrand,
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vehicles/${widget.vehicle.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o abastecimento. Tente novamente.',
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
    final scanState = ref.watch(scanControllerProvider);
    final isScanning = scanState is ScanInProgress;
    final autoField = _autoField;

    // Label do campo de volume: "Volume (m³)" para GNV, "Litros" para outros.
    final isGnv = _fuelType == FuelType.gnv;
    final litersLabel = isGnv ? 'Volume (m³)' : 'Litros';
    final litersHint = isGnv ? 'Ex.: 12,500' : 'Ex.: 43,219';

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
        title: Text(_isEditing ? 'Editar abastecimento' : 'Novo abastecimento'),
        leading: Tooltip(
          message: 'Voltar',
          child: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles/${widget.vehicle.id}');
              }
            },
          ),
        ),
        // Scan icon na AppBar — redundante com o banner, mas conveniente.
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: 'Escanear cupom',
              onPressed: _scan,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable content — cresce até o limite; TotalActionBar fica sticky.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Contexto do veículo ──────────────────────────────────
                    VehicleContextChip(vehicle: widget.vehicle),

                    // ── CTA de scan ──────────────────────────────────────────
                    ScanCtaBanner(onTap: _scan, scanning: isScanning),

                    // ── Seção 1: Litros · Preço/litro · Total ───────────────
                    FormSectionCard(
                      eyebrow: 'Números do abastecimento',
                      children: [
                        // Litros / Volume (m³ para GNV)
                        _FieldWithAutoBadge(
                          isAuto: autoField == FuelField.liters,
                          child: TextFormField(
                            controller: _litersCtrl,
                            decoration: InputDecoration(
                              labelText: litersLabel,
                              hintText: litersHint,
                              helperText: isGnv
                                  ? 'GNV é cobrado em m³, não litros'
                                  : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              // Obrigatório apenas se for o único campo preenchível.
                              // A validação real do triplet é feita no _submit.
                              // Aqui só valida formato se houver conteúdo.
                              if (v != null && v.trim().isNotEmpty) {
                                return validateDecimalPositive(
                                  v,
                                  fieldLabel: litersLabel.toLowerCase(),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Preço por litro
                        _FieldWithAutoBadge(
                          isAuto: autoField == FuelField.pricePerLiter,
                          child: TextFormField(
                            controller: _priceCtrl,
                            decoration: const InputDecoration(
                              labelText: r'Preço por litro (R$)',
                              hintText: 'Ex.: 5,799',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                return validateDecimalPositive(
                                  v,
                                  fieldLabel: 'preço por litro',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Total — agora editável.
                        _FieldWithAutoBadge(
                          isAuto: autoField == FuelField.totalCost,
                          child: TextFormField(
                            controller: _totalCtrl,
                            decoration: const InputDecoration(
                              labelText: r'Total (R$)',
                              hintText: 'Ex.: 250,63',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                return validateDecimalPositive(
                                  v,
                                  fieldLabel: 'total',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── Seção 2: Odômetro · Data · Tanque · Combustível ─────
                    FormSectionCard(
                      eyebrow: 'Quando, onde, como',
                      children: [
                        // Odômetro
                        TextFormField(
                          controller: _odometerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Odômetro (km)',
                            hintText: 'Ex.: 45000',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: validateOdometerAtFueling,
                        ),

                        // Chip de erro de odômetro (validação cronológica).
                        InlineValidationChip(message: _validationError),

                        const SizedBox(height: AppSpacing.md),

                        // Data
                        DatePickerField(value: _date, onTap: _pickDate),

                        const SizedBox(height: AppSpacing.md),

                        // Tanque cheio / parcial
                        FullTankToggle(
                          value: _fullTank,
                          onChanged: (v) => setState(() => _fullTank = v),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Tipo de combustível — filtrado pelo veículo.
                        _FuelTypeSectionLabel(),
                        const SizedBox(height: AppSpacing.sm),
                        FuelTypeSegmented(
                          value: _fuelType,
                          onChanged: (v) => setState(() => _fuelType = v),
                          allowed: _availableFuelTypes,
                        ),
                      ],
                    ),

                    // ── Seção 3: Posto (opcional) ────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Posto (opcional)',
                      children: [
                        // Bandeira com autocomplete
                        Autocomplete<String>(
                          initialValue: TextEditingValue(
                            text: _stationBrandCtrl.text,
                          ),
                          optionsBuilder: (textEditingValue) {
                            final query = textEditingValue.text.toLowerCase();
                            if (query.isEmpty) return const [];
                            return brStationBrands.where(
                              (b) => b.toLowerCase().contains(query),
                            );
                          },
                          onSelected: (selection) {
                            _stationBrandCtrl.text = selection;
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Sincroniza estado interno do Autocomplete com nosso ctrl.
                            controller.addListener(() {
                              if (_stationBrandCtrl.text != controller.text) {
                                _stationBrandCtrl.text = controller.text;
                              }
                            });
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Bandeira',
                                hintText: 'Ex.: Shell',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Nome do posto
                        TextFormField(
                          controller: _stationNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome do posto',
                            hintText: 'Ex.: Posto Shell BR-101 km 87',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),

                    // Espaço extra no fim do scroll.
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Barra sticky: total + botão Salvar ──────────────────────────
            TotalActionBar(
              totalDisplay: _totalDisplay,
              onSave: _submit,
              saving: _saving,
              disabled: _validationError != null,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers de build inline
// ---------------------------------------------------------------------------

/// Label eyebrow "TIPO DE COMBUSTÍVEL" para posicionar acima do FuelTypeSegmented.
class _FuelTypeSectionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'TIPO DE COMBUSTÍVEL',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.inkSoft,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Envolve um campo com badge "auto" cinza discreto quando [isAuto] é true.
/// O badge aparece no canto superior direito do campo.
class _FieldWithAutoBadge extends StatelessWidget {
  const _FieldWithAutoBadge({required this.isAuto, required this.child});

  final bool isAuto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isAuto) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 8,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.surfaceRaised,
              borderRadius: AppRadius.allSm,
              border: Border.all(color: context.hairline, width: 1),
            ),
            child: Text(
              'auto',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.inkSoft,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
