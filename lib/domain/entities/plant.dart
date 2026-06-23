class Plant {
  final String id;
  final String userId;
  final String name;
  final String? scientificName;
  final String? commonName;
  final String? photoUrl;
  final String? location;
  final int waterFrequencyDays;
  final int fertilizeFrequencyDays;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final DateTime createdAt;
  final String? description;
  final String? careTips;

  const Plant({
    required this.id,
    required this.userId,
    required this.name,
    this.scientificName,
    this.commonName,
    this.photoUrl,
    this.location,
    this.waterFrequencyDays = 3,
    this.fertilizeFrequencyDays = 30,
    this.lastWatered,
    this.lastFertilized,
    required this.createdAt,
    this.description,
    this.careTips,
  });

  DateTime get nextWateringDate =>
      (lastWatered ?? createdAt).add(Duration(days: waterFrequencyDays));

  DateTime get nextFertilizingDate =>
      (lastFertilized ?? createdAt).add(Duration(days: fertilizeFrequencyDays));

  bool get isWateringOverdue => DateTime.now().isAfter(nextWateringDate);

  Plant copyWith({
    String? name,
    String? scientificName,
    String? commonName,
    String? photoUrl,
    String? location,
    int? waterFrequencyDays,
    int? fertilizeFrequencyDays,
    DateTime? lastWatered,
    DateTime? lastFertilized,
    String? description,
    String? careTips,
  }) {
    return Plant(
      id: id,
      userId: userId,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      waterFrequencyDays: waterFrequencyDays ?? this.waterFrequencyDays,
      fertilizeFrequencyDays:
          fertilizeFrequencyDays ?? this.fertilizeFrequencyDays,
      lastWatered: lastWatered ?? this.lastWatered,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      createdAt: createdAt,
      description: description ?? this.description,
      careTips: careTips ?? this.careTips,
    );
  }
}
