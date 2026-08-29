class ServerException implements Exception {
  final String message;
  final String code;
  ServerException({required this.message, required this.code});
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}

class ApiException implements Exception {
  final String message;
  final String? code;
  ApiException({required this.message, this.code = "000"});
}

class StorageExceptions implements Exception {
  final String message;
  final String? code;
  StorageExceptions({required this.message, this.code = "000"});
}

class AuthUserException implements Exception {
  final String message;
  AuthUserException({required this.message});
}

class UnexceptedException implements Exception {
  final String message;
  final String? code;
  UnexceptedException({required this.message, this.code = "000"});
}
