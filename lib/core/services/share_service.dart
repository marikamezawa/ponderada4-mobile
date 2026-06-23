import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../errors/app_exception.dart';

class ShareService {
  final Dio _dio;

  ShareService({Dio? dio}) : _dio = dio ?? Dio();

  Future<void> sharePlant({
    required String name,
    required String? scientificName,
    required String? nextWateringDate,
    required String? photoUrl,
  }) async {
    final text = '''
Minha planta: $name
Especie: ${scientificName ?? 'Nao identificada'}
Proxima rega: ${nextWateringDate ?? 'Nao agendada'}
Cadastrada no ReggieApp
    '''.trim();

    try {
      if (photoUrl != null) {
        final response = await _dio.get<List<int>>(
          photoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/share_plant.jpg');
        await file.writeAsBytes(response.data!);
        await Share.shareXFiles([XFile(file.path)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (_) {
      throw const AppStorageException('Erro ao preparar compartilhamento.');
    }
  }
}
