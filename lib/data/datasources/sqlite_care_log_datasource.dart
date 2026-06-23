import '../../core/errors/app_exception.dart';
import '../models/care_log_model.dart';
import 'local_database.dart';

class SqliteCareLogDatasource {
  Future<List<CareLogModel>> getPlantCareLogs(String plantId) async {
    try {
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        'care_logs',
        where: 'plant_id = ?',
        whereArgs: [plantId],
        orderBy: 'logged_at DESC',
      );
      return rows.map(CareLogModel.fromJson).toList();
    } catch (e) {
      throw AppException('Erro ao buscar histórico: $e');
    }
  }

  Future<int> countByUser(String userId) async {
    try {
      final db = await LocalDatabase.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM care_logs WHERE user_id = ?',
        [userId],
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<CareLogModel> insertCareLog(Map<String, dynamic> data) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.insert('care_logs', data);
      final rows = await db.query(
        'care_logs',
        where: 'id = ?',
        whereArgs: [data['id']],
      );
      return CareLogModel.fromJson(rows.first);
    } catch (e) {
      throw AppException('Erro ao registrar cuidado: $e');
    }
  }

  Future<void> deleteCareLog(String id) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.delete('care_logs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('Erro ao deletar registro: $e');
    }
  }
}
