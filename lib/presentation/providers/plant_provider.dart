import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/sqlite_plant_datasource.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../domain/entities/plant.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../domain/usecases/get_user_plants_usecase.dart';
import '../../domain/usecases/save_plant_usecase.dart';
import 'auth_provider.dart';

final sqlitePlantDatasourceProvider = Provider<SqlitePlantDatasource>((ref) {
  return SqlitePlantDatasource();
});

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepositoryImpl(ref.watch(sqlitePlantDatasourceProvider));
});

final getUserPlantsUsecaseProvider = Provider<GetUserPlantsUsecase>((ref) {
  return GetUserPlantsUsecase(ref.watch(plantRepositoryProvider));
});

final savePlantUsecaseProvider = Provider<SavePlantUsecase>((ref) {
  return SavePlantUsecase(
    ref.watch(plantRepositoryProvider),
    NotificationService(),
  );
});

class PlantListNotifier extends AsyncNotifier<List<Plant>> {
  @override
  Future<List<Plant>> build() async {
    final user = await ref.watch(authNotifierProvider.future);
    if (user == null) return [];
    return ref.read(getUserPlantsUsecaseProvider).call(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = await ref.read(authNotifierProvider.future);
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(getUserPlantsUsecaseProvider).call(user.id),
    );
  }

  Future<void> addPlant(Plant plant, {File? imageFile}) async {
    final saved = await ref.read(savePlantUsecaseProvider).call(
          plant,
          imageFile: imageFile,
        );
    state.whenData((plants) {
      state = AsyncData([saved, ...plants]);
    });
  }

  Future<void> removePlant(String id) async {
    await ref.read(plantRepositoryProvider).deletePlant(id);
    state.whenData((plants) {
      state = AsyncData(plants.where((p) => p.id != id).toList());
    });
  }
}

final plantListProvider =
    AsyncNotifierProvider<PlantListNotifier, List<Plant>>(
        () => PlantListNotifier());

final plantDetailProvider =
    FutureProvider.family<Plant, String>((ref, id) async {
  return ref.watch(plantRepositoryProvider).getPlantById(id);
});
