import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/widgets/form_section_card.dart';
import 'package:autolog/features/fuel/widgets/fuel_type_segmented.dart';
import 'package:autolog/features/scan/crlv_scan_service.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/widgets/crlv_source_sheet.dart';
import 'package:autolog/features/vehicles/vehicle_form_validators.dart';
import 'package:autolog/features/vehicles/vehicle_saver.dart';
import 'package:autolog/features/vehicles/vehicle_specs_inference_service.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:autolog/features/vehicles/widgets/fipe_search_sheet.dart';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:uuid/uuid.dart';

/// Tela de formulário de veículo — usada tanto para criar quanto para editar.
///
/// [initial] == null → modo criar ("Novo veículo").
/// [initial] != null → modo editar ("Editar veículo").
///
/// Redesenhada na Tranche C: compõe os widgets de design system (FormSectionCard,
/// FuelTypeSegmented, TotalActionBar pattern) para vocabulário visual unificado
/// com o formulário de abastecimento.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.initial});

  final Vehicle? initial;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _ufCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _engineCcCtrl;
  late final TextEditingController _tankLCtrl;
  late final TextEditingController _horsepowerCtrl;
  late final TextEditingController _renavamCtrl;
  late final TextEditingController _chassiCtrl;

  late FuelType _fuelType;
  late VehicleType _vehicleType;
  bool _saving = false;
  bool _crlvScanning = false;
  bool _inferring = false;

  // Campos FIPE — preenchidos pelo FipeSearchSheet
  String? _fipeCode;
  Decimal? _fipeValue;
  String? _fipeReferenceMonth;

  // Highlight verde nos campos preenchidos pelo FIPE
  bool _fipeHighlight = false;

  /// ID temporário usado no modo criar para associar snapshots FIPE ao veículo
  /// antes de ele ser persistido. Quando o veículo for salvo com este mesmo id
  /// (client-generated UUID), os snapshots já estarão linkados.
  late final String _draftId;

  bool get _isEditing => widget.initial != null;

  Future<void> _openFipeSearch() async {
    final result = await showFipeSearchSheet(context, _vehicleType);
    if (result == null || !mounted) return;
    await _applyFipeResult(result);
  }

  Future<void> _applyFipeResult(FipeVehicleDetails result) async {
    setState(() {
      _makeCtrl.text = result.brand;
      _modelCtrl.text = result.model;
      _yearCtrl.text = result.modelYear.toString();
      _fipeCode = result.fipeCode;
      _fipeValue = result.priceValue;
      _fipeReferenceMonth = result.referenceMonth;

      // Preenche combustível se ainda não selecionado (padrão é flex)
      // Mapeamento defensivo: só mapeia os óbvios
      final fuelMap = {
        'gasolina': FuelType.gasolina,
        'álcool': FuelType.etanol,
        'etanol': FuelType.etanol,
        'diesel': FuelType.diesel,
        'flex': FuelType.flex,
      };
      final mapped = fuelMap[result.fuel.toLowerCase()];
      if (mapped != null) _fuelType = mapped;

      _fipeHighlight = true;
    });

    // Salva snapshot FIPE automaticamente (idempotente por PK composta).
    // No modo criar, usa _draftId — o veículo será salvo com o mesmo id.
    // Erros são silenciosos: não bloquear o preenchimento do formulário.
    try {
      await ref.read(fipeHistoryRepositoryProvider).saveSnapshot(
        vehicleId: _draftId,
        month: result.referenceMonth,
        value: result.priceValue,
      );
    } catch (_) {
      // Falha ao salvar snapshot não deve interromper o fluxo do usuário.
    }

    // Animação: highlight verde fading em 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _fipeHighlight = false);
    });
  }

  Future<void> _openCrlvScan() async {
    // Captura o ScaffoldMessenger ANTES de qualquer await — evita usar
    // context dentro de callbacks (ex: TextButton.onPressed do banner) que
    // podem disparar depois do State já ter sido desmontado.
    // Regressão 26/05/2026: app crashava quando user tocava "Fechar" no
    // MaterialBanner após sair da tela. (use_build_context_synchronously)
    final messenger = ScaffoldMessenger.of(context);

    final source = await showCrlvSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() => _crlvScanning = true);

    try {
      final Uint8List bytes;
      final String mimeType;

      if (source == CrlvSource.file) {
        // Seleção de arquivo via file_picker.
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        if (file.bytes == null) return;
        bytes = file.bytes!;
        final ext = (file.extension ?? '').toLowerCase();
        mimeType = switch (ext) {
          'pdf' => 'application/pdf',
          'png' => 'image/png',
          _ => 'image/jpeg',
        };
      } else {
        // Câmera ou galeria via image_picker (com redimensionamento 1280/q80).
        final pickerSource = source == CrlvSource.camera
            ? img_picker.ImageSource.camera
            : img_picker.ImageSource.gallery;
        final xfile = await img_picker.ImagePicker().pickImage(
          source: pickerSource,
          maxWidth: 1280,
          imageQuality: 80,
        );
        if (xfile == null) return; // cancelado
        bytes = await xfile.readAsBytes();
        mimeType = 'image/jpeg';
      }

      final scanService = ref.read(crlvScanServiceProvider);
      final scanned = await scanService.scan(bytes, mimeType: mimeType);

      if (!mounted) return;

      setState(() {
        if (scanned.plate != null) _plateCtrl.text = scanned.plate!;
        if (scanned.make != null) _makeCtrl.text = scanned.make!;
        if (scanned.model != null) _modelCtrl.text = scanned.model!;
        if (scanned.year != null) _yearCtrl.text = scanned.year.toString();
        if (scanned.color != null) _colorCtrl.text = scanned.color!;
        if (scanned.fuelType != null) _fuelType = scanned.fuelType!;
        if (scanned.renavam != null) _renavamCtrl.text = scanned.renavam!;
        if (scanned.chassi != null) _chassiCtrl.text = scanned.chassi!;
      });
    } on QuotaExhaustedException {
      messenger.showMaterialBanner(
        MaterialBanner(
          content: const Text(
            'Cota mensal de scans esgotada — vire premium ou preencha manualmente.',
          ),
          actions: [
            TextButton(
              // Usa `messenger` capturado, não `context` — seguro mesmo
              // se o usuário sair da tela antes de tocar "Fechar".
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } on ScanException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não conseguimos ler o CRLV. Tente outra foto/arquivo ou preencha manualmente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não conseguimos ler o CRLV. Tente outra foto/arquivo ou preencha manualmente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _crlvScanning = false);
    }
  }

  Future<void> _onInferSpecs() async {
    final year = int.tryParse(_yearCtrl.text.trim());
    if (year == null) return; // guard — chip só aparece quando ano é válido

    setState(() => _inferring = true);
    try {
      final result = await ref.read(vehicleSpecsInferenceServiceProvider).infer(
        type: _vehicleType,
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: year,
      );

      if (!mounted) return;

      // Preenche somente campos não-null e que o usuário não preencheu ainda.
      bool anyFilled = false;
      setState(() {
        if (result.engineDisplacementCc != null && _engineCcCtrl.text.isEmpty) {
          _engineCcCtrl.text = result.engineDisplacementCc.toString();
          anyFilled = true;
        }
        if (result.tankCapacityL != null && _tankLCtrl.text.isEmpty) {
          _tankLCtrl.text = result.tankCapacityL.toString();
          anyFilled = true;
        }
        if (result.horsepower != null && _horsepowerCtrl.text.isEmpty) {
          _horsepowerCtrl.text = result.horsepower.toString();
          anyFilled = true;
        }
      });

      if (anyFilled && mounted) {
        final message = result.confidence >= 0.7
            ? 'Confira os dados sugeridos'
            : 'Sugestão com baixa confiança — revise antes de salvar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on QuotaExhaustedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text(
              'Cota mensal de scans esgotada — preencha manualmente ou vire premium.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } on ScanException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não conseguimos inferir agora. Tente de novo ou preencha manualmente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _inferring = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // UUID gerado antecipadamente para o modo criar — permite salvar snapshots
    // FIPE antes do veículo ser persistido. No modo editar, usa o id existente.
    _draftId = widget.initial?.id ?? const Uuid().v4();
    final v = widget.initial;
    _nicknameCtrl = TextEditingController(text: v?.nickname ?? '');
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(
      text: v?.year != null ? v!.year.toString() : '',
    );
    _ufCtrl = TextEditingController(text: v?.uf ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _plateCtrl = TextEditingController(text: v?.plate ?? '');
    _odometerCtrl = TextEditingController(
      text: v != null ? v.initialOdometer.toString() : '',
    );
    _engineCcCtrl = TextEditingController(
      text: v?.engineDisplacementCc?.toString() ?? '',
    );
    _tankLCtrl = TextEditingController(
      text: v?.tankCapacityL?.toString() ?? '',
    );
    _horsepowerCtrl = TextEditingController(
      text: v?.horsepower?.toString() ?? '',
    );
    _renavamCtrl = TextEditingController(text: v?.renavam ?? '');
    _chassiCtrl = TextEditingController(text: v?.chassi ?? '');
    _fuelType = v?.fuelType ?? FuelType.flex;
    _vehicleType = v?.type ?? VehicleType.carro;
    _fipeCode = v?.fipeCode;
    _fipeValue = v?.fipeValue;
    _fipeReferenceMonth = v?.fipeReferenceMonth;

    // Rebuild when make/model/year change so _TechnicalSpecsSection
    // receives updated values and shows/hides the IA chip correctly.
    _makeCtrl.addListener(_onIdentityChanged);
    _modelCtrl.addListener(_onIdentityChanged);
    _yearCtrl.addListener(_onIdentityChanged);
  }

  void _onIdentityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _ufCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _odometerCtrl.dispose();
    _engineCcCtrl.dispose();
    _tankLCtrl.dispose();
    _horsepowerCtrl.dispose();
    _renavamCtrl.dispose();
    _chassiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final saver = ref.read(vehicleSaverProvider);
      final nickname = _nicknameCtrl.text.trim();
      final make = _makeCtrl.text.trim().isEmpty ? null : _makeCtrl.text.trim();
      final model = _modelCtrl.text.trim().isEmpty
          ? null
          : _modelCtrl.text.trim();
      final year = parseYearOptional(_yearCtrl.text.trim());
      final uf = normalizeUf(_ufCtrl.text);
      final color = _colorCtrl.text.trim().isEmpty
          ? null
          : _colorCtrl.text.trim();
      final plate = _plateCtrl.text.trim().isEmpty
          ? null
          : _plateCtrl.text.trim();
      final renavam = _renavamCtrl.text.trim().isEmpty
          ? null
          : _renavamCtrl.text.trim();
      final chassi = _chassiCtrl.text.trim().isEmpty
          ? null
          : _chassiCtrl.text.trim().toUpperCase();
      final odometer = parseOdometer(_odometerCtrl.text.trim());
      final engineCc = parseEngineCcOptional(_engineCcCtrl.text);
      final tankL = parseTankLOptional(_tankLCtrl.text);
      final hp = parseHorsepowerOptional(_horsepowerCtrl.text);

      if (_isEditing) {
        await saver.update(
          widget.initial!,
          nickname: nickname,
          make: make,
          model: model,
          year: year,
          uf: uf,
          color: color,
          type: _vehicleType,
          engineDisplacementCc: engineCc,
          tankCapacityL: tankL,
          horsepower: hp,
          fipeCode: _fipeCode,
          fipeValue: _fipeValue,
          fipeReferenceMonth: _fipeReferenceMonth,
          plate: plate,
          renavam: renavam,
          chassi: chassi,
          fuelType: _fuelType,
          initialOdometer: odometer,
        );
      } else {
        final userId = ref.read(currentUserIdProvider);
        await saver.create(
          id: _draftId,
          userId: userId,
          nickname: nickname,
          make: make,
          model: model,
          year: year,
          uf: uf,
          color: color,
          type: _vehicleType,
          engineDisplacementCc: engineCc,
          tankCapacityL: tankL,
          horsepower: hp,
          fipeCode: _fipeCode,
          fipeValue: _fipeValue,
          fipeReferenceMonth: _fipeReferenceMonth,
          plate: plate,
          renavam: renavam,
          chassi: chassi,
          fuelType: _fuelType,
          initialOdometer: odometer,
        );
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vehicles');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o veículo. Tente novamente.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.hairline,
        // Status bar com ícones escuros — fundo é o surface off-white.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Text(_isEditing ? 'Editar veículo' : 'Novo veículo'),
        leading: Tooltip(
          message: 'Voltar',
          child: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles');
              }
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable content — cresce até o limite; botão fica sticky no fundo.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Seletor de tipo carro/moto ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _VehicleTypeChip(
                              icon: Icons.directions_car,
                              label: 'Carro',
                              selected: _vehicleType == VehicleType.carro,
                              onTap: () => setState(
                                () => _vehicleType = VehicleType.carro,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _VehicleTypeChip(
                              icon: Icons.two_wheeler,
                              label: 'Moto',
                              selected: _vehicleType == VehicleType.moto,
                              onTap: () => setState(
                                () => _vehicleType = VehicleType.moto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Espaçamento entre seletor de tipo e botões de busca/scan.
                    const SizedBox(height: AppSpacing.md),
                    // ── Botões "Buscar na FIPE" + "Escanear CRLV" ───────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: FilledButton.icon(
                        onPressed: _openFipeSearch,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.brand,
                          foregroundColor: AppColors.brandInk,
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Buscar na FIPE'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: FilledButton.icon(
                        onPressed: _crlvScanning ? null : _openCrlvScan,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.surfaceRaised,
                          foregroundColor: AppColors.ink,
                        ),
                        icon: _crlvScanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.document_scanner, size: 18),
                        label: const Text('Escanear CRLV'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Seção 1: Identificação ───────────────────────────────
                    FormSectionCard(
                      eyebrow: 'Identificação',
                      children: [
                        // Apelido — campo obrigatório e mais importante.
                        TextFormField(
                          controller: _nicknameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apelido',
                            hintText: 'Ex.: Meu Civic',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: validateNickname,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Marca e modelo em row — quando cabem lado a lado
                        // economizam vertical estate e criam par lógico.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                  begin: Colors.transparent,
                                  end: _fipeHighlight
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                                duration: const Duration(milliseconds: 800),
                                builder: (_, color, child) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.allMd,
                                    color: color,
                                  ),
                                  child: child,
                                ),
                                child: TextFormField(
                                  controller: _makeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Marca',
                                    hintText: 'Ex.: Honda',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                  begin: Colors.transparent,
                                  end: _fipeHighlight
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                                duration: const Duration(milliseconds: 800),
                                builder: (_, color, child) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.allMd,
                                    color: color,
                                  ),
                                  child: child,
                                ),
                                child: TextFormField(
                                  controller: _modelCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Modelo',
                                    hintText: 'Ex.: Civic',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Placa — ocupa linha inteira; formatação all-caps.
                        TextFormField(
                          controller: _plateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Placa (opcional)',
                            hintText: 'Ex.: ABC1D23',
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // RENAVAM — numérico, 9-11 dígitos.
                        TextFormField(
                          controller: _renavamCtrl,
                          decoration: const InputDecoration(
                            labelText: 'RENAVAM (opcional)',
                            hintText: '11 dígitos',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: validateRenavam,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Chassi — alfanumérico, 17 caracteres.
                        TextFormField(
                          controller: _chassiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Chassi (opcional)',
                            hintText: '17 caracteres',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 17,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[a-zA-Z0-9]'),
                            ),
                            _UpperCaseTextFormatter(),
                          ],
                          validator: validateChassi,
                        ),
                      ],
                    ),

                    // ── Seção 1b: Detalhes do veículo ───────────────────────
                    FormSectionCard(
                      eyebrow: 'Detalhes do veículo',
                      children: [
                        // Ano e UF em row — relacionados (ano/modelo e UF de emplacamento).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Ano (opcional)',
                                  hintText: 'Ex.: 2018',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: validateYear,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _ufCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'UF (opcional)',
                                  hintText: 'Ex.: SP',
                                  // Esconde counter "2/2" — campo curto já é
                                  // óbvio pelo tamanho. (regressão 26/05/2026)
                                  counterText: '',
                                ),
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 2,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[a-zA-Z]'),
                                  ),
                                  _UpperCaseTextFormatter(),
                                ],
                                validator: validateUf,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Cor — linha inteira, texto livre.
                        TextFormField(
                          controller: _colorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cor (opcional)',
                            hintText: 'Ex.: preto',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),

                    // ── Seção 1c: Detalhes técnicos (colapsável) ────────────
                    _TechnicalSpecsSection(
                      vehicleType: _vehicleType,
                      make: _makeCtrl.text.trim(),
                      model: _modelCtrl.text.trim(),
                      year: int.tryParse(_yearCtrl.text.trim()),
                      engineCcCtrl: _engineCcCtrl,
                      tankLCtrl: _tankLCtrl,
                      horsepowerCtrl: _horsepowerCtrl,
                      inferring: _inferring,
                      onInferSpecs: _onInferSpecs,
                      initiallyExpanded: _isEditing &&
                          (widget.initial?.engineDisplacementCc != null ||
                              widget.initial?.tankCapacityL != null ||
                              widget.initial?.horsepower != null),
                    ),

                    // ── Seção 2: Combustível e odômetro ─────────────────────
                    FormSectionCard(
                      eyebrow: 'Combustível e odômetro',
                      children: [
                        // Label eyebrow interno para o segmentado.
                        const _SectionFieldLabel('TIPO DE COMBUSTÍVEL'),
                        const SizedBox(height: AppSpacing.sm),
                        FuelTypeSegmented(
                          value: _fuelType,
                          onChanged: (v) => setState(() => _fuelType = v),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Odômetro inicial — digit-only.
                        TextFormField(
                          controller: _odometerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Odômetro inicial (km)',
                            hintText: 'Ex.: 45000',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: validateInitialOdometer,
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
              saving: _saving,
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

/// Formata input para maiúsculas em tempo real (para campo de UF).
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Eyebrow label para campo interno de seção (ex.: "TIPO DE COMBUSTÍVEL").
class _SectionFieldLabel extends StatelessWidget {
  const _SectionFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.inkSoft,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Barra sticky inferior: botão Salvar com surfaceRaised + hairline top.
///
/// Espelha o padrão de TotalActionBar do fuel form, mas sem o bloco de total
/// (veículo não tem total calculado).
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
              : Text(isEditing ? 'Salvar alterações' : 'Adicionar veículo'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sprint 6.H — widgets novos
// ---------------------------------------------------------------------------

/// Chip de seleção de tipo de veículo (carro / moto).
class _VehicleTypeChip extends StatelessWidget {
  const _VehicleTypeChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.brandInk : AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.brandInk : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seção colapsável de detalhes técnicos (cilindrada, tanque, potência).
///
/// Sprint 6.L: aceita [make], [model], [year] do formulário pai para mostrar
/// o chip "Preencher com IA" quando as condições estão satisfeitas.
class _TechnicalSpecsSection extends StatefulWidget {
  const _TechnicalSpecsSection({
    required this.vehicleType,
    required this.make,
    required this.model,
    required this.year,
    required this.engineCcCtrl,
    required this.tankLCtrl,
    required this.horsepowerCtrl,
    required this.inferring,
    required this.onInferSpecs,
    required this.initiallyExpanded,
  });

  final VehicleType vehicleType;
  final String make;
  final String model;
  final int? year;
  final TextEditingController engineCcCtrl;
  final TextEditingController tankLCtrl;
  final TextEditingController horsepowerCtrl;
  final bool inferring;
  final VoidCallback onInferSpecs;
  final bool initiallyExpanded;

  @override
  State<_TechnicalSpecsSection> createState() => _TechnicalSpecsSectionState();
}

class _TechnicalSpecsSectionState extends State<_TechnicalSpecsSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    // Rebuild when any of the 3 technical fields change so the chip appears/
    // disappears as the user fills or clears them.
    widget.engineCcCtrl.addListener(_onTechFieldChanged);
    widget.tankLCtrl.addListener(_onTechFieldChanged);
    widget.horsepowerCtrl.addListener(_onTechFieldChanged);
  }

  @override
  void dispose() {
    widget.engineCcCtrl.removeListener(_onTechFieldChanged);
    widget.tankLCtrl.removeListener(_onTechFieldChanged);
    widget.horsepowerCtrl.removeListener(_onTechFieldChanged);
    super.dispose();
  }

  void _onTechFieldChanged() {
    if (mounted) setState(() {});
  }

  /// Whether the chip should be shown.
  ///
  /// Conditions:
  /// - make, model, year all provided by the user.
  /// - At least one of the 3 technical fields is still empty.
  bool get _showAiChip {
    return widget.make.isNotEmpty &&
        widget.model.isNotEmpty &&
        widget.year != null &&
        (widget.engineCcCtrl.text.isEmpty ||
            widget.tankLCtrl.text.isEmpty ||
            widget.horsepowerCtrl.text.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final engineLabel = widget.vehicleType == VehicleType.moto
        ? 'Cilindrada (cc)'
        : 'Cilindrada (cc) — ex.: 1600 para 1.6L';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.hairline),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.allMd,
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            title: Text(
              'Detalhes técnicos (opcional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            // Top padding > sm é necessário porque o ClipRRect ao redor do
            // ExpansionTile clipa o label flutuante do 1º TextField — sm
            // (8px) não cobre o overflow do label do Material 3, md (12px)
            // resolve sem deixar gap exagerado. (regressão 26/05/2026)
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Chip "Preencher com IA" (Sprint 6.L) ───────────────────
              // Visível quando make+model+year preenchidos E ao menos 1 campo
              // técnico vazio. Desabilitado enquanto a inferência está rodando.
              if (_showAiChip) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: widget.inferring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Preencher com IA'),
                    onPressed: widget.inferring ? null : widget.onInferSpecs,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Cilindrada
              TextFormField(
                controller: widget.engineCcCtrl,
                decoration: InputDecoration(labelText: engineLabel),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validateEngineCc,
              ),
              const SizedBox(height: AppSpacing.md),
              // Tanque
              TextFormField(
                controller: widget.tankLCtrl,
                decoration: const InputDecoration(
                  labelText: 'Capacidade do tanque (L)',
                  hintText: 'Ex.: 47,0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: validateTankL,
              ),
              const SizedBox(height: AppSpacing.md),
              // Potência
              TextFormField(
                controller: widget.horsepowerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Potência (cv)',
                  hintText: 'Ex.: 130',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validateHorsepower,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
