import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../domain/entities/plant.dart';
import 'plant_image.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto com menu ⋮ sobreposto
            Stack(
              children: [
                PlantImage(
                  url: plant.photoUrl,
                  height: 120,
                  width: double.infinity,
                ),
                if (onDelete != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'delete') _confirmDelete(context);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                                SizedBox(width: 8),
                                Text('Apagar planta',
                                    style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Informações
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plant.scientificName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _WaterBadge(plant: plant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar planta'),
        content: Text(
            'Deseja apagar "${plant.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }
}

class _WaterBadge extends StatelessWidget {
  final Plant plant;
  const _WaterBadge({required this.plant});

  @override
  Widget build(BuildContext context) {
    final overdue = plant.isWateringOverdue;
    final daysUntil = DateHelper.daysUntil(plant.nextWateringDate);
    final color = overdue
        ? AppColors.error
        : daysUntil <= 1
            ? AppColors.warning
            : AppColors.primaryLight;
    final label = overdue
        ? '💧 Regar agora!'
        : daysUntil == 0
            ? '💧 Regar hoje'
            : '💧 Em ${daysUntil}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
