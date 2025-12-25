import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../models/token.dart';
import 'logger_service.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggerService _logger = LoggerService();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      _LoggingInterceptor(_logger),
      _RetryInterceptor(_dio),
    ]);
  }

  // Token management
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Generic HTTP methods
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // Token refresh logic
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Authorization': null
          }, // Don't include access token for refresh
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newTokens = Token.fromJson(response.data['data']['tokens']);
        await setTokens(newTokens.accessToken, newTokens.refreshToken);
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed: $e');
    }

    return false;
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  final ApiService _apiService;

  _AuthInterceptor(this._apiService);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Add access token to headers if available
    final token = await _apiService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print(
          '🔑 AUTH_HEADER: Bearer ${token.substring(0, 20)}...'); // Log partial token for security
    } else {
      print('❌ NO_AUTH_TOKEN: Token is null');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors by trying to refresh token
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.headers.containsKey('Authorization-Retry')) {
      final refreshed = await _apiService._refreshAccessToken();

      if (refreshed) {
        // Retry the request with new token
        final newToken = await _apiService.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        err.requestOptions.headers['Authorization-Retry'] = 'true';

        try {
          final response = await _apiService._dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );

          return handler.resolve(response);
        } catch (e) {
          // If retry fails, continue with original error
        }
      }
    }

    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  final LoggerService _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('API Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      _logger.d('Request Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
        'API Response: ${response.statusCode} ${response.requestOptions.uri}');
    _logger.d('Response Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger
        .e('API Error: ${err.response?.statusCode} ${err.requestOptions.uri}');
    if (err.response?.data != null) {
      _logger.e('Error Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}

// Retry Interceptor for network issues
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int maxRetries = 3;

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Retry on network errors
    if (_shouldRetry(err)) {
      final requestOptions = err.requestOptions;

      if (requestOptions.headers['Retry-Count'] == null) {
        requestOptions.headers['Retry-Count'] = 0;
      }

      int retryCount = requestOptions.headers['Retry-Count'] ?? 0;

      if (retryCount < maxRetries) {
        requestOptions.headers['Retry-Count'] = retryCount + 1;

        // Exponential backoff
        final delay = Duration(milliseconds: 1000 * (retryCount + 1));

        await Future.delayed(delay);

        try {
          final response = await _dio.request(
            requestOptions.path,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
          );

          return handler.resolve(response);
        } catch (e) {
          // Continue to next retry or final error
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
