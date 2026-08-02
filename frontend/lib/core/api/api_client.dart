import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'endpoints.dart';
import 'exceptions.dart';
import '../utils/connectivity_service.dart';
import '../events/unauthorized_event_bus.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const int _maxRetries = 3;
  final ConnectivityService _connectivityService = ConnectivityService();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _connectivityService.setServerUnreachable(false);
        return handler.next(response);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        if (error.response?.statusCode == 401 && !path.contains('token/refresh')) {
          final refreshed = await _tryRefreshToken(error.requestOptions);
          if (refreshed) {
            return handler.resolve(await _retryRequest(error.requestOptions));
          }
        }
        if (_isNetworkError(error)) {
          _connectivityService.setServerUnreachable(true);
        }
        return handler.next(error);
      },
    ));
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  Future<bool> _tryRefreshToken(RequestOptions requestOptions) async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        await clearTokens();
        _emitUnauthorized();
        return false;
      }

      final response = await Dio().post(
        '${ApiEndpoints.baseUrl}/accounts/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final newAccess = response.data['access'];
        await _storage.write(key: 'access_token', value: newAccess);
        requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await clearTokens();
      _emitUnauthorized();
    }
    return false;
  }

  void _emitUnauthorized() {
    UnauthorizedEventBus().emit(UnauthorizedEvent(
      statusCode: 401,
      message: 'Sesi telah berakhir, silakan login kembali',
    ));
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    return await _dio.fetch(requestOptions);
  }

  bool _isRetryable(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }
    return false;
  }

  Future<Response<T>> _retryWithBackoff<T>(
    Future<Response<T>> Function() request,
  ) async {
    int attempts = 0;
    DioException? lastError;

    while (attempts < _maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        lastError = e;
        attempts++;
        if (attempts >= _maxRetries || !_isRetryable(e)) {
          break;
        }
        final delay = Duration(seconds: attempts * 2);
        await Future.delayed(delay);
        if (kDebugMode) {
          print('Retry attempt $attempts after ${delay.inSeconds}s');
        }
      }
    }

    throw _handleError(lastError!);
  }

  Future<void> setTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _retryWithBackoff<T>(() => _dio.get<T>(path, queryParameters: queryParameters));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _retryWithBackoff<T>(() => _dio.post<T>(path, data: data, queryParameters: queryParameters));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _retryWithBackoff<T>(() => _dio.patch<T>(path, data: data, queryParameters: queryParameters));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _retryWithBackoff<T>(() => _dio.delete<T>(path, queryParameters: queryParameters));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    String message = 'Terjadi kesalahan';

    if (response?.data is Map) {
      final data = response!.data as Map;
      if (data.containsKey('message')) {
        message = data['message'].toString();
      } else if (data.containsKey('error')) {
        message = data['error'].toString();
      } else if (data.containsKey('detail')) {
        message = data['detail'].toString();
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException(message: message, statusCode: 400);
      case 401:
        return ApiException(message: 'Silakan login kembali', statusCode: 401);
      case 403:
        return ApiException(message: 'Anda tidak punya akses', statusCode: 403);
      case 404:
        return ApiException(message: 'Data tidak ditemukan', statusCode: 404);
      case 429:
        return ApiException(message: 'Terlalu banyak permintaan, coba lagi nanti', statusCode: 429);
      case 503:
        return ApiException(message: message, statusCode: 503);
      default:
        return ApiException(message: message, statusCode: statusCode);
    }
  }
}
