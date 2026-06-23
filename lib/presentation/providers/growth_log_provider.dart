import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/sqlite_growth_log_datasource.dart';
import '../../data/repositories/growth_log_repository_impl.dart';
import '../../domain/entities/growth_log.dart';
import '../../domain/repositories/growth_log_repository.dart';

final growthLogDatasourceProvider =
    Provider<SqliteGrowthLogDatasource>((_) => SqliteGrowthLogDatasource());

final growthLogRepositoryProvider = Provider<GrowthLogRepository>((ref) {
  return GrowthLogRepositoryImpl(ref.watch(growthLogDatasourceProvider));
});

class GrowthLogNotifier
    extends FamilyAsyncNotifier<List<GrowthLog>, String> {
  @override
  Future<List<GrowthLog>> build(String plantId) =>
      ref.watch(growthLogRepositoryProvider).getPlantGrowthLogs(plantId);

  Future<void> addLog({
    required String plantId,
    required File photo,
    String? note,
  }) async {
    final saved = await ref
        .read(growthLogRepositoryProvider)
        .addGrowthLog(plantId: plantId, photo: photo, note: note);
    state.whenData(
        (logs) => state = AsyncData([...logs, saved]));
  }

  Future<void> removeLog(String id) async {
    await ref.read(growthLogRepositoryProvider).deleteGrowthLog(id);
    state.whenData(
        (logs) => state = AsyncData(logs.where((l) => l.id != id).toList()));
  }
}

final growthLogProvider = AsyncNotifierProviderFamily<GrowthLogNotifier,
    List<GrowthLog>, String>(() => GrowthLogNotifier());
