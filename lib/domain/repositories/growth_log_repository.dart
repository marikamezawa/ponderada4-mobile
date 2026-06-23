import 'dart:io';
import '../entities/growth_log.dart';

abstract class GrowthLogRepository {
  Future<List<GrowthLog>> getPlantGrowthLogs(String plantId);
  Future<GrowthLog> addGrowthLog({
    required String plantId,
    required File photo,
    String? note,
  });
  Future<void> deleteGrowthLog(String id);
}
