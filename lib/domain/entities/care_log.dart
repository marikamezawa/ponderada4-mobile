enum CareType { water, fertilize, repot }

class CareLog {
  final String id;
  final String plantId;
  final String userId;
  final CareType careType;
  final String? note;
  final DateTime loggedAt;

  const CareLog({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.careType,
    this.note,
    required this.loggedAt,
  });

  String get careTypeLabel {
    switch (careType) {
      case CareType.water:
        return 'Rega';
      case CareType.fertilize:
        return 'Adubação';
      case CareType.repot:
        return 'Transplante';
    }
  }
}
