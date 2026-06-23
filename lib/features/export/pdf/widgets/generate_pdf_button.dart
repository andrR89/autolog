// lib/features/export/pdf/widgets/generate_pdf_button.dart
//
// Sprint 6.Y — PDF Histórico do Veículo.
//
// Botão que busca todos os dados do veículo via providers, gera o PDF e
// abre o compartilhamento nativo via Printing.sharePdf.
//
// Como inserir em VehicleDetailScreen (quando existir) ou VehiclesScreen:
//   Sugestão: no card de detalhes do veículo, dentro de uma seção "Ações" ou
//   como FloatingActionButton secundário em VehiclesScreen → detalhe.
//   Alternativamente, no ExportCard em SettingsScreen, abaixo do CSV.
//   Ver docs/specs/sprint-6.Y-pdf-historico.md para wireframe sugerido.
//
// Exemplo de uso:
//   GeneratePdfButton(vehicleId: vehicle.id)

import 'package:autolog/core/observability/analytics.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/features/export/pdf/vehicle_history_pdf_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Botão que gera e compartilha o PDF de histórico do veículo.
///
/// Insira passando o [vehicleId]. O widget busca tudo via providers,
/// exibe loading e trata erros com Snackbar PT-BR.
class GeneratePdfButton extends ConsumerStatefulWidget {
  const GeneratePdfButton({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<GeneratePdfButton> createState() => _GeneratePdfButtonState();
}

class _GeneratePdfButtonState extends ConsumerState<GeneratePdfButton> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final fuelRepo = ref.read(fuelEntryRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final reminderRepo = ref.read(reminderRepositoryProvider);
      final fipeRepo = ref.read(fipeHistoryRepositoryProvider);
      final pdfService = ref.read(vehicleHistoryPdfServiceProvider);

      // Busca paralela tipada de todos os dados.
      final vehicleFut = vehicleRepo.getById(widget.vehicleId);
      final fuelFut = fuelRepo.listByVehicle(widget.vehicleId);
      final expenseFut = expenseRepo.listByVehicle(widget.vehicleId);
      final reminderFut = reminderRepo.listByVehicle(widget.vehicleId);
      final fipeFut = fipeRepo.listByVehicle(widget.vehicleId);

      final vehicle = await vehicleFut;
      if (vehicle == null) {
        _showError('Veículo não encontrado.');
        return;
      }

      final fuelEntries = await fuelFut;
      final expenses = await expenseFut;
      final reminders = await reminderFut;
      final fipeHistory = await fipeFut;

      // Filtra só os lembretes concluídos (manutenção feita).
      final doneReminders = reminders.where((r) => r.isDone).toList();

      final bytes = await pdfService.generate(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        expenses: expenses,
        fipeHistory: fipeHistory.isEmpty ? null : fipeHistory,
        doneReminders: doneReminders,
      );

      if (!mounted) return;

      final nickname = vehicle.nickname.replaceAll(' ', '-').toLowerCase();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'historico-$nickname.pdf',
      );

      await track(AnalyticsEvent.exportPdfUsed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao gerar PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _generate,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: Text(_loading ? 'Gerando PDF...' : 'Histórico em PDF'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
