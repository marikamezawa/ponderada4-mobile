class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sem conexão com a internet.'])
    : super(code: 'NETWORK_ERROR');
}

class AppAuthException extends AppException {
  const AppAuthException([super.message = 'Erro de autenticação.'])
    : super(code: 'AUTH_ERROR');
}

class PlantIdException extends AppException {
  const PlantIdException([super.message = 'Erro ao identificar planta.'])
    : super(code: 'PLANT_ID_ERROR');
}

class GeminiException extends AppException {
  const GeminiException([super.message = 'Erro ao consultar o Gemini.'])
    : super(code: 'GEMINI_ERROR');
}

class AppStorageException extends AppException {
  const AppStorageException([super.message = 'Erro ao salvar arquivo.'])
    : super(code: 'STORAGE_ERROR');
}
