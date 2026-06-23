import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/plant.dart';
import '../../domain/repositories/plant_repository.dart';
import '../datasources/sqlite_plant_datasource.dart';
import '../models/plant_model.dart';

class PlantRepositoryImpl implements PlantRepository {
  final SqlitePlantDatasource _datasource;
  final _uuid = const Uuid();

  PlantRepositoryImpl(this._datasource);

  @override
  Future<List<Plant>> getUserPlants(String userId) =>
      _datasource.getUserPlants(userId);

  @override
  Future<Plant> getPlantById(String id) => _datasource.getPlantById(id);

  @override
  Future<Plant> savePlant(Plant plant, {File? imageFile}) async {
    final id = _uuid.v4();
    String? photoUrl;

    if (imageFile != null) {
      photoUrl = await _savePhotoLocally(plant.userId, id, imageFile);
    }

    final now = DateTime.now();
    final data = PlantModel.fromEntity(plant).toJson()
      ..['id'] = id
      ..['photo_url'] = photoUrl ?? plant.photoUrl
      ..['created_at'] = now.toIso8601String();

    return _datasource.insertPlant(data);
  }

  @override
  Future<Plant> updatePlant(Plant plant) async {
    final data = PlantModel.fromEntity(plant).toJson()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    return _datasource.updatePlant(plant.id, data);
  }

  @override
  Future<void> deletePlant(String id) async {
    final plant = await _datasource.getPlantById(id);
    if (plant.photoUrl != null && !plant.photoUrl!.startsWith('http')) {
      final f = File(plant.photoUrl!);
      if (await f.exists()) await f.delete();
    }
    await _datasource.deletePlant(id);
  }

  Future<String> _savePhotoLocally(
    String userId,
    String plantId,
    File file,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(p.join(dir.path, 'plant_photos', userId));
      await photoDir.create(recursive: true);
      final dest = File(p.join(photoDir.path, '$plantId.jpg'));
      await file.copy(dest.path);
      return dest.path;
    } catch (e) {
      throw AppStorageException('Erro ao salvar foto: $e');
    }
  }
}
