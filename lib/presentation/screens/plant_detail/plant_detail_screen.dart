import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/share_service.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../domain/entities/care_log.dart';
import '../../../domain/entities/plant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_log_provider.dart';
import '../../providers/growth_log_provider.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/care_badge.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/plant_image.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    final logsAsync = ref.watch(careLogNotifierProvider(plantId));

    return plantAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (plant) => _PlantDetailContent(plant: plant, logsAsync: logsAsync),
    );
  }
}

class _PlantDetailContent extends ConsumerStatefulWidget {
  final Plant plant;
  final AsyncValue<List<CareLog>> logsAsync;

  const _PlantDetailContent({required this.plant, required this.logsAsync});

  @override
  ConsumerState<_PlantDetailContent> createState() =>
      _PlantDetailContentState();
}

class _PlantDetailContentState extends ConsumerState<_PlantDetailContent> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return LoadingOverlay(
      isLoading: _sharing,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _PlantAppBar(plant: plant, onShare: _share, onDelete: _delete),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PlantInfoSection(plant: plant),
                  const SizedBox(height: 20),
                  _CareChips(plant: plant),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showRegisterCareModal(context, plant),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(AppStrings.registerCare),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _registerGrowthPhoto(plant),
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 18,
                          ),
                          label: const Text('Registrar evolução'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '${AppRoutes.growthHistoryPath(plant.id)}?name=${Uri.encodeComponent(plant.name)}',
                          ),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text('Ver evolução 📸'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (plant.careTips != null) ...[
                    const SizedBox(height: 20),
                    _CareTipsSection(tips: plant.careTips!),
                  ],
                  const SizedBox(height: 24),
                  _RecentCareLogs(logsAsync: widget.logsAsync),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    final plant = widget.plant;
    setState(() => _sharing = true);
    try {
      await ShareService().sharePlant(
        name: plant.name,
        scientificName: plant.scientificName,
        nextWateringDate: DateHelper.formatDisplay(plant.nextWateringDate),
        photoUrl: plant.photoUrl,
      );
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.deletePlant),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(plantListProvider.notifier).removePlant(widget.plant.id);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    }
  }

  Future<void> _showRegisterCareModal(BuildContext context, Plant plant) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RegisterCareModal(plant: plant),
    );
  }

  Future<void> _registerGrowthPhoto(Plant plant) async {
    final file = await pickPlantImage(context);
    if (file == null || !mounted) return;

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _GrowthNoteModal(),
    );

    if (!mounted) return;

    try {
      await ref
          .read(growthLogProvider(plant.id).notifier)
          .addLog(
            plantId: plant.id,
            photo: file,
            note: note?.trim().isEmpty ?? true ? null : note?.trim(),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Foto de evolução registrada!');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    }
  }
}

class _PlantAppBar extends StatelessWidget {
  final Plant plant;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _PlantAppBar({
    required this.plant,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: [
        _AppBarButton(
          icon: Icons.share_outlined,
          tooltip: AppStrings.share,
          onPressed: onShare,
        ),
        _AppBarButton(
          icon: Icons.delete_outline,
          tooltip: AppStrings.deletePlant,
          iconColor: Colors.red[300]!,
          onPressed: onDelete,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PlantImage(
              url: plant.photoUrl,
              height: 260,
              width: double.infinity,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45],
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color iconColor;

  const _AppBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: Colors.black26,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class _PlantInfoSection extends StatelessWidget {
  final Plant plant;

  const _PlantInfoSection({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plant.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (plant.scientificName != null) ...[
          const SizedBox(height: 4),
          Text(
            plant.scientificName!,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (plant.location != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                plant.location!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
        if (plant.description != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plant.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CareChips extends StatelessWidget {
  final Plant plant;

  const _CareChips({required this.plant});

  @override
  Widget build(BuildContext context) {
    final waterDays = DateHelper.daysUntil(plant.nextWateringDate);
    final fertilizeDays = DateHelper.daysUntil(plant.nextFertilizingDate);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _NextCareChip(
          icon: Icons.water_drop_outlined,
          label: waterDays <= 0 ? 'Regar hoje!' : 'Rega em ${waterDays}d',
          color: waterDays <= 0 ? AppColors.error : Colors.blue,
        ),
        _NextCareChip(
          icon: Icons.eco_outlined,
          label: fertilizeDays <= 0
              ? 'Adubar hoje!'
              : 'Adubação em ${fertilizeDays}d',
          color: fertilizeDays <= 0 ? AppColors.error : AppColors.primaryLight,
        ),
      ],
    );
  }
}

class _NextCareChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NextCareChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTipsSection extends StatelessWidget {
  final String tips;

  const _CareTipsSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'Dicas de cuidado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tips,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCareLogs extends StatelessWidget {
  final AsyncValue<List<CareLog>> logsAsync;

  const _RecentCareLogs({required this.logsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.careHistory,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            e.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
          data: (logs) {
            final recent = logs.take(10).toList();
            if (recent.isEmpty) {
              return const Text(
                'Nenhum cuidado registrado ainda.',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: recent.map((log) => _LogTile(log: log)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final CareLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
                if (log.note != null && log.note!.isNotEmpty)
                  Text(log.note!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Text(
            DateHelper.timeAgo(log.loggedAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterCareModal extends ConsumerStatefulWidget {
  final Plant plant;

  const _RegisterCareModal({required this.plant});

  @override
  ConsumerState<_RegisterCareModal> createState() => _RegisterCareModalState();
}

class _RegisterCareModalState extends ConsumerState<_RegisterCareModal> {
  CareType _selected = CareType.water;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(authNotifierProvider.future);
      if (user == null) return;
      await ref
          .read(careLogNotifierProvider(widget.plant.id).notifier)
          .addLog(
            CareLog(
              id: const Uuid().v4(),
              plantId: widget.plant.id,
              userId: user.id,
              careType: _selected,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              loggedAt: DateTime.now(),
            ),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Cuidado registrado!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.registerCare,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SegmentedButton<CareType>(
            segments: const [
              ButtonSegment(
                value: CareType.water,
                label: Text('Rega'),
                icon: Icon(Icons.water_drop_outlined),
              ),
              ButtonSegment(
                value: CareType.fertilize,
                label: Text('Adubação'),
                icon: Icon(Icons.eco_outlined),
              ),
              ButtonSegment(
                value: CareType.repot,
                label: Text('Transplante'),
                icon: Icon(Icons.move_up),
              ),
            ],
            selected: {_selected},
            onSelectionChanged: (s) => setState(() => _selected = s.first),
            style: ButtonStyle(
              iconColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _GrowthNoteModal extends StatefulWidget {
  const _GrowthNoteModal();

  @override
  State<_GrowthNoteModal> createState() => _GrowthNoteModalState();
}

class _GrowthNoteModalState extends State<_GrowthNoteModal> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Adicionar nota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Descreva como está sua planta (opcional)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex: primeira folha nova! 🌱',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Pular'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
