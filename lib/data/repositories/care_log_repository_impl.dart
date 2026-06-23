import 'package:uuid/uuid.dart';
import '../../domain/entities/care_log.dart';
import '../../domain/repositories/care_log_repository.dart';
import '../datasources/sqlite_care_log_datasource.dart';
import '../models/care_log_model.dart';

class CareLogRepositoryImpl implements CareLogRepository {
  final SqliteCareLogDatasource _datasource;
  final _uuid = const Uuid();

  CareLogRepositoryImpl(this._datasource);

  @override
  Future<List<CareLog>> getPlantCareLogs(String plantId) =>
      _datasource.getPlantCareLogs(plantId);

  @override
  Future<int> countByUser(String userId) =>
      _datasource.countByUser(userId);

  @override
  Future<CareLog> addCareLog(CareLog log) async {
    final model = CareLogModel.fromEntity(
      CareLog(
        id: _uuid.v4(),
        plantId: log.plantId,
        userId: log.userId,
        careType: log.careType,
        note: log.note,
        loggedAt: log.loggedAt,
      ),
    );
    return _datasource.insertCareLog(model.toJson());
  }

  @override
  Future<void> deleteCareLog(String id) =>
      _datasource.deleteCareLog(id);
}
