// lib/core/network/api_client.dart
// ============================================================
// QIBRA AI — CENTRAL API CLIENT (P1.1 — Single Network Layer)
// ============================================================
// Consolidates Dio + http scattered usage.
// Provides timeout (20s), offline guard, retry, error mapping,
// debug-only logging. Used by Auth, Hadith, AI (via backend),
// Halal (via backend proxy ideally).
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

enum ApiErrorType {
  offline,
  timeout,
  unauthorized,
  notFound,
  serverError,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  const ApiException(this.type, this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppApi.apiUrl,
        connectTimeout: AppApi.connectTimeout,
        receiveTimeout: AppApi.receiveTimeout,
        sendTimeout: AppApi.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'QIBRA-AI/1.0',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    // Retry interceptor (simple)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final retriesValue = e.requestOptions.extra['retries'] as int?;
          if (_shouldRetry(e) && (retriesValue ?? 0) < AppApi.maxRetries) {
            final retries = (retriesValue ?? 0) + 1;
            e.requestOptions.extra['retries'] = retries;
            await Future<void>.delayed(AppApi.retryDelay * retries);
            try {
              final resp = await _dio.fetch<dynamic>(e.requestOptions);
              return handler.resolve(resp);
            } catch (_) {}
          }
          return handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }

  /// Check internet before request
  Future<void> _ensureOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none) || (result.isEmpty)) {
        // Double-check via DNS to avoid false offline on some devices
        // but connectivity_plus is sufficient for guard
        throw const ApiException(ApiErrorType.offline,
            'No internet connection. Please check your network.');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // If connectivity check itself fails, proceed — request will timeout naturally
    }
  }

  // Generic GET with timeout guard
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      final resp = await _dio
          .get<T>(path, queryParameters: queryParameters, options: options)
          .timeout(AppApi.receiveTimeout);
      return resp;
    } on TimeoutException {
      throw const ApiException(
          ApiErrorType.timeout, 'Request timed out. Please try again.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const ApiException(ApiErrorType.offline, 'No internet connection.');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      final resp = await _dio
          .post<T>(path,
              data: data, queryParameters: queryParameters, options: options)
          .timeout(AppApi.receiveTimeout);
      return resp;
    } on TimeoutException {
      throw const ApiException(
          ApiErrorType.timeout, 'Request timed out. Please try again.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const ApiException(ApiErrorType.offline, 'No internet connection.');
    }
  }

  ApiException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
          ApiErrorType.timeout, 'Connection timed out. Please try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
          ApiErrorType.offline, 'Cannot reach server. Check internet.');
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return ApiException(
          ApiErrorType.unauthorized, 'Session expired. Please sign in again.',
          statusCode: code);
    }
    if (code == 404) {
      return const ApiException(
          ApiErrorType.notFound, 'Requested resource not found.',
          statusCode: 404);
    }
    if (code != null && code >= 500) {
      return ApiException(
          ApiErrorType.serverError, 'Server error. Please try later.',
          statusCode: code);
    }
    return ApiException(ApiErrorType.unknown, e.message ?? 'Network error',
        statusCode: code);
  }
}
