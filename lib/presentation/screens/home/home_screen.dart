import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plant_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/plant_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final plantsAsync = ref.watch(plantListProvider);
    final dueReminders = ref.watch(dueRemindersCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            authAsync.whenOrNull(
              data: (user) =>
                  Text('Olá, ${user?.name.split(' ').first ?? ''}! 🌱'),
            ) ??
            const Text(AppStrings.myPlants),
        actions: [
          IconButton(
            tooltip: 'Central de notificações',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (dueReminders > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        dueReminders > 9 ? '9+' : '$dueReminders',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: plantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          showErrorSnackbar(context, e.toString());
          return const SizedBox.shrink();
        },
        data: (plants) {
          if (plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 80, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noPlantsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.noPlantsSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.addPlant),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar primeira planta'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 48),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(plantListProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 480
                    ? 2
                    : constraints.maxWidth < 900
                    ? 3
                    : 4;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: plants.length,
                  itemBuilder: (context, i) => PlantCard(
                    plant: plants[i],
                    onTap: () =>
                        context.push(AppRoutes.plantDetailPath(plants[i].id)),
                    onDelete: () => ref
                        .read(plantListProvider.notifier)
                        .removePlant(plants[i].id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addPlant),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addPlant),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
