// lib/features/export/widgets/export_card.dart
//
// Sprint 6.II — Export CSV / Backup.
//
// Widget ExportCard: card de exportação para inserir em SettingsScreen.
// Apresenta bottom sheet com seletor de veículo, período e tipo de dado.
// Usa share_plus para compartilhar o arquivo gerado.
//
// Como integrar em settings_screen.dart:
//   1. Adicionar import:
//        import 'package:autolog/features/export/widgets/export_card.dart';
//   2. No body → ListView → children, adicionar APÓS o _GoogleCalendarCard
//      (antes do último SizedBox(height: 8)):
//        const SizedBox(height: 8),
//        const ExportCard(),
//        const SizedBox(height: 8),

import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/export/csv_export_providers.dart';
import 'package:autolog/features/export/pdf/widgets/generate_pdf_button.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

// ---------------------------------------------------------------------------
// ExportCard — card público para settings_screen.dart
// ---------------------------------------------------------------------------

/// Card de exportação de dados para CSV.
///
/// Inserir em [SettingsScreen] após o _GoogleCalendarCard.
class ExportCard extends ConsumerWidget {
  const ExportCard({super.key});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ExportSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Exportar dados',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Exporte abastecimentos e despesas como planilha CSV.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () => _openSheet(context),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Exportar dados'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ExportSheet — bottom sheet interno
// ---------------------------------------------------------------------------

enum _PeriodFilter { all, thisYear, thisMonth, custom }

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  Vehicle? _selectedVehicle;
  _PeriodFilter _period = _PeriodFilter.all;
  DateTimeRange? _customRange;
  bool _loading = false;

  // -------------------------------------------------------------------------
  // Helpers de período
  // -------------------------------------------------------------------------

  (DateTime? from, DateTime? to) get _dateRange {
    final now = DateTime.now();
    switch (_period) {
      case _PeriodFilter.all:
        return (null, null);
      case _PeriodFilter.thisYear:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      case _PeriodFilter.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case _PeriodFilter.custom:
        return (_customRange?.start, _customRange?.end);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      locale: const Locale('pt', 'BR'),
    );
    if (range != null && mounted) {
      setState(() {
        _customRange = range;
        _period = _PeriodFilter.custom;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Export actions
  // -------------------------------------------------------------------------

  Future<void> _export(_ExportType type) async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      _showError('Selecione um veículo antes de exportar.');
      return;
    }

    // Capturar messenger antes de qualquer await — depois de awaits o
    // BottomSheet pode estar desmontado e ScaffoldMessenger.of(context)
    // fica inalcançável (root cause do CSV "silencioso" em iOS 26).
    final messenger = ScaffoldMessenger.of(context);

    // sharePositionOrigin defensivo: iPhone grandes em iOS 26 podem rotear o
    // UIActivityViewController via popoverPresentationController e exigir
    // sourceRect — sem isso o share volta com erro silencioso.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;

    setState(() => _loading = true);
    try {
      final svc = ref.read(csvExportServiceProvider);
      final (from, to) = _dateRange;

      final String path;
      switch (type) {
        case _ExportType.fuel:
          path = await svc.exportFuelEntries(vehicle.id, from: from, to: to);
        case _ExportType.expenses:
          path = await svc.exportExpenses(vehicle.id, from: from, to: to);
        case _ExportType.all:
          path = await svc.exportAll(vehicle.id, from: from, to: to);
      }

      final result = await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv')],
        subject: 'AutoLog — dados exportados',
        sharePositionOrigin: origin,
      );

      switch (result.status) {
        case ShareResultStatus.success:
          messenger.showSnackBar(
            const SnackBar(content: Text('Arquivo exportado com sucesso.')),
          );
        case ShareResultStatus.dismissed:
          // Usuário fechou sem compartilhar — não polui com erro.
          break;
        case ShareResultStatus.unavailable:
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                'Compartilhamento indisponível neste dispositivo.',
              ),
              backgroundColor: Colors.red[700],
            ),
          );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar arquivo: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Exportar dados',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),

          // Seletor de veículo
          Text(
            'Veículo',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          vehiclesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro ao carregar veículos: $e'),
            data: (vehicles) {
              // Seleciona o primeiro se nenhum selecionado ainda.
              if (_selectedVehicle == null && vehicles.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedVehicle = vehicles.first);
                  }
                });
              }
              return DropdownButtonFormField<Vehicle>(
                initialValue: vehicles.contains(_selectedVehicle)
                    ? _selectedVehicle
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                hint: const Text('Selecione o veículo'),
                items: vehicles
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        // nickname é non-nullable; make/model podem ser null.
                        child: Text(
                          v.nickname,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedVehicle = v),
              );
            },
          ),

          const SizedBox(height: 20),

          // Seletor de período
          Text(
            'Período',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _PeriodChip(
                label: 'Todo',
                selected: _period == _PeriodFilter.all,
                onTap: () => setState(() => _period = _PeriodFilter.all),
              ),
              _PeriodChip(
                label: 'Este ano',
                selected: _period == _PeriodFilter.thisYear,
                onTap: () => setState(() => _period = _PeriodFilter.thisYear),
              ),
              _PeriodChip(
                label: 'Este mês',
                selected: _period == _PeriodFilter.thisMonth,
                onTap: () => setState(() => _period = _PeriodFilter.thisMonth),
              ),
              _PeriodChip(
                label: _customRange != null
                    ? '${_fmtShort(_customRange!.start)} – ${_fmtShort(_customRange!.end)}'
                    : 'Personalizado',
                selected: _period == _PeriodFilter.custom,
                onTap: _pickCustomRange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botões de exportação
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _ExportButton(
              label: 'Abastecimentos',
              icon: Icons.local_gas_station_outlined,
              onPressed: () => _export(_ExportType.fuel),
            ),
            const SizedBox(height: 8),
            _ExportButton(
              label: 'Despesas',
              icon: Icons.receipt_long_outlined,
              onPressed: () => _export(_ExportType.expenses),
            ),
            const SizedBox(height: 8),
            _ExportButton(
              label: 'Tudo',
              icon: Icons.download_outlined,
              onPressed: () => _export(_ExportType.all),
              primary: true,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // PDF "Histórico do veículo" (Sprint 6.Y) — pro veículo selecionado.
            if (_selectedVehicle != null)
              GeneratePdfButton(vehicleId: _selectedVehicle!.id),
          ],
        ],
      ),
    );
  }

  String _fmtShort(DateTime d) => '${d.day}/${d.month}';
}

// ---------------------------------------------------------------------------
// Helpers de UI
// ---------------------------------------------------------------------------

enum _ExportType { fuel, expenses, all }

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    );
  }
}
