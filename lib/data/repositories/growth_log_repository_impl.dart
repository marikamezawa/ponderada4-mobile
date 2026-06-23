import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/growth_log.dart';
import '../../domain/repositories/growth_log_repository.dart';
import '../datasources/sqlite_growth_log_datasource.dart';

class GrowthLogRepositoryImpl implements GrowthLogRepository {
  final SqliteGrowthLogDatasource _datasource;
  final _uuid = const Uuid();

  GrowthLogRepositoryImpl(this._datasource);

  @override
  Future<List<GrowthLog>> getPlantGrowthLogs(String plantId) =>
      _datasource.getPlantGrowthLogs(plantId);

  @override
  Future<GrowthLog> addGrowthLog({
    required String plantId,
    required File photo,
    String? note,
  }) async {
    final id = _uuid.v4();
    final photoPath = await _savePhotoLocally(plantId, id, photo);

    final data = {
      'id': id,
      'plant_id': plantId,
      'photo_path': photoPath,
      'note': note,
      'logged_at': DateTime.now().toIso8601String(),
    };

    return _datasource.insertGrowthLog(data);
  }

  @override
  Future<void> deleteGrowthLog(String id) async {
    final log = await _datasource.getGrowthLogById(id);
    if (log != null) {
      final f = File(log.photoPath);
      if (await f.exists()) await f.delete();
    }
    await _datasource.deleteGrowthLog(id);
  }

  Future<String> _savePhotoLocally(
    String plantId,
    String logId,
    File file,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(p.join(dir.path, 'growth_photos', plantId));
      await photoDir.create(recursive: true);
      final dest = File(p.join(photoDir.path, '$logId.jpg'));
      await file.copy(dest.path);
      return dest.path;
    } catch (e) {
      throw AppStorageException('Erro ao salvar foto de evolução: $e');
    }
  }
}
