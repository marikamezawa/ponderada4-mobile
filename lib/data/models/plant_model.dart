import '../../domain/entities/plant.dart';

class PlantModel extends Plant {
  const PlantModel({
    required super.id,
    required super.userId,
    required super.name,
    super.scientificName,
    super.commonName,
    super.photoUrl,
    super.location,
    super.waterFrequencyDays,
    super.fertilizeFrequencyDays,
    super.lastWatered,
    super.lastFertilized,
    required super.createdAt,
    super.description,
    super.careTips,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) => PlantModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    scientificName: json['scientific_name'] as String?,
    commonName: json['common_name'] as String?,
    photoUrl: json['photo_url'] as String?,
    location: json['location'] as String?,
    waterFrequencyDays: json['water_frequency_days'] as int? ?? 3,
    fertilizeFrequencyDays: json['fertilize_frequency_days'] as int? ?? 30,
    lastWatered: json['last_watered'] != null
        ? DateTime.parse(json['last_watered'] as String)
        : null,
    lastFertilized: json['last_fertilized'] != null
        ? DateTime.parse(json['last_fertilized'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    description: json['description'] as String?,
    careTips: json['care_tips'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'scientific_name': scientificName,
    'common_name': commonName,
    'photo_url': photoUrl,
    'location': location,
    'water_frequency_days': waterFrequencyDays,
    'fertilize_frequency_days': fertilizeFrequencyDays,
    'last_watered': lastWatered?.toIso8601String(),
    'last_fertilized': lastFertilized?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'description': description,
    'care_tips': careTips,
  };

  factory PlantModel.fromEntity(Plant plant) => PlantModel(
    id: plant.id,
    userId: plant.userId,
    name: plant.name,
    scientificName: plant.scientificName,
    commonName: plant.commonName,
    photoUrl: plant.photoUrl,
    location: plant.location,
    waterFrequencyDays: plant.waterFrequencyDays,
    fertilizeFrequencyDays: plant.fertilizeFrequencyDays,
    lastWatered: plant.lastWatered,
    lastFertilized: plant.lastFertilized,
    createdAt: plant.createdAt,
    description: plant.description,
    careTips: plant.careTips,
  );
}
