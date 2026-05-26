import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/remote/fipe_models.dart';
import 'package:autolog/data/remote/fipe_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre o sheet de busca FIPE e retorna [FipeVehicleDetails] quando o usuário
/// confirma, ou null se cancelar.
Future<FipeVehicleDetails?> showFipeSearchSheet(
  BuildContext context,
  VehicleType type,
) {
  return showModalBottomSheet<FipeVehicleDetails>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => _FipeSearchSheetContent(
        type: type,
        scrollController: controller,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Passos da busca
// ---------------------------------------------------------------------------

enum _Step { brand, model, year }

// ---------------------------------------------------------------------------
// Widget principal do sheet
// ---------------------------------------------------------------------------

class _FipeSearchSheetContent extends ConsumerStatefulWidget {
  const _FipeSearchSheetContent({
    required this.type,
    required this.scrollController,
  });

  final VehicleType type;
  final ScrollController scrollController;

  @override
  ConsumerState<_FipeSearchSheetContent> createState() =>
      _FipeSearchSheetContentState();
}

class _FipeSearchSheetContentState
    extends ConsumerState<_FipeSearchSheetContent>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.brand;

  // Seleções
  FipeBrand? _selectedBrand;
  FipeModel? _selectedModel;

  // Estado de cada passo
  List<FipeBrand> _brands = [];
  List<FipeModel> _models = [];
  List<FipeYear> _years = [];

  bool _loading = false;
  String? _error;

  // Busca textual
  final _searchCtrl = TextEditingController();
  String _query = '';

  late final AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _loadBrands();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Carregamento
  // -------------------------------------------------------------------------

  Future<void> _loadBrands() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(fipeRepositoryProvider);
      final brands = await repo.listBrands(widget.type);
      if (mounted) setState(() => _brands = brands);
    } on FipeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadModels(FipeBrand brand) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(fipeRepositoryProvider);
      final models = await repo.listModels(widget.type, brand.code);
      if (mounted) setState(() => _models = models);
    } on FipeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadYears(FipeModel model) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(fipeRepositoryProvider);
      final years = await repo.listYears(
        widget.type,
        _selectedBrand!.code,
        model.code,
      );
      if (mounted) setState(() => _years = years);
    } on FipeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectYear(FipeYear year) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(fipeRepositoryProvider);
      final details = await repo.getDetails(
        widget.type,
        _selectedBrand!.code,
        _selectedModel!.code,
        year.code,
      );
      if (mounted) Navigator.of(context).pop(details);
    } on FipeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Navegação entre passos
  // -------------------------------------------------------------------------

  Future<void> _advanceTo(_Step step) async {
    await _slideCtrl.reverse();
    if (mounted) {
      setState(() {
        _step = step;
        _query = '';
        _searchCtrl.clear();
      });
      await _slideCtrl.forward();
    }
  }

  Future<void> _onBrandTap(FipeBrand brand) async {
    _selectedBrand = brand;
    await _loadModels(brand);
    if (_error == null) await _advanceTo(_Step.model);
  }

  Future<void> _onModelTap(FipeModel model) async {
    _selectedModel = model;
    await _loadYears(model);
    if (_error == null) await _advanceTo(_Step.year);
  }

  Future<void> _goBack() async {
    await _slideCtrl.reverse();
    if (mounted) {
      setState(() {
        _query = '';
        _searchCtrl.clear();
        _error = null;
        if (_step == _Step.year) {
          _step = _Step.model;
        } else if (_step == _Step.model) {
          _step = _Step.brand;
        }
      });
      await _slideCtrl.forward();
    }
  }

  // -------------------------------------------------------------------------
  // Filtragem
  // -------------------------------------------------------------------------

  List<FipeBrand> get _filteredBrands {
    if (_query.isEmpty) return _brands;
    final q = _query.toLowerCase();
    return _brands
        .where((b) => b.name.toLowerCase().contains(q))
        .toList();
  }

  List<FipeModel> get _filteredModels {
    if (_query.isEmpty) return _models;
    final q = _query.toLowerCase();
    return _models
        .where((m) => m.name.toLowerCase().contains(q))
        .toList();
  }

  List<FipeYear> get _filteredYears {
    if (_query.isEmpty) return _years;
    final q = _query.toLowerCase();
    return _years
        .where((y) => y.name.toLowerCase().contains(q))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Alça de drag
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Breadcrumb
        _BreadcrumbBar(step: _step, onBack: _step != _Step.brand ? _goBack : null),

        const Divider(height: 1, color: AppColors.hairline),

        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: _stepHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),

        // Conteúdo
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  String get _stepHint {
    switch (_step) {
      case _Step.brand:
        return 'Buscar marca…';
      case _Step.model:
        return 'Buscar modelo…';
      case _Step.year:
        return 'Buscar ano…';
    }
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.inkSoft),
              const SizedBox(height: 12),
              Text(
                'Não conseguimos buscar agora',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _slideCtrl,
        child: _buildList(),
      ),
    );
  }

  void _retry() {
    switch (_step) {
      case _Step.brand:
        _loadBrands();
      case _Step.model:
        if (_selectedBrand != null) _loadModels(_selectedBrand!);
      case _Step.year:
        if (_selectedModel != null) _loadYears(_selectedModel!);
    }
    setState(() => _error = null);
  }

  Widget _buildList() {
    switch (_step) {
      case _Step.brand:
        final items = _filteredBrands;
        if (items.isEmpty && _query.isNotEmpty) return _emptyState();
        return ListView.builder(
          controller: widget.scrollController,
          itemCount: items.length,
          itemBuilder: (_, i) => _ItemTile(
            name: items[i].name,
            code: items[i].code,
            onTap: () => _onBrandTap(items[i]),
          ),
        );

      case _Step.model:
        final items = _filteredModels;
        if (items.isEmpty && _query.isNotEmpty) return _emptyState();
        return ListView.builder(
          controller: widget.scrollController,
          itemCount: items.length,
          itemBuilder: (_, i) => _ItemTile(
            name: items[i].name,
            code: items[i].code,
            onTap: () => _onModelTap(items[i]),
          ),
        );

      case _Step.year:
        final items = _filteredYears;
        if (items.isEmpty && _query.isNotEmpty) return _emptyState();
        return ListView.builder(
          controller: widget.scrollController,
          itemCount: items.length,
          itemBuilder: (_, i) => _ItemTile(
            name: items[i].name,
            code: items[i].code,
            onTap: () => _selectYear(items[i]),
          ),
        );
    }
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'Nenhum resultado para "$_query"',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb bar
// ---------------------------------------------------------------------------

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.step, this.onBack});

  final _Step step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: onBack,
              tooltip: 'Voltar',
            )
          else
            const SizedBox(width: 8),
          _BreadcrumbItem(
            label: 'Marca',
            active: step == _Step.brand,
            done: step != _Step.brand,
          ),
          const _BreadcrumbSep(),
          _BreadcrumbItem(
            label: 'Modelo',
            active: step == _Step.model,
            done: step == _Step.year,
          ),
          const _BreadcrumbSep(),
          _BreadcrumbItem(
            label: 'Ano',
            active: step == _Step.year,
            done: false,
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  const _BreadcrumbItem({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    Color color;
    FontWeight weight;
    if (active) {
      color = AppColors.brand;
      weight = FontWeight.w700;
    } else if (done) {
      color = AppColors.success;
      weight = FontWeight.w500;
    } else {
      color = AppColors.inkSoft;
      weight = FontWeight.w400;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (done)
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
        if (done) const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbSep extends StatelessWidget {
  const _BreadcrumbSep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
    );
  }
}

// ---------------------------------------------------------------------------
// Item de lista
// ---------------------------------------------------------------------------

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.name,
    required this.code,
    required this.onTap,
  });

  final String name;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              code,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
