import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';

import '../config/environment.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();
  final Logger _logger = Logger();

  Future<ApiService> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.BASE_URL,
        connectTimeout: const Duration(milliseconds: Environment.CONNECTION_TIMEOUT),
        receiveTimeout: const Duration(milliseconds: Environment.RECEIVE_TIMEOUT),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Don't throw exceptions for 4xx and 5xx status codes
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    // Add interceptors for logging and token management
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically attach JWT token to all requests
          final token = _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _logger.i('🚀 REQUEST[${options.method}] => URI: ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
          _logger.e('Error message: ${error.message}');
          _logger.e('Error data: ${error.response?.data}');

          // Handle 401 Unauthorized - Token expired or invalid
          if (error.response?.statusCode == 401) {
            _logger.w('⚠️ Unauthorized! Clearing storage and redirecting to login...');
            await _storageService.clearAll();
            Get.offAllNamed('/');
          }

          // Handle 403 Forbidden - Insufficient permissions
          if (error.response?.statusCode == 403) {
            _logger.w('⚠️ Forbidden! You do not have permission to access this resource.');
            // Don't auto-navigate, let the calling code handle the error
            // This allows proper error handling in the UI
          }

          return handler.next(error);
        },
      ),
    );

    return this;
  }

  // ========== HTTP METHODS ==========

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters,}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Check for error status codes after getting response
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleErrorResponse(response);
      }

      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Downloads a binary file (e.g. a PDF) through the authenticated Dio
  // client, so the Authorization header attached by the request
  // interceptor above is sent — unlike opening the URL directly in an
  // external browser via url_launcher, which has no auth token.
  Future<List<int>> downloadBytes(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleErrorResponse(response);
      }

      final data = response.data;
      if (data == null) {
        throw 'Empty response while downloading file';
      }
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters,}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      
      // Check for error status codes after getting response
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleErrorResponse(response);
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters,}) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      
      // Check for error status codes after getting response
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleErrorResponse(response);
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters,}) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      
      // Check for error status codes after getting response
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw _handleErrorResponse(response);
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== ERROR HANDLING ==========

  String _handleErrorResponse(Response response) {
    final statusCode = response.statusCode ?? 500;

    // For 401 Unauthorized
    if (statusCode == 401) {
      return 'Unauthorized. Please login again.';
    }

    if (response.data is Map) {
      // NestJS validation errors return message as List<String>
      final message = response.data['message'];
      if (message is List) {
        return message.map((e) => e.toString()).join(', ');
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final error = response.data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }

      return 'Server error: $statusCode';
    }
    return 'Server error: $statusCode';
  }

  String _handleError(DioException error) {
    String errorMessage = 'An error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;

      case DioExceptionType.badResponse:
        if (error.response?.data != null) {
          // Try to extract error message from response
          if (error.response!.data is Map) {
            errorMessage = error.response!.data['message'] ??
                error.response!.data['error'] ??
                'Server error: ${error.response!.statusCode}';
          } else {
            errorMessage = 'Server error: ${error.response!.statusCode}';
          }
        } else {
          errorMessage = 'Server error: ${error.response?.statusCode}';
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          errorMessage = 'No internet connection';
        } else {
          errorMessage = 'Network error. Please try again.';
        }
        break;

      default:
        errorMessage = 'An unexpected error occurred';
    }

    return errorMessage;
  }
}