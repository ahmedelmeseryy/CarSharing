import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/storage/secure_storage.dart';
import 'api_exceptions.dart';

/// Centralized Dio client with auth, error handling, and logging
class DioClient {
  // old link
  // static const String baseUrl = 'http://34.160.91.182';
  static const String baseUrl = 'http://35.186.208.67';


  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Logger _logger = Logger();

  DioClient({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
            headers: {'Accept': 'application/json'},
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor: Add JWT to headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          _logger.i('🔵 [REQUEST] ${options.method} ${options.path}');
          
          // Skip adding auth header for public auth endpoints
          final publicEndpoints = [
            '/auth-service/api/auth/login',
            '/auth-service/api/auth/signup',
          ];
          
          final isPublicEndpoint = publicEndpoints.any((endpoint) => options.path.contains(endpoint));
          
          if (!isPublicEndpoint) {
            final accessToken = await _tokenStorage.getAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
              _logger.d('Added Authorization header');
            }
          } else {
            _logger.d('Skipping Authorization header for public endpoint: ${options.path}');
          }
          
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          _logger.i('🟢 [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          _logger.e('🔴 [ERROR] ${error.response?.statusCode} ${error.message}');
          
          // Handle 401: Token expired
          if (error.response?.statusCode == 401) {
            _logger.w('⚠️  Unauthorized (401). Clearing tokens.');
            await _tokenStorage.clearAll();
            // You might want to emit an event to navigate to login
            // or refresh the token here
          }
          
          return handler.next(error);
        },
      ),
    );

    // Optional: Pretty logging for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    ));
  }

  /// Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request with body
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle successful response
  T _handleResponse<T>(Response response, T Function(dynamic json)? fromJson) {
    print('🌐 DIO_CLIENT: Response status: ${response.statusCode}');
    print('🌐 DIO_CLIENT: Response data type: ${response.data.runtimeType}');
    print('🌐 DIO_CLIENT: Raw response.data: ${response.data}');
    
    if (fromJson != null) {
      print('🌐 DIO_CLIENT: Calling fromJson with data');
      final result = fromJson(response.data);
      print('🌐 DIO_CLIENT: fromJson returned: $result');
      return result;
    }
    print('🌐 DIO_CLIENT: No fromJson, returning response.data as T');
    return response.data as T;
  }

  /// Convert DioException to custom ApiException
  ApiException _handleError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final errorMessage = error.message ?? 'Unknown error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Request timeout. Please check your connection.',
          code: 'TIMEOUT',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.badResponse:
        return _handleStatusCode(statusCode, errorMessage, error);

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
          code: 'NO_INTERNET',
          stackTrace: error.stackTrace,
        );

      default:
        return NetworkException(
          message: errorMessage,
          code: 'UNKNOWN_ERROR',
          stackTrace: error.stackTrace,
        );
    }
  }

  ApiException _handleStatusCode(int statusCode, String message, DioException error) {
    // Extract the actual message from the server response body if available
    final responseData = error.response?.data;
    final serverMessage = (responseData is Map)
        ? (responseData['message'] as String? ?? message)
        : message;

    switch (statusCode) {
      case 400:
        return ClientException(
          message: serverMessage,
          statusCode: 400,
          code: 'BAD_REQUEST',
          stackTrace: error.stackTrace,
        );
      case 401:
        return UnauthorizedException(message: serverMessage, stackTrace: error.stackTrace);
      case 403:
        return ForbiddenException(message: serverMessage, stackTrace: error.stackTrace);
      case 404:
        return NotFoundException(message: serverMessage, stackTrace: error.stackTrace);
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: serverMessage,
          statusCode: statusCode,
          code: 'SERVER_ERROR',
          stackTrace: error.stackTrace,
        );
      default:
        return ClientException(
          message: serverMessage,
          statusCode: statusCode,
          stackTrace: error.stackTrace,
        );
    }
  }

  // Cleanup
  void close() => _dio.close();
}
