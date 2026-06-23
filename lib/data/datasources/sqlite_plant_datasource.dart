import '../../core/errors/app_exception.dart';
import '../models/plant_model.dart';
import 'local_database.dart';

class SqlitePlantDatasource {
  Future<List<PlantModel>> getUserPlants(String userId) async {
    try {
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        'plants',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return rows.map(PlantModel.fromJson).toList();
    } catch (e) {
      throw AppException('Erro ao buscar plantas: $e');
    }
  }

  Future<PlantModel> getPlantById(String id) async {
    try {
      final db = await LocalDatabase.instance.database;
      final rows =
          await db.query('plants', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) throw AppException('Planta não encontrada.');
      return PlantModel.fromJson(rows.first);
    } catch (e) {
      throw AppException('Erro ao buscar planta: $e');
    }
  }

  Future<PlantModel> insertPlant(Map<String, dynamic> data) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.insert('plants', data);
      return getPlantById(data['id'] as String);
    } catch (e) {
      throw AppException('Erro ao salvar planta: $e');
    }
  }

  Future<PlantModel> updatePlant(
      String id, Map<String, dynamic> data) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.update('plants', data, where: 'id = ?', whereArgs: [id]);
      return getPlantById(id);
    } catch (e) {
      throw AppException('Erro ao atualizar planta: $e');
    }
  }

  Future<void> deletePlant(String id) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.delete('plants', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('Erro ao deletar planta: $e');
    }
  }
}
