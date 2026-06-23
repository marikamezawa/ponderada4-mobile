import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_log_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/plant_provider.dart';

final _totalCareLogsProvider = FutureProvider<int>((ref) async {
  final user = await ref.watch(authNotifierProvider.future);
  if (user == null) return 0;
  return ref.read(careLogRepositoryProvider).countByUser(user.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final plantsAsync = ref.watch(plantListProvider);
    final careCountAsync = ref.watch(_totalCareLogsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.go(AppRoutes.login),
            );
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _AvatarSection(name: user.name, email: user.email),
              const SizedBox(height: 32),
              _StatsRow(
                plantCount: plantsAsync.valueOrNull?.length ?? 0,
                careCount: careCountAsync.valueOrNull ?? 0,
              ),
              const SizedBox(height: 32),
              _SettingsSection(
                notificationsEnabled: notificationsEnabled,
                onNotificationsChanged: (v) =>
                    ref.read(notificationsEnabledProvider.notifier).toggle(v),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _AvatarSection extends StatelessWidget {
  final String name;
  final String email;

  const _AvatarSection({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int plantCount;
  final int careCount;

  const _StatsRow({required this.plantCount, required this.careCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(value: plantCount, label: 'Plantas'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(value: careCount, label: 'Cuidados'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  const _SettingsSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: notificationsEnabled,
        onChanged: onNotificationsChanged,
        activeThumbColor: AppColors.primary,
        title: const Text('Notificações de cuidados'),
        subtitle: Text(
          notificationsEnabled ? 'Lembretes ativos' : 'Lembretes desativados',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        secondary: Icon(
          notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off_outlined,
          color: notificationsEnabled
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
