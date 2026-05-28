// Tela de chat com o assistente IA baseado no histórico do veículo.
//
// Estados:
//   - empty (sem mensagens): CTA com chips de sugestão.
//   - com mensagens: ListView com bubbles user (direita) e assistant (esquerda).
//   - enviando: botão desabilitado, sem spinner inline.
//   - QuotaExhaustedException: MaterialBanner de cota esgotada.
//   - ScanException: SnackBar de erro.
//
// Fluxo _send:
//   1. Append user msg otimista.
//   2. Chama chatService.ask com os últimos 5 turns.
//   3. Append assistant msg em sucesso.
//   4. Erros tratados por tipo.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/chat/chat_message.dart';
import 'package:autolog/features/chat/chat_message_repository.dart';
import 'package:autolog/features/chat/chat_service.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de chat com o assistente IA do AutoLog.
///
/// Acesso: `/vehicles/:vehicleId/insights/chat`.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _quotaExhausted = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    final repo = ref.read(chatMessageRepositoryProvider);
    final svc = ref.read(chatServiceProvider);

    final now = DateTime.now().toUtc();
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      role: ChatRole.user,
      content: text,
      createdAt: now,
    );

    _textController.clear();
    setState(() => _sending = true);

    // Append user msg otimista
    await repo.append(userMsg);

    // Busca histórico recente (últimos 5 turns para contexto)
    final history = await repo.listByVehicle(widget.vehicle.id);
    final recentHistory = history.length > 1
        ? history
              .sublist(0, history.length - 1)
              .reversed
              .take(5)
              .toList()
              .reversed
              .toList()
        : <ChatMessage>[];

    try {
      final answer = await svc.ask(
        vehicleId: widget.vehicle.id,
        userMessage: text,
        recentHistory: recentHistory,
      );

      final assistantMsg = ChatMessage(
        id: const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        role: ChatRole.assistant,
        content: answer.content,
        createdAt: DateTime.now().toUtc(),
      );
      await repo.append(assistantMsg);
    } on QuotaExhaustedException {
      setState(() => _quotaExhausted = true);
    } on ScanException {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Algo deu errado. Tente de novo.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text(
          'Todas as mensagens desta conversa serão apagadas. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surfaceRaised,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(chatMessageRepositoryProvider)
          .clearVehicle(widget.vehicle.id);
      setState(() => _quotaExhausted = false);
    }
  }

  void _prefillSuggestion(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pergunte ao histórico'),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
        titleTextStyle: AppTypography.body(
          18,
          weight: FontWeight.w600,
          color: AppColors.brandInk,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.brandInk),
            onSelected: (value) {
              if (value == 'clear') _confirmClear();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Limpar conversa'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quota banner
          if (_quotaExhausted)
            MaterialBanner(
              backgroundColor: AppColors.warningSoft,
              content: Text(
                'Cota de chat esgotada — vire premium pra ilimitado.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
              ),
              leading: const Icon(Icons.info_outline, color: AppColors.warning),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _quotaExhausted = false),
                  child: const Text('Fechar'),
                ),
              ],
            ),

          // Message list
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Erro ao carregar mensagens.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return _EmptyState(onSuggestionTap: _prefillSuggestion);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) => _ChatBubble(message: msgs[i]),
                );
              },
            ),
          ),

          // Input area
          _InputBar(
            controller: _textController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state com sugestões
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestionTap});

  final void Function(String) onSuggestionTap;

  static const _suggestions = [
    'Quanto gastei esse mês?',
    'Quando vence meu IPVA?',
    'Qual meu posto preferido?',
    'Meu consumo está piorando?',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.surfaceSunken,
                  borderRadius: AppRadius.allLg,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: context.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pergunte algo:',
                style: AppTypography.display(
                  22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'O assistente usa seu histórico de abastecimentos e despesas para responder.',
                style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () => onSuggestionTap(s),
                        backgroundColor: context.surfaceSunken,
                        labelStyle: textTheme.bodySmall?.copyWith(
                          color: context.ink,
                        ),
                        side: BorderSide(color: context.hairline),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat bubble
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isUser ? AppColors.brandSoft : context.surfaceRaised,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: isUser
                        ? const Radius.circular(AppRadius.md)
                        : const Radius.circular(AppRadius.sm),
                    bottomRight: isUser
                        ? const Radius.circular(AppRadius.sm)
                        : const Radius.circular(AppRadius.md),
                  ),
                  border: isUser ? null : Border.all(color: context.hairline),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  message.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isUser ? AppColors.brandInk : context.ink,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _timeFormat.format(message.createdAt.toLocal()),
                style: textTheme.labelSmall?.copyWith(color: context.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de input
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceRaised,
          border: Border(top: BorderSide(color: context.hairline)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Faça uma pergunta...',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: context.inkSoft),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: AppColors.brand),
                  ),
                  filled: true,
                  fillColor: context.surfaceSunken,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: sending ? null : (_) => onSend(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (ctx, value, _) {
                final canSend = value.text.trim().isNotEmpty && !sending;
                return IconButton(
                  onPressed: canSend ? onSend : null,
                  icon: const Icon(Icons.send),
                  color: AppColors.brand,
                  disabledColor: ctx.inkSoft,
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? AppColors.brand.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
