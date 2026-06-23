class GrowthLog {
  final String id;
  final String plantId;
  final String photoPath;
  final String? note;
  final DateTime loggedAt;

  const GrowthLog({
    required this.id,
    required this.plantId,
    required this.photoPath,
    this.note,
    required this.loggedAt,
  });
}
