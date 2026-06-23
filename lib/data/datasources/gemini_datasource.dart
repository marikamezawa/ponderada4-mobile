import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/env.dart';
import '../../core/errors/app_exception.dart';
import '../models/plant_care_info.dart';

class GeminiDatasource {
  static const _model = 'gemini-3.1-flash-lite';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent';

  static const _responseSchema = <String, dynamic>{
    'type': 'object',
    'properties': {
      'water_frequency_days': {
        'type': 'integer',
        'description': 'Intervalo recomendado entre regas, em dias.',
      },
      'fertilize_frequency_days': {
        'type': 'integer',
        'description': 'Intervalo recomendado entre adubações, em dias.',
      },
      'suggested_location': {
        'type': 'string',
        'description': 'Local ideal dentro de casa, em português.',
      },
      'description': {
        'type': 'string',
        'description':
            'Duas frases de curiosidades sobre origem, história, simbolismo '
            'ou características marcantes da espécie, em português.',
      },
      'tips': {
        'type': 'string',
        'description':
            'Dicas curtas de rega, luz, temperatura e adubação, em português.',
      },
    },
    'required': [
      'water_frequency_days',
      'fertilize_frequency_days',
      'suggested_location',
      'description',
      'tips',
    ],
  };

  final Dio _dio;

  GeminiDatasource({Dio? dio}) : _dio = dio ?? Dio();

  Future<PlantCareInfo> getCareTips({
    required String scientificName,
    String? commonName,
  }) async {
    if (Env.geminiApiKey.trim().isEmpty ||
        Env.geminiApiKey.contains('SUA_GEMINI')) {
      throw const GeminiException(
        'Configure uma chave válida da API Gemini antes de continuar.',
      );
    }

    final normalizedCommonName = commonName?.trim();
    final plantLabel =
        normalizedCommonName != null && normalizedCommonName.isNotEmpty
        ? '$normalizedCommonName (${scientificName.trim()})'
        : scientificName.trim();

    final prompt =
        'Você é especialista em botânica e cultivo doméstico. Gere informações '
        'sobre a espécie "$plantLabel". Responda em português do Brasil. As '
        'frequências devem ser números inteiros realistas para a espécie. Nas '
        'dicas, use uma linha para cada item: Rega, Luz, Temperatura e Adubação.';

    return _requestWithRetry(prompt);
  }

  Future<PlantCareInfo> _requestWithRetry(
    String prompt, {
    int attempt = 0,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1024,
            'responseFormat': {
              'text': {
                'mimeType': 'APPLICATION_JSON',
                'schema': _responseSchema,
              },
            },
          },
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': Env.geminiApiKey,
          },
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final text = _extractText(response.data);
      try {
        final decoded = jsonDecode(text);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('A resposta não é um objeto JSON.');
        }
        return PlantCareInfo.fromJson(decoded);
      } on FormatException {
        throw const GeminiException(
          'O Gemini devolveu informações em um formato inesperado. Tente novamente.',
        );
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if ((statusCode == 429 || (statusCode != null && statusCode >= 500)) &&
          attempt < 2) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        return _requestWithRetry(prompt, attempt: attempt + 1);
      }
      throw _friendlyError(error);
    }
  }

  String _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final blockReason = data?['promptFeedback']?['blockReason'];
      throw GeminiException(
        blockReason == null
            ? 'O Gemini não gerou informações para esta planta.'
            : 'O Gemini bloqueou a resposta ($blockReason). Tente outra identificação.',
      );
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      throw const GeminiException('Resposta inválida recebida do Gemini.');
    }
    final content = firstCandidate['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) {
      throw const GeminiException('Resposta vazia recebida do Gemini.');
    }

    final text = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join()
        .trim();
    if (text.isEmpty) {
      throw const GeminiException('Resposta vazia recebida do Gemini.');
    }
    return text;
  }

  GeminiException _friendlyError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    String? apiMessage;
    if (responseData is Map) {
      final apiError = responseData['error'];
      if (apiError is Map) apiMessage = apiError['message'] as String?;
    }

    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      return GeminiException(
        'A chave do Gemini é inválida, está bloqueada ou não tem acesso à API. '
        'Revise a chave no Google AI Studio.${_details(apiMessage)}',
      );
    }
    if (statusCode == 404) {
      return GeminiException(
        'O modelo do Gemini configurado não está disponível.${_details(apiMessage)}',
      );
    }
    if (statusCode == 429) {
      return const GeminiException(
        'Limite de requisições do Gemini atingido. Aguarde e tente novamente.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const GeminiException(
        'O Gemini demorou para responder. Verifique a conexão e tente novamente.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const GeminiException('Sem conexão com o Gemini.');
    }
    return GeminiException(
      'Não foi possível consultar o Gemini.${_details(apiMessage)}',
    );
  }

  String _details(String? message) =>
      message == null || message.trim().isEmpty ? '' : ' Detalhes: $message';
}
