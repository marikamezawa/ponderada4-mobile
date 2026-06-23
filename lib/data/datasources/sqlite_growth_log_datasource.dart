import '../../core/errors/app_exception.dart';
import '../models/growth_log_model.dart';
import 'local_database.dart';

class SqliteGrowthLogDatasource {
  Future<List<GrowthLogModel>> getPlantGrowthLogs(String plantId) async {
    try {
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        'growth_logs',
        where: 'plant_id = ?',
        whereArgs: [plantId],
        orderBy: 'logged_at ASC',
      );
      return rows.map(GrowthLogModel.fromJson).toList();
    } catch (e) {
      throw AppException('Erro ao buscar evolução: $e');
    }
  }

  Future<GrowthLogModel> insertGrowthLog(Map<String, dynamic> data) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.insert('growth_logs', data);
      final rows = await db.query(
        'growth_logs',
        where: 'id = ?',
        whereArgs: [data['id']],
      );
      return GrowthLogModel.fromJson(rows.first);
    } catch (e) {
      throw AppException('Erro ao salvar foto de evolução: $e');
    }
  }

  Future<void> deleteGrowthLog(String id) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.delete('growth_logs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('Erro ao deletar registro de evolução: $e');
    }
  }
}
