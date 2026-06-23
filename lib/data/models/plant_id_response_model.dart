class PlantIdSuggestion {
  final String name;
  final double probability;
  final String? commonName;
  final String? imageUrl;

  const PlantIdSuggestion({
    required this.name,
    required this.probability,
    this.commonName,
    this.imageUrl,
  });

  factory PlantIdSuggestion.fromJson(Map<String, dynamic> json) {
    final species = json['species'] as Map<String, dynamic>?;
    final commonNames = species?['commonNames'] as List?;
    final images = json['images'] as List?;
    final firstImage = images != null && images.isNotEmpty
        ? images.first as Map<String, dynamic>?
        : null;
    final urls = firstImage?['url'] as Map<String, dynamic>?;

    return PlantIdSuggestion(
      name: species?['scientificNameWithoutAuthor'] as String? ?? '',
      probability: (json['score'] as num?)?.toDouble() ?? 0.0,
      commonName: commonNames != null && commonNames.isNotEmpty
          ? commonNames.first as String?
          : null,
      imageUrl: urls?['m'] as String?,
    );
  }
}

class PlantIdResponseModel {
  final List<PlantIdSuggestion> suggestions;
  const PlantIdResponseModel({required this.suggestions});

  PlantIdSuggestion? get bestMatch =>
      suggestions.isNotEmpty ? suggestions.first : null;

  factory PlantIdResponseModel.fromJson(Map<String, dynamic> json) {
    final results =
        (json['results'] as List?)
            ?.map((e) => PlantIdSuggestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PlantIdResponseModel(suggestions: results);
  }
}
