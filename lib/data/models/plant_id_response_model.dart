class PlantIdSuggestion {
  final String name;
  final double probability;
  final String? commonName;
  final String? description;
  final String? imageUrl;

  const PlantIdSuggestion({
    required this.name,
    required this.probability,
    this.commonName,
    this.description,
    this.imageUrl,
  });

  factory PlantIdSuggestion.fromJson(Map<String, dynamic> json) {
    final species = json['species'] as Map<String, dynamic>?;
    final commonNames = species?['commonNames'] as List?;
    final images = json['images'] as List?;
    final firstImage =
        images != null && images.isNotEmpty ? images.first as Map<String, dynamic>? : null;
    final urls = firstImage?['url'] as Map<String, dynamic>?;

    return PlantIdSuggestion(
      name: species?['scientificNameWithoutAuthor'] as String? ?? '',
      probability: (json['score'] as num?)?.toDouble() ?? 0.0,
      commonName: commonNames != null && commonNames.isNotEmpty
          ? commonNames.first as String?
          : null,
      description: null,
      imageUrl: urls?['m'] as String?,
    );
  }
}

class PlantIdResponseModel {
  final List<PlantIdSuggestion> suggestions;
  final bool isPlant;

  const PlantIdResponseModel({
    required this.suggestions,
    required this.isPlant,
  });

  PlantIdSuggestion? get bestMatch =>
      suggestions.isNotEmpty ? suggestions.first : null;

  bool get hasLowConfidence =>
      bestMatch == null || bestMatch!.probability < 0.3;

  factory PlantIdResponseModel.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List?)
            ?.map((e) =>
                PlantIdSuggestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PlantIdResponseModel(
      suggestions: results,
      isPlant: results.isNotEmpty,
    );
  }
}
