import '../../domain/entities/care_log.dart';

class CareLogModel extends CareLog {
  const CareLogModel({
    required super.id,
    required super.plantId,
    required super.userId,
    required super.careType,
    super.note,
    required super.loggedAt,
  });

  factory CareLogModel.fromJson(Map<String, dynamic> json) => CareLogModel(
        id: json['id'] as String,
        plantId: json['plant_id'] as String,
        userId: json['user_id'] as String,
        careType: _parseCareType(json['care_type'] as String),
        note: json['note'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'user_id': userId,
        'care_type': careType.name,
        'note': note,
        'logged_at': loggedAt.toIso8601String(),
      };

  static CareType _parseCareType(String value) {
    return CareType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CareType.water,
    );
  }

  factory CareLogModel.fromEntity(CareLog log) => CareLogModel(
        id: log.id,
        plantId: log.plantId,
        userId: log.userId,
        careType: log.careType,
        note: log.note,
        loggedAt: log.loggedAt,
      );
}
