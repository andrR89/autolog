import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/settings/notif_prefs_providers.dart';
import 'package:autolog/features/settings/theme_mode_providers.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _AppearanceCard(
            userId: userId,
            repo: repo,
            current: current,
          ),
          const SizedBox(height: 8),
          _NotificationsCard(
            userId: userId,
            repo: repo,
            prefs: prefs,
          ),
        ],
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              subtitle:
                  const Text('Avisa quando vencer em menos de 30 dias'),
              value: prefs.fiscal,
              onChanged: (v) => repo.setNotifPref(userId, 'fiscal', v),
            ),
            SwitchListTile(
              title: const Text('Recap mensal pronto'),
              subtitle:
                  const Text('Notifica nos primeiros dias do mês com o resumo'),
              value: prefs.recapReady,
              onChanged: (v) => repo.setNotifPref(userId, 'recap_ready', v),
            ),
          ],
        ),
      ),
    );
  }
}
