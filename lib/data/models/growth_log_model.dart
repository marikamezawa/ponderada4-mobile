import '../../domain/entities/growth_log.dart';

class GrowthLogModel extends GrowthLog {
  const GrowthLogModel({
    required super.id,
    required super.plantId,
    required super.photoPath,
    super.note,
    required super.loggedAt,
  });

  factory GrowthLogModel.fromJson(Map<String, dynamic> json) => GrowthLogModel(
    id: json['id'] as String,
    plantId: json['plant_id'] as String,
    photoPath: json['photo_path'] as String,
    note: json['note'] as String?,
    loggedAt: DateTime.parse(json['logged_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'plant_id': plantId,
    'photo_path': photoPath,
    'note': note,
    'logged_at': loggedAt.toIso8601String(),
  };
}
