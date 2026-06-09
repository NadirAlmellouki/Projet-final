import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';

/// Couche service HTTP — wrapper Dio partagé par tous les repositories.
class ApiService {
  ApiService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage
              .readToken()
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.put<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) =>
      _wrap(() => _dio.delete<T>(path));

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;
    final data = response?.data;
    var message = 'Erreur réseau';

    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Backend injoignable (${AppConfig.baseUrl}). Lancez: npm run dev';
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      details: data,
    );
  }
}
