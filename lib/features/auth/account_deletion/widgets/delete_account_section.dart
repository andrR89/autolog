// lib/features/auth/account_deletion/widgets/delete_account_section.dart
//
// Sprint 7.3 — LGPD: seção de exclusão de conta para SettingsScreen.
//
// UX de dois passos:
//   1. AlertDialog com lista do que será apagado + botão "Cancelar" em destaque
//   2. Usuário digita "EXCLUIR" para liberar o botão final
//
// Integração em settings_screen.dart — ver snippet no relatório final.

import 'package:autolog/features/auth/account_deletion/account_deletion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Constante de confirmação
// ---------------------------------------------------------------------------

/// Palavra de confirmação que o usuário deve digitar para liberar a deleção.
const _kConfirmationWord = 'EXCLUIR';

// ---------------------------------------------------------------------------
// Widget público
// ---------------------------------------------------------------------------

/// Card vermelho discreto que dispara o fluxo de exclusão de conta (LGPD).
///
/// Inserir no final do ListView de [SettingsScreen], após o [ExportCard].
class DeleteAccountSection extends ConsumerStatefulWidget {
  const DeleteAccountSection({super.key});

  @override
  ConsumerState<DeleteAccountSection> createState() =>
      _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends ConsumerState<DeleteAccountSection> {
  bool _loading = false;

  Future<void> _onDeleteTapped() async {
    // Abre o diálogo de confirmação em dois passos
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ConfirmDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final service = ref.read(accountDeletionServiceProvider);
      await service.deleteAccount();
      // Após deletar, o supabase.auth.onAuthStateChange emite null e o router
      // redireciona automaticamente para /login. Não navegamos manualmente
      // aqui para evitar race condition com o provider de auth.
    } on AccountDeletionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível excluir a conta. Tente novamente.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // Borda vermelha discreta para sinalizar zona destrutiva
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delete_forever_outlined,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Excluir conta',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Apaga permanentemente sua conta e todos os dados '
              '(veículos, abastecimentos, lembretes). '
              'Isso não pode ser desfeito.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else
              OutlinedButton.icon(
                onPressed: _onDeleteTapped,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  'Excluir minha conta',
                  style: TextStyle(color: colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo de confirmação em dois passos
// ---------------------------------------------------------------------------

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  /// 0 = primeira etapa (lista do que vai ser apagado)
  /// 1 = segunda etapa (digitar "EXCLUIR")
  int _step = 0;

  final _controller = TextEditingController();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isConfirmed =
          _controller.text.trim().toUpperCase() == _kConfirmationWord;
      if (isConfirmed != _confirmed) {
        setState(() => _confirmed = isConfirmed);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _step == 0 ? _buildStep1() : _buildStep2();
  }

  Widget _buildStep1() {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      // Explícito pra dark-aware (DialogTheme global tava sendo override por
      // surfaceTint do M3 — bug homolog 04/06, dialog vinha branco no dark).
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 8),
          const Text('Excluir conta'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Os seguintes dados serão apagados permanentemente:'),
          const SizedBox(height: 12),
          ..._dataPoints.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Esta ação é irreversível.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        // Cancelar em destaque (ação mais segura)
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: Text('Continuar', style: TextStyle(color: colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      // Idem step 1 — fix dark mode.
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      title: const Text('Confirmação final'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Para confirmar, digite '),
                TextSpan(
                  text: _kConfirmationWord,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: colorScheme.error,
                  ),
                ),
                const TextSpan(text: ' no campo abaixo:'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Digite $_kConfirmationWord pra confirmar',
              hintText: _kConfirmationWord,
              border: const OutlineInputBorder(),
              errorText: _controller.text.isNotEmpty && !_confirmed
                  ? 'Digite exatamente "$_kConfirmationWord"'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            'Excluir definitivamente',
            style: TextStyle(
              color: _confirmed ? colorScheme.error : colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dados exibidos na lista de confirmação
// ---------------------------------------------------------------------------

const _dataPoints = [
  'Sua conta e credenciais de acesso',
  'Todos os veículos cadastrados',
  'Histórico completo de abastecimentos',
  'Despesas, multas e seguros',
  'Lembretes e alertas',
  'Documentos pessoais (CNH)',
  'Histórico de análises e chat IA',
];
