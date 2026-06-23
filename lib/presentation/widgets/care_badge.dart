import 'package:flutter/material.dart';
import '../../domain/entities/care_log.dart';
import '../../core/constants/app_colors.dart';

class CareBadge extends StatelessWidget {
  final CareType type;

  const CareBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (type) {
      CareType.water => ('Rega', Colors.blue, Icons.water_drop),
      CareType.fertilize => ('Adubação', AppColors.primary, Icons.eco),
      CareType.repot => ('Transplante', AppColors.warning, Icons.move_up),
    };

    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color, width: 0.5),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
