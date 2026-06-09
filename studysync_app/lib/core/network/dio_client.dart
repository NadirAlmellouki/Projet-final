import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

typedef TokenRefresher = Future<void> Function();

class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    TokenRefresher? onUnauthorized,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
            await _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefresher? _onUnauthorized;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _safeRequest(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _safeRequest(
        () => _dio.post<T>(path, data: data, queryParameters: queryParameters),
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) =>
      _safeRequest(() => _dio.put<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) =>
      _safeRequest(() => _dio.delete<T>(path));

  Future<Response<T>> _safeRequest<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Une erreur réseau est survenue';
    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Délai de connexion dépassé. Vérifiez le backend.';
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Impossible de joindre le serveur (${AppConfig.baseUrl}). Lancez le backend.';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: data,
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(tokenStorage: ref.watch(tokenStorageProvider));
});
