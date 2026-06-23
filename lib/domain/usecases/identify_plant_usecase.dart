import 'dart:io';
import '../../data/models/plant_id_response_model.dart';
import '../../data/datasources/plant_id_api_datasource.dart';

class IdentifyPlantUsecase {
  final PlantIdApiDatasource _datasource;

  IdentifyPlantUsecase(this._datasource);

  Future<PlantIdResponseModel> call(File imageFile) =>
      _datasource.identifyPlant(imageFile);
}
