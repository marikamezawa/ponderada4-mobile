import '../entities/plant.dart';
import '../repositories/plant_repository.dart';

class GetUserPlantsUsecase {
  final PlantRepository _repository;

  GetUserPlantsUsecase(this._repository);

  Future<List<Plant>> call(String userId) => _repository.getUserPlants(userId);
}
