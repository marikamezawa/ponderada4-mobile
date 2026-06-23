class PlantCareInfo {
  final int waterFrequencyDays;
  final int fertilizeFrequencyDays;
  final String? suggestedLocation;
  final String? description;
  final String tips;

  const PlantCareInfo({
    required this.waterFrequencyDays,
    required this.fertilizeFrequencyDays,
    this.suggestedLocation,
    this.description,
    required this.tips,
  });

  factory PlantCareInfo.fromJson(Map<String, dynamic> json) {
    return PlantCareInfo(
      waterFrequencyDays: (json['water_frequency_days'] as num?)?.toInt() ?? 3,
      fertilizeFrequencyDays:
          (json['fertilize_frequency_days'] as num?)?.toInt() ?? 30,
      suggestedLocation: json['suggested_location'] as String?,
      description: json['description'] as String?,
      tips: json['tips'] as String? ?? '',
    );
  }
}
