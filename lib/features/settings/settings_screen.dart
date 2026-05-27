import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final repo = ref.watch(userSettingsRepositoryProvider);

    final themeModeAsync = ref.watch(
      StreamProvider<ThemeModeEnum>(
        (ref) => repo.watchThemeMode(userId),
      ),
    );

    final current = themeModeAsync.valueOrNull ?? ThemeModeEnum.system;

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
