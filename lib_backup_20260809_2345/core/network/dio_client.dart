// lib/core/network/dio_client.dart

// ============================================================
// QIBRA AI — DIO HTTP CLIENT
// Version: 1.0.0
// Description: Configured Dio instance with interceptors,
//              timeout, error handling, and logging.
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';

// ============================================================
// SECTION 1: DIO CLIENT CLASS
// ============================================================
// Dio ka wrapper — poori app mein same instance use hoga
// Interceptors handle karte hain: auth, logging, errors
// ============================================================

class DioClient {
  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  DioClient(this._secureStorage) {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  // ── BASE OPTIONS ─────────────────────────────────────
  // Dio ki default configuration
  BaseOptions get _baseOptions => BaseOptions(
        // Base URL — sab requests iske relative hongi
        baseUrl: AppApi.apiUrl,

        // Timeouts
        connectTimeout: AppApi.connectTimeout,
        receiveTimeout: AppApi.receiveTimeout,
        sendTimeout: AppApi.sendTimeout,

        // Response type
        responseType: ResponseType.json,

        // Content type
        contentType: Headers.jsonContentType,

        // Default headers
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },

        // Success status codes
        // 200-299 success mana jaayega
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },

        // Follow redirects
        followRedirects: true,
        maxRedirects: 3,
      );

  // ── INTERCEPTORS SETUP ───────────────────────────────
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      _authInterceptor(),
      if (kDebugMode) _loggingInterceptor(),
      _errorInterceptor(),
    ]);
  }

  // ── AUTH INTERCEPTOR ─────────────────────────────────
  // Har request se pehle token add karta hai automatically
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Token read karo secure storage se
        final token = await _secureStorage.read(
          key: AppStorageKeys.accessToken,
        );

        // Agar token hai to header mein add karo
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Request continue karo
        handler.next(options);
      },
    );
  }

  // ── LOGGING INTERCEPTOR ──────────────────────────────
  // Debug mode mein saare requests/responses log karta hai
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('┌─── DIO REQUEST ────────────────────────');
        debugPrint('│ ${options.method} ${options.uri}');
        debugPrint('│ Headers: ${options.headers}');
        if (options.data != null) {
          debugPrint('│ Body: ${options.data}');
        }
        debugPrint('└────────────────────────────────────────');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('┌─── DIO RESPONSE ───────────────────────');
        debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
        debugPrint('│ Data: ${response.data}');
        debugPrint('└────────────────────────────────────────');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('┌─── DIO ERROR ──────────────────────────');
        debugPrint(
            '│ ${error.response?.statusCode} ${error.requestOptions.uri}');
        debugPrint('│ Message: ${error.message}');
        debugPrint('│ Data: ${error.response?.data}');
        debugPrint('└────────────────────────────────────────');
        handler.next(error);
      },
    );
  }

  // ── ERROR INTERCEPTOR ────────────────────────────────
  // Errors ko clean karke throw karta hai
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // 401 Unauthorized — token expired ya invalid
        if (error.response?.statusCode == 401) {
          // Token clear karo
          await _secureStorage.delete(
            key: AppStorageKeys.accessToken,
          );
          await _secureStorage.delete(
            key: AppStorageKeys.refreshToken,
          );

          // Error ko wrap karke throw karo
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: 'Session expired. Please login again.',
            ),
          );
          return;
        }

        // Baaki errors normally throw karo
        handler.next(error);
      },
    );
  }

  // ── GETTER — Dio instance access ─────────────────────
  Dio get dio => _dio;

  // ══════════════════════════════════════════
  // HTTP METHODS — Convenient wrappers
  // ══════════════════════════════════════════

  // ── GET ──────────────────────────────────────────────
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST ─────────────────────────────────────────────
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PUT ──────────────────────────────────────────────
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH ────────────────────────────────────────────
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE ───────────────────────────────────────────
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ══════════════════════════════════════════
  // ERROR HANDLING
  // ══════════════════════════════════════════

  ApiException _handleError(DioException error) {
    switch (error.type) {
      // Timeouts (connection, send, receive, transform)
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timeout. Please try again.',
          type: ApiExceptionType.timeout,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          type: ApiExceptionType.network,
        );

      case DioExceptionType.badResponse:
        return _handleStatusError(error);

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled.',
          type: ApiExceptionType.cancel,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Security error. Please try again.',
          type: ApiExceptionType.security,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? 'Unknown error occurred.',
          type: ApiExceptionType.unknown,
        );

      // Fallback for any future Dio exception types
      default:
        return ApiException(
          message: error.message ?? 'An unexpected error occurred.',
          type: ApiExceptionType.unknown,
        );
    }
  }

  ApiException _handleStatusError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Server se message extract karne ki koshish karo
    String message = 'An error occurred';
    if (data is Map<String, dynamic>) {
      message =
          data['message']?.toString() ?? data['error']?.toString() ?? message;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message,
          statusCode: 400,
          type: ApiExceptionType.badRequest,
        );
      case 401:
        return const ApiException(
          message: 'Unauthorized. Please login again.',
          statusCode: 401,
          type: ApiExceptionType.unauthorized,
        );
      case 403:
        return const ApiException(
          message: 'You don\'t have permission for this action.',
          statusCode: 403,
          type: ApiExceptionType.forbidden,
        );
      case 404:
        return const ApiException(
          message: 'Resource not found.',
          statusCode: 404,
          type: ApiExceptionType.notFound,
        );
      case 409:
        return ApiException(
          message: message,
          statusCode: 409,
          type: ApiExceptionType.conflict,
        );
      case 422:
        return ApiException(
          message: message,
          statusCode: 422,
          type: ApiExceptionType.validation,
        );
      case 429:
        return const ApiException(
          message: 'Too many requests. Please slow down.',
          statusCode: 429,
          type: ApiExceptionType.rateLimit,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
          type: ApiExceptionType.server,
        );
      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
          type: ApiExceptionType.unknown,
        );
    }
  }
}

// ============================================================
// SECTION 2: API EXCEPTION MODEL
// ============================================================
// Custom exception class — clean error handling
// UI mein user-friendly errors show karne ke liye
// ============================================================

/// API exception types — categorization ke liye
enum ApiExceptionType {
  network,
  timeout,
  cancel,
  security,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimit,
  server,
  unknown,
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    required this.type,
    this.data,
  });

  // Helper getters for UI

  /// User ko internet chahiye?
  bool get isNetworkError => type == ApiExceptionType.network;

  /// Request timeout hua?
  bool get isTimeout => type == ApiExceptionType.timeout;

  /// Token expired hai?
  bool get isUnauthorized => type == ApiExceptionType.unauthorized;

  /// Server ka issue hai?
  bool get isServerError => type == ApiExceptionType.server;

  /// Validation fail hui?
  bool get isValidationError => type == ApiExceptionType.validation;

  @override
  String toString() =>
      'ApiException($type): $message${statusCode != null ? ' [$statusCode]' : ''}';
}
