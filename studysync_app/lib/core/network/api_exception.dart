class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isBadRequest => statusCode == 400;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}
