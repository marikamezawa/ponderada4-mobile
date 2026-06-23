import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_helper.dart';
import '../../../domain/entities/care_log.dart';
import '../../providers/care_log_provider.dart';
import '../../widgets/care_badge.dart';

class CareLogScreen extends ConsumerStatefulWidget {
  final String plantId;

  const CareLogScreen({super.key, required this.plantId});

  @override
  ConsumerState<CareLogScreen> createState() => _CareLogScreenState();
}

class _CareLogScreenState extends ConsumerState<CareLogScreen> {
  CareType? _filter;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(careLogNotifierProvider(widget.plantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Cuidados'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(
            selected: _filter,
            onChanged: (t) => setState(() => _filter = t),
          ),
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (logs) {
          final filtered = _filter == null
              ? logs
              : logs.where((l) => l.careType == _filter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 64, color: AppColors.accent),
                  const SizedBox(height: 12),
                  Text(
                    _filter == null
                        ? 'Nenhum cuidado registrado ainda.'
                        : 'Nenhum registro de ${_filter!.label}.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) => _CareLogTile(log: filtered[i]),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final CareType? selected;
  final ValueChanged<CareType?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...CareType.values.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: t.label,
                  selected: selected == t,
                  onTap: () => onChanged(selected == t ? null : t),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _CareLogTile extends StatelessWidget {
  final CareLog log;

  const _CareLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareBadge(type: log.careType),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateHelper.formatWithTime(log.loggedAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (log.note != null && log.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(log.note!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
            Text(
              DateHelper.timeAgo(log.loggedAt),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

extension on CareType {
  String get label {
    switch (this) {
      case CareType.water:
        return 'Rega';
      case CareType.fertilize:
        return 'Adubação';
      case CareType.repot:
        return 'Transplante';
    }
  }
}
