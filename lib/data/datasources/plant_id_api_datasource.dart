import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/env.dart';
import '../../core/errors/app_exception.dart';
import '../models/plant_id_response_model.dart';

class PlantIdApiDatasource {
  final Dio _dio;

  PlantIdApiDatasource({Dio? dio}) : _dio = dio ?? Dio();

  Future<PlantIdResponseModel> identifyPlant(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'images': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'plant.jpg',
        ),
        'organs': 'auto',
      });

      final response = await _dio.post<Map<String, dynamic>>(
        'https://my-api.plantnet.org/v2/identify/all',
        queryParameters: {
          'api-key': Env.plantNetApiKey,
          'lang': 'pt',
        },
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return PlantIdResponseModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const PlantIdException(
            'Tempo esgotado. Tente outra foto ou cadastre manualmente.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      if (e.response?.statusCode == 404) {
        // PlantNet returns 404 when no plant is found
        return const PlantIdResponseModel(suggestions: [], isPlant: false);
      }
      throw const PlantIdException();
    }
  }
}
