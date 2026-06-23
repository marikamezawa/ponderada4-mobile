import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant_id_response_model.dart';
import '../../providers/add_plant_provider.dart';

class IdentifyPlantScreen extends ConsumerWidget {
  const IdentifyPlantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        ref.watch(addPlantProvider).identification?.suggestions ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Sugestões de identificação')),
      body: suggestions.isEmpty
          ? const Center(child: Text('Nenhuma sugestão disponível.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _SuggestionTile(
                suggestion: suggestions[i],
                onTap: () => Navigator.of(context).pop(suggestions[i]),
              ),
            ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final PlantIdSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final confidence = (suggestion.probability * 100).toStringAsFixed(0);
    final isHigh = suggestion.probability >= 0.7;
    final isMid = suggestion.probability >= 0.3;
    final confColor =
        isHigh ? AppColors.primary : (isMid ? AppColors.warning : AppColors.error);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailOrIcon(imageUrl: suggestion.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.commonName ?? suggestion.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (suggestion.commonName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        suggestion.name,
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            fontSize: 12),
                      ),
                    ],
                    if (suggestion.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        suggestion.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$confidence%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: confColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailOrIcon extends StatelessWidget {
  final String? imageUrl;

  const _ThumbnailOrIcon({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.accent,
        child: const Icon(Icons.eco, color: AppColors.primary),
      );
}
