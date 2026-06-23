import '../entities/care_log.dart';

abstract class CareLogRepository {
  Future<List<CareLog>> getPlantCareLogs(String plantId);
  Future<int> countByUser(String userId);
  Future<CareLog> addCareLog(CareLog log);
  Future<void> deleteCareLog(String id);
}
