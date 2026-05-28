import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/calendar/google_calendar_service.dart';
import 'package:autolog/features/settings/notif_prefs_providers.dart';
import 'package:autolog/features/settings/theme_mode_providers.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:autolog/features/whatsapp/whatsapp_service.dart';
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
          const SizedBox(height: 8),
          const _GoogleCalendarCard(),
          const SizedBox(height: 8),
          const _WhatsAppCard(),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Conectado'),
                    subtitle: Text(_email ?? 'Google Calendar'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

// ---------------------------------------------------------------------------
// _WhatsAppCard
// ---------------------------------------------------------------------------

/// Card de integração com bot WhatsApp via Twilio.
/// Com Mock ativo: toggle "Conectar" mostra a UX de conectado/desconectado.
/// Com serviço real configurado: gera código de pareamento e exibe instrução.
class _WhatsAppCard extends ConsumerStatefulWidget {
  const _WhatsAppCard();

  @override
  ConsumerState<_WhatsAppCard> createState() => _WhatsAppCardState();
}

class _WhatsAppCardState extends ConsumerState<_WhatsAppCard> {
  bool _loading = false;
  bool _paired = false;
  String? _phone;

  static const _twilioNumber = '+14155238886';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final svc = ref.read(whatsAppServiceProvider);
    final paired = await svc.isPaired();
    final phone = paired ? await svc.pairedPhoneNumber() : null;
    if (mounted) {
      setState(() {
        _paired = paired;
        _phone = phone;
      });
    }
  }

  Future<void> _generateCode() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(whatsAppServiceProvider);
      final code = await svc.generatePairingCode();
      if (mounted) {
        _showPairingDialog(code);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar código. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPairingDialog(String code) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conectar WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Envie a mensagem abaixo para o nosso número no WhatsApp:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AUTOLOG $code',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Número: $_twilioNumber',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'O código expira quando você gerar um novo.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadState();
            },
            child: const Text('Já enviei'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _unpair() async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(whatsAppServiceProvider);
      await svc.unpair();
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
                'WhatsApp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Registre abastecimentos enviando uma mensagem de texto para o bot.',
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
            else if (_paired)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Conectado'),
                    subtitle: Text(_phone ?? 'WhatsApp pareado'),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OutlinedButton.icon(
                      onPressed: _unpair,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Desconectar'),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ElevatedButton.icon(
                  onPressed: _generateCode,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Conectar WhatsApp'),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
