import 'dart:io';
import '../entities/plant.dart';
import '../repositories/plant_repository.dart';
import '../../core/services/notification_service.dart';

class SavePlantUsecase {
  final PlantRepository _repository;
  final NotificationService _notifications;

  SavePlantUsecase(this._repository, this._notifications);

  Future<Plant> call(Plant plant, {File? imageFile}) async {
    final saved = await _repository.savePlant(plant, imageFile: imageFile);
    await _notifications.scheduleWaterReminder(
      plantId: saved.id,
      plantName: saved.name,
      frequencyDays: saved.waterFrequencyDays,
    );
    await _notifications.scheduleFertilizeReminder(
      plantId: saved.id,
      plantName: saved.name,
    );
    return saved;
  }
}
