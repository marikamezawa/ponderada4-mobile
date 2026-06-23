import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reggieapp/data/datasources/gemini_datasource.dart';

void main() {
  test('envia schema JSON e interpreta curiosidades e cuidados', () async {
    late RequestOptions capturedRequest;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': '''
{
  "water_frequency_days": 7,
  "fertilize_frequency_days": 30,
  "suggested_location": "Próximo a uma janela com luz indireta",
  "description": "A costela-de-adão vem das florestas tropicais americanas. Suas folhas desenvolvem recortes conforme amadurecem.",
  "tips": "Rega: mantenha o solo levemente úmido.\\nLuz: prefira luz indireta."
}
''',
                        },
                      ],
                    },
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final result = await GeminiDatasource(dio: dio).getCareTips(
      scientificName: 'Monstera deliciosa',
      commonName: 'Costela-de-adão',
    );

    expect(result.waterFrequencyDays, 7);
    expect(result.fertilizeFrequencyDays, 30);
    expect(result.description, contains('florestas tropicais'));
    expect(capturedRequest.path, contains('gemini-3.1-flash-lite'));
    expect(capturedRequest.headers['x-goog-api-key'], isNotEmpty);

    final body = capturedRequest.data as Map<String, dynamic>;
    final config = body['generationConfig'] as Map<String, dynamic>;
    final responseFormat = config['responseFormat'] as Map<String, dynamic>;
    final textFormat = responseFormat['text'] as Map<String, dynamic>;
    expect(textFormat['mimeType'], 'APPLICATION_JSON');
    expect(textFormat['schema'], isA<Map<String, dynamic>>());
  });

  test('informa quando o Gemini devolve resposta vazia', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: const {'candidates': []},
          ),
        ),
      ),
    );

    expect(
      () => GeminiDatasource(
        dio: dio,
      ).getCareTips(scientificName: 'Monstera deliciosa'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'mensagem',
          contains('não gerou informações'),
        ),
      ),
    );
  });
}
