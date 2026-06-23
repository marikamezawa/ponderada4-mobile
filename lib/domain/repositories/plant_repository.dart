import 'dart:io';
import '../entities/plant.dart';

abstract class PlantRepository {
  Future<List<Plant>> getUserPlants(String userId);
  Future<Plant> getPlantById(String id);
  Future<Plant> savePlant(Plant plant, {File? imageFile});
  Future<Plant> updatePlant(Plant plant);
  Future<void> deletePlant(String id);
}
