import 'package:flutter_test/flutter_test.dart';
import 'package:reggieapp/data/models/plant_model.dart';
import 'package:reggieapp/domain/entities/plant.dart';

void main() {
  test('mantém curiosidade e dicas ao converter planta para SQLite', () {
    final plant = Plant(
      id: 'plant-1',
      userId: 'user-1',
      name: 'Costela-de-adão',
      createdAt: DateTime(2026, 6, 23),
      description: 'Curiosidade sobre a espécie.',
      careTips: 'Dicas de cuidado.',
    );

    final json = PlantModel.fromEntity(plant).toJson();

    expect(json['description'], plant.description);
    expect(json['care_tips'], plant.careTips);
  });
}
