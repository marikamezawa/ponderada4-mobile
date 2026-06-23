import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../models/plant_model.dart';

class SupabasePlantDatasource {
  final SupabaseClient _client;

  SupabasePlantDatasource(this._client);

  Future<List<PlantModel>> getUserPlants(String userId) async {
    try {
      final data = await _client
          .from('plants')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => PlantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException('Erro ao buscar plantas: $e');
    }
  }

  Future<PlantModel> getPlantById(String id) async {
    try {
      final data =
          await _client.from('plants').select().eq('id', id).single();
      return PlantModel.fromJson(data);
    } catch (e) {
      throw AppException('Erro ao buscar planta: $e');
    }
  }

  Future<PlantModel> insertPlant(Map<String, dynamic> data) async {
    try {
      final result = await _client
          .from('plants')
          .insert(data)
          .select()
          .single();
      return PlantModel.fromJson(result);
    } catch (e) {
      throw AppException('Erro ao salvar planta: $e');
    }
  }

  Future<PlantModel> updatePlant(String id, Map<String, dynamic> data) async {
    try {
      final result = await _client
          .from('plants')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return PlantModel.fromJson(result);
    } catch (e) {
      throw AppException('Erro ao atualizar planta: $e');
    }
  }

  Future<void> deletePlant(String id) async {
    try {
      await _client.from('plants').delete().eq('id', id);
    } catch (e) {
      throw AppException('Erro ao deletar planta: $e');
    }
  }

  Future<String> uploadPhoto(String userId, String plantId, File file) async {
    try {
      final path = '$userId/$plantId.jpg';
      await _client.storage.from('plant-photos').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('plant-photos').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Erro ao fazer upload da foto: $e');
    }
  }
}
