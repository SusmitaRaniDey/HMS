import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:logger/logger.dart';

import '../config/environment.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = getx.Get.find<StorageService>(tag: 'doctor');
  final Logger _logger = Logger();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: const Duration(milliseconds: Environment.CONNECT_TIMEOUT),
        receiveTimeout: const Duration(milliseconds: Environment.RECEIVE_TIMEOUT),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add token to headers if available
          final token = _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.d('Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          _logger.d('Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          _logger.e('Error message: ${error.message}');
          _logger.e('Error data: ${error.response?.data}');

          // Handle 401 Unauthorized - Auto logout
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _handleUnauthorized() async {
    await _storageService.clearAll();
    getx.Get.offAllNamed(AppRoutes.WELCOME);
  }

  // GET Request
  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler
  String _handleError(DioException error) {
    String errorMessage = 'An unexpected error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;

      case DioExceptionType.badResponse:
        if (error.response?.data != null) {
          if (error.response!.data is Map) {
            errorMessage = error.response!.data['message'] ??
                error.response!.data['error'] ??
                'Server error occurred';
          } else {
            errorMessage = error.response!.data.toString();
          }
        } else {
          errorMessage = 'Server error: ${error.response?.statusCode}';
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection. Please check your network.';
        break;

      case DioExceptionType.unknown:
        errorMessage = 'Connection failed. Please try again.';
        break;

      default:
        errorMessage = error.message ?? 'An error occurred';
    }

    return errorMessage;
  }

  // Get Dio instance (for advanced use cases)
  Dio get dio => _dio;
}
