class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NotFoundException extends ApiException {
  NotFoundException(String message, {Map<String, dynamic>? details})
      : super(404, message, details: details);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message, {Map<String, dynamic>? details})
      : super(401, message, details: details);
}

class ValidationException extends ApiException {
  ValidationException(String message, {Map<String, dynamic>? details})
      : super(422, message, details: details);
}

class ConflictException extends ApiException {
  ConflictException(String message, {Map<String, dynamic>? details})
      : super(409, message, details: details);
}
