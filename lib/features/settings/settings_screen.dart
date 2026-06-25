import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/auth/account_deletion/widgets/delete_account_section.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/backup/widgets/backup_card.dart';
import 'package:autolog/features/calendar/google_calendar_service.dart';
import 'package:autolog/features/export/widgets/export_card.dart';
import 'package:autolog/features/premium/entitlements.dart';
import 'package:autolog/features/settings/locale_providers.dart';
import 'package:autolog/features/settings/notif_prefs_providers.dart';
import 'package:autolog/features/settings/theme_mode_providers.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:autolog/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final repo = ref.watch(userSettingsRepositoryProvider);

    // Usa provider GLOBAL — NÃO criar inline em build (descartava state).
    // Bug 27/05/2026: provider inline fazia o radio nunca refletir a
    // gravação e o tema voltar pra system ao sair.
    final themeModeAsync = ref.watch(themeModeEnumProvider);
    final current = themeModeAsync.valueOrNull ?? ThemeModeEnum.system;

    // Provider GLOBAL de prefs de notificação — não criar inline em build.
    final notifPrefsAsync = ref.watch(notifPrefsProvider);
    final prefs =
        notifPrefsAsync.valueOrNull ?? const NotificationPreferences();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const _PremiumCard(),
          const SizedBox(height: 8),
          _AppearanceCard(userId: userId, repo: repo, current: current),
          const SizedBox(height: 8),
          const _LanguageCard(),
          const SizedBox(height: 8),
          _NotificationsCard(userId: userId, repo: repo, prefs: prefs),
          const SizedBox(height: 8),
          const _GoogleCalendarCard(),
          const SizedBox(height: 8),
          const ExportCard(),
          const SizedBox(height: 8),
          const BackupCard(),
          const SizedBox(height: 8),
          const _SignOutCard(),
          const SizedBox(height: 8),
          const DeleteAccountSection(),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            const _SentryTestCard(),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Botão de teste do Sentry. Só renderiza em debug — usuário final
/// nunca vê. Dispara uma exception sintética e captura via Sentry.captureException.
class _SentryTestCard extends StatelessWidget {
  const _SentryTestCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      child: ListTile(
        leading: const Icon(Icons.bug_report, color: Colors.amber),
        title: const Text('Disparar erro de teste (debug)'),
        subtitle: const Text(
          'Envia uma exception sintética pro Sentry. Só aparece em '
          'debug builds.',
        ),
        onTap: () async {
          try {
            throw Exception(
              'AutoLog test event — Sentry handshake from device',
            );
          } catch (e, st) {
            await Sentry.captureException(e, stackTrace: st);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Erro de teste enviado. Olha o dashboard do Sentry.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _PremiumCard extends ConsumerWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      return Card(
        color: AppColors.success.withValues(alpha: 0.10),
        child: ListTile(
          leading: const Icon(
            Icons.workspace_premium,
            color: AppColors.success,
          ),
          title: Text(l10n.premiumActive),
          subtitle: Text(l10n.premiumActiveSubtitle),
        ),
      );
    }
    return Card(
      color: AppColors.brand,
      child: ListTile(
        leading: const Icon(
          Icons.workspace_premium,
          color: AppColors.accent,
        ),
        title: Text(
          l10n.premiumGoCta,
          style: const TextStyle(
            color: AppColors.brandInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          l10n.premiumGoSubtitle,
          style: TextStyle(color: AppColors.brandInk.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.brandInk),
        onTap: () => context.push('/paywall'),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(localeProvider);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.translate),
        title: Text(l10n.settingsLanguageLabel),
        subtitle: Text(
          selected == null
              ? l10n.settingsLanguageSystem
              : localeDisplayName(selected),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showPicker(context, ref, selected),
      ),
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    WidgetRef ref,
    Locale? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<Locale?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.settingsLanguageSystem),
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop<Locale?>(null),
              ),
              for (final locale in supportedLocales)
                ListTile(
                  title: Text(localeDisplayName(locale)),
                  trailing: current?.languageCode == locale.languageCode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(locale),
                ),
            ],
          ),
        );
      },
    );
    // Sentinel: usuário fechou sem escolher → showModalBottomSheet retorna
    // null nesse caso e no "padrão do sistema" (também null). Como a
    // diferença não importa pra função, aplicamos sempre.
    await ref.read(localeProvider.notifier).setLocale(picked);
  }
}

class _SignOutCard extends ConsumerWidget {
  const _SignOutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l10n.settingsSignOut),
        subtitle: Text(l10n.settingsSignOutSubtitle),
        onTap: () async {
          try {
            await ref.read(authServiceProvider).signOut();
          } catch (_) {
            // Estado local já foi limpo — falha de rede não bloqueia logout.
          }
        },
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.userId,
    required this.repo,
    required this.current,
  });

  final String userId;
  final UserSettingsRepository repo;
  final ThemeModeEnum current;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Aparência',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            RadioGroup<ThemeModeEnum>(
              groupValue: current,
              onChanged: (value) {
                if (value != null) repo.setThemeMode(userId, value);
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeModeEnum>(
                    title: Text('Automático (sistema)'),
                    value: ThemeModeEnum.system,
                  ),
                  RadioListTile<ThemeModeEnum>(
                    title: Text('Claro'),
                    value: ThemeModeEnum.light,
                  ),
                  RadioListTile<ThemeModeEnum>(
                    title: Text('Escuro'),
                    value: ThemeModeEnum.dark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.userId,
    required this.repo,
    required this.prefs,
  });

  final String userId;
  final UserSettingsRepository repo;
  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Notificações',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SwitchListTile(
              title: const Text('Consumo piorando'),
              subtitle: const Text('Avisa quando o consumo cair mais de 10%'),
              value: prefs.consumptionDrop,
              onChanged: (v) =>
                  repo.setNotifPref(userId, 'consumption_drop', v),
            ),
            SwitchListTile(
              title: const Text('CNH próxima do vencimento'),
              subtitle: const Text('Lembrete 7–30 dias antes do vencimento'),
              value: prefs.cnh,
              onChanged: (v) => repo.setNotifPref(userId, 'cnh', v),
            ),
            SwitchListTile(
              title: const Text('IPVA / Licenciamento próximo'),
              subtitle: const Text('Avisa quando vencer em menos de 30 dias'),
              value: prefs.fiscal,
              onChanged: (v) => repo.setNotifPref(userId, 'fiscal', v),
            ),
            SwitchListTile(
              title: const Text('Recap mensal pronto'),
              subtitle: const Text(
                'Notifica nos primeiros dias do mês com o resumo',
              ),
              value: prefs.recapReady,
              onChanged: (v) => repo.setNotifPref(userId, 'recap_ready', v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GoogleCalendarCard
// ---------------------------------------------------------------------------

/// Card de integração com Google Calendar.
/// Com Mock ativo: toggle "Conectar" mostra a UX de conectado/desconectado.
/// Com OAuth real configurado: dispara o fluxo de autenticação do Google.
class _GoogleCalendarCard extends ConsumerStatefulWidget {
  const _GoogleCalendarCard();

  @override
  ConsumerState<_GoogleCalendarCard> createState() =>
      _GoogleCalendarCardState();
}

class _GoogleCalendarCardState extends ConsumerState<_GoogleCalendarCard> {
  bool _loading = false;
  bool _connected = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final svc = ref.read(googleCalendarServiceProvider);
    final connected = await svc.isConnected();
    final email = connected ? await svc.connectedEmail() : null;
    if (mounted) {
      setState(() {
        _connected = connected;
        _email = email;
      });
    }
  }

  Future<void> _connect() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(googleCalendarServiceProvider);
      await svc.connect();
      await _loadState();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(googleCalendarServiceProvider);
      await svc.disconnect();
      await _loadState();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Google Calendar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Lembretes criados aqui aparecem no seu Google Calendar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_connected)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: const Text('Conectado'),
                    subtitle: Text(_email ?? 'Google Calendar'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Desconectar'),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ElevatedButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Conectar Google Calendar'),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
