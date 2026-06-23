import '../entities/care_log.dart';
import '../repositories/care_log_repository.dart';
import '../repositories/plant_repository.dart';

class ScheduleCareUsecase {
  final CareLogRepository _careLogRepository;
  final PlantRepository _plantRepository;

  ScheduleCareUsecase(this._careLogRepository, this._plantRepository);

  Future<CareLog> call(CareLog log) async {
    final saved = await _careLogRepository.addCareLog(log);

    final plant = await _plantRepository.getPlantById(log.plantId);
    final updated = switch (log.careType) {
      CareType.water => plant.copyWith(lastWatered: log.loggedAt),
      CareType.fertilize => plant.copyWith(lastFertilized: log.loggedAt),
      CareType.repot => plant,
    };
    await _plantRepository.updatePlant(updated);

    return saved;
  }
}
