import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/repositories/vehicle_member_repository.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/models/vehicle_member.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/vehicles/share_vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Provider para stream de membros
// ---------------------------------------------------------------------------

final _membersProvider =
    StreamProvider.family<List<VehicleMember>, String>((ref, vehicleId) {
      final repo = ref.watch(vehicleMemberRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

// ---------------------------------------------------------------------------
// Tela
// ---------------------------------------------------------------------------

/// Tela de compartilhamento de veículo.
///
/// Permite ao dono adicionar membros por email e ver/remover membros atuais.
class ShareVehicleScreen extends ConsumerStatefulWidget {
  const ShareVehicleScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<ShareVehicleScreen> createState() => _ShareVehicleScreenState();
}

class _ShareVehicleScreenState extends ConsumerState<ShareVehicleScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailCtrl.text.trim();

    setState(() => _loading = true);
    try {
      final service = ref.read(shareVehicleServiceProvider);
      final memberUserId = await service.shareWith(
        vehicleId: widget.vehicle.id,
        memberEmail: email,
      );

      // Persiste localmente para exibição imediata (sem aguardar sync).
      final repo = ref.read(vehicleMemberRepositoryProvider);
      await repo.upsert(
        VehicleMember(
          vehicleId: widget.vehicle.id,
          userId: memberUserId,
          role: 'member',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      if (mounted) {
        _emailCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membro adicionado com sucesso!')),
        );
      }
    } on ShareEmailNotFoundException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email não encontrado. Peça para a pessoa criar uma conta.'),
          ),
        );
      }
    } on ScanException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não conseguimos adicionar. Verifique sua conexão e tente novamente.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não conseguimos adicionar. Verifique sua conexão e tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeMember(VehicleMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text(
          'Remover o acesso de ${_truncateId(member.userId)} a este veículo?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(vehicleMemberRepositoryProvider);
      await repo.remove(member.vehicleId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membro removido.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover membro.')),
        );
      }
    }
  }

  String _truncateId(String userId) {
    if (userId.length <= 12) return userId;
    return '${userId.substring(0, 8)}...${userId.substring(userId.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_membersProvider(widget.vehicle.id));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: context.ink,
          tooltip: 'Voltar',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vehicles/${widget.vehicle.id}');
            }
          },
        ),
        title: Text(
          'Compartilhar veículo',
          style: textTheme.titleLarge?.copyWith(color: context.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            widget.vehicle.nickname,
            style: textTheme.headlineSmall?.copyWith(
              color: context.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Quem você adicionar verá e poderá editar este veículo, '
            'abastecimentos, despesas e lembretes.',
            style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Formulário de adição ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.hairline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adicionar por email',
                    style: textTheme.titleMedium?.copyWith(
                      color: context.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'email@exemplo.com',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: context.inkSoft,
                      ),
                      filled: true,
                      fillColor: context.surfaceSunken,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o email';
                      }
                      final email = v.trim();
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: AppColors.brandInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandInk,
                              ),
                            )
                          : const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Lista de membros atuais ──────────────────────────────────
          Text(
            'MEMBROS ATUAIS',
            style: textTheme.labelSmall?.copyWith(
              color: context.inkMuted,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          membersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Text(
              'Erro ao carregar membros.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
            data: (members) {
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  child: Text(
                    'Nenhum membro adicionado ainda.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.inkSoft,
                    ),
                  ),
                );
              }
              return Column(
                children: members
                    .map((m) => _MemberTile(
                          member: m,
                          onRemove: () => _removeMember(m),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de membro
// ---------------------------------------------------------------------------

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onRemove});

  final VehicleMember member;
  final VoidCallback onRemove;

  String _truncate(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.hairline),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.surfaceSunken,
          child: Icon(Icons.person_outline, color: context.inkMuted),
        ),
        title: Text(
          _truncate(member.userId),
          style: textTheme.bodyMedium?.copyWith(color: context.ink),
        ),
        subtitle: Text(
          member.role == 'owner' ? 'Proprietário' : 'Membro',
          style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
          tooltip: 'Remover membro',
          onPressed: onRemove,
        ),
      ),
    );
  }
}
