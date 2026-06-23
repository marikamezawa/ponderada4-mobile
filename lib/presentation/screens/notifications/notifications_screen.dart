import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_helper.dart';
import '../../providers/notification_provider.dart';
import '../../providers/plant_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(careRemindersProvider);
    final enabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de notificações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar lembretes',
            onPressed: () => ref.read(plantListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (reminders) => RefreshIndicator(
          onRefresh: () => ref.read(plantListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(
                enabled: enabled,
                isDesktop: _isDesktop,
                onChanged: (value) => ref
                    .read(notificationsEnabledProvider.notifier)
                    .toggle(value),
              ),
              const SizedBox(height: 20),
              if (reminders.isEmpty)
                const _EmptyState()
              else
                _ReminderSections(reminders: reminders),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool enabled;
  final bool isDesktop;
  final ValueChanged<bool> onChanged;

  const _StatusCard({
    required this.enabled,
    required this.isDesktop,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: enabled
          ? AppColors.accent.withValues(alpha: 0.35)
          : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              secondary: Icon(
                enabled
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                enabled ? 'Lembretes ativados' : 'Lembretes desativados',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Rega e adubação das plantas cadastradas'),
            ),
            if (isDesktop) ...[
              const Divider(),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.computer, size: 19, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo de demonstração no computador: os lembretes são '
                      'exibidos nesta central. No Android e iOS, o app também '
                      'agenda notificações no sistema.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderSections extends StatelessWidget {
  final List<CareReminder> reminders;

  const _ReminderSections({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = reminders.where((item) => item.isDueAt(now)).toList();
    final upcoming = reminders.where((item) => !item.isDueAt(now)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (due.isNotEmpty) ...[
          _SectionTitle(label: 'Precisam de atenção', count: due.length),
          const SizedBox(height: 8),
          ...due.map((item) => _ReminderCard(reminder: item, isDue: true)),
          const SizedBox(height: 20),
        ],
        _SectionTitle(label: 'Próximos lembretes', count: upcoming.length),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const Text(
            'Nenhum lembrete futuro.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...upcoming.map(
            (item) => _ReminderCard(reminder: item, isDue: false),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;

  const _SectionTitle({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label ($count)',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final CareReminder reminder;
  final bool isDue;

  const _ReminderCard({required this.reminder, required this.isDue});

  @override
  Widget build(BuildContext context) {
    final isWater = reminder.type == CareReminderType.water;
    final color = isDue ? AppColors.error : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.plantDetailPath(reminder.plantId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  isWater ? Icons.water_drop_outlined : Icons.grass_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isDue
                          ? 'Pendente desde ${DateHelper.formatDisplay(reminder.scheduledAt)}'
                          : 'Agendada para ${DateHelper.formatDisplay(reminder.scheduledAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none,
            size: 72,
            color: AppColors.accent,
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum lembrete agendado',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre uma planta para criar lembretes de rega e adubação.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.addPlant),
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar planta'),
          ),
        ],
      ),
    );
  }
}
