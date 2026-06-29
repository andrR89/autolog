// Card de backup completo em Settings.
//
// Export: gera JSON com TODOS os dados do user (vehicles, fuel_entries,
// expenses, reminders, fines, insurances, user_profile) e abre share sheet.
//
// Import: file_picker → lê JSON → diálogo confirm com estatísticas
// (X novos, Y atualizados, Z mantidos) → aplica merge last-write-wins.

import 'dart:convert';
import 'dart:io';

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/features/backup/backup_models.dart';
import 'package:autolog/features/backup/backup_service.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.backup_outlined),
              title: Text('Backup completo'),
              subtitle: Text(
                'Exporta tudo (veículos, abastecimentos, despesas, '
                'lembretes, multas, apólices) em um único arquivo JSON. '
                'Útil pra trocar de celular ou ter um seguro.',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _exportAll,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Exportar tudo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _importFromFile,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Importar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;

    setState(() => _busy = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      final svc = ref.read(backupServiceProvider);
      final bundle = await svc.exportAll(userId);

      final json = const JsonEncoder.withIndent('  ').convert(bundle.toJson());
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/autolog_backup_$stamp.json');
      await file.writeAsString(json, flush: true);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'AutoLog — backup completo',
        sharePositionOrigin: origin,
      );

      if (result.status == ShareResultStatus.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Backup gerado: ${bundle.vehicles.length} veículos, '
              '${bundle.fuelEntries.length} abastecimentos, '
              '${bundle.expenses.length} despesas.',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFromFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        // user cancelou
        return;
      }

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ler o arquivo selecionado.'),
          ),
        );
        return;
      }

      final raw = utf8.decode(bytes);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final bundle = BackupBundle.fromJson(decoded);

      if (!mounted) return;
      final confirmed = await _confirmRestore(navigator.context, bundle);
      if (confirmed != true) return;

      final svc = ref.read(backupServiceProvider);
      final stats = await svc.importBundle(bundle);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restauração concluída: ${stats.toInsert} novos, '
            '${stats.toUpdate} atualizados, ${stats.toSkip} mantidos.',
          ),
        ),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmRestore(BuildContext context, BackupBundle b) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar restauração'),
        content: Text(
          'Vou aplicar este backup ao seu app:\n\n'
          '• ${b.vehicles.length} veículos\n'
          '• ${b.fuelEntries.length} abastecimentos\n'
          '• ${b.expenses.length} despesas\n'
          '• ${b.reminders.length} lembretes\n'
          '• ${b.fines.length} multas\n'
          '• ${b.insurances.length} apólices\n\n'
          'Dados locais mais novos NÃO serão sobrescritos. '
          'Itens já existentes só serão atualizados se o backup for mais '
          'recente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
}
