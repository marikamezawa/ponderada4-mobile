import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/sqlite_care_log_datasource.dart';
import '../../data/repositories/care_log_repository_impl.dart';
import '../../domain/entities/care_log.dart';
import '../../domain/repositories/care_log_repository.dart';
import '../../domain/usecases/schedule_care_usecase.dart';
import 'plant_provider.dart';

final sqliteCareLogDatasourceProvider =
    Provider<SqliteCareLogDatasource>((ref) {
  return SqliteCareLogDatasource();
});

final careLogRepositoryProvider = Provider<CareLogRepository>((ref) {
  return CareLogRepositoryImpl(ref.watch(sqliteCareLogDatasourceProvider));
});

final scheduleCareUsecaseProvider = Provider<ScheduleCareUsecase>((ref) {
  return ScheduleCareUsecase(
    ref.watch(careLogRepositoryProvider),
    ref.watch(plantRepositoryProvider),
  );
});

class CareLogNotifier extends FamilyAsyncNotifier<List<CareLog>, String> {
  @override
  Future<List<CareLog>> build(String plantId) async {
    return ref.watch(careLogRepositoryProvider).getPlantCareLogs(plantId);
  }

  Future<void> addLog(CareLog log) async {
    final saved = await ref.read(scheduleCareUsecaseProvider).call(log);
    state.whenData((logs) {
      state = AsyncData([saved, ...logs]);
    });
    ref.invalidate(plantDetailProvider(log.plantId));
  }
}

final careLogNotifierProvider =
    AsyncNotifierProvider.family<CareLogNotifier, List<CareLog>, String>(
        () => CareLogNotifier());
