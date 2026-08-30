// lib/core/network/api_client.dart
// Single Dio client. Tokens are never logged. Network failure must not logout.

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
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  serverError,
  permission,
  sync,
  auth,
  unknown,
}

enum RefreshOutcome { rotated, networkFailure, rejected, skipped }

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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final path = e.requestOptions.path;
          final already = e.requestOptions.extra['authRetry'] == true;
          if (e.response?.statusCode == 401 &&
              !already &&
              !path.contains('/auth/refresh') &&
              !path.contains('/auth/login')) {
            final outcome = await _singleFlightRefresh();
            if (outcome == RefreshOutcome.rotated) {
              e.requestOptions.extra['authRetry'] = true;
              final auth = _dio.options.headers['Authorization'];
              if (auth != null) {
                e.requestOptions.headers['Authorization'] = auth;
              }
              try {
                final resp = await _dio.fetch<dynamic>(e.requestOptions);
                return handler.resolve(resp);
              } catch (_) {}
            } else if (outcome == RefreshOutcome.rejected) {
              onAuthExpired?.call();
            }
            return handler.next(e);
          }
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

  Future<RefreshOutcome> Function()? refreshAccess;
  void Function()? onAuthExpired;
  Completer<RefreshOutcome>? _refreshInFlight;

  Future<RefreshOutcome> _singleFlightRefresh() async {
    if (_refreshInFlight != null) return _refreshInFlight!.future;
    final pending = Completer<RefreshOutcome>();
    _refreshInFlight = pending;
    try {
      final outcome =
          await (refreshAccess?.call() ?? Future.value(RefreshOutcome.skipped));
      pending.complete(outcome);
      return outcome;
    } catch (_) {
      pending.complete(RefreshOutcome.networkFailure);
      return RefreshOutcome.networkFailure;
    } finally {
      _refreshInFlight = null;
    }
  }

  void setBearer(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }

  Future<void> _ensureOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        throw const ApiException(ApiErrorType.offline,
            'No internet connection. Please check your network.');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      return await _dio
          .get<T>(path, queryParameters: queryParameters, options: options)
          .timeout(AppApi.receiveTimeout);
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
      return await _dio
          .post<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          )
          .timeout(AppApi.receiveTimeout);
    } on TimeoutException {
      throw const ApiException(
          ApiErrorType.timeout, 'Request timed out. Please try again.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const ApiException(ApiErrorType.offline, 'No internet connection.');
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      return await _dio
          .put<T>(path, data: data, options: options)
          .timeout(AppApi.receiveTimeout);
    } on TimeoutException {
      throw const ApiException(
          ApiErrorType.timeout, 'Request timed out. Please try again.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const ApiException(ApiErrorType.offline, 'No internet connection.');
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      return await _dio
          .patch<T>(path, data: data, options: options)
          .timeout(AppApi.receiveTimeout);
    } on TimeoutException {
      throw const ApiException(
          ApiErrorType.timeout, 'Request timed out. Please try again.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException {
      throw const ApiException(ApiErrorType.offline, 'No internet connection.');
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool requireOnline = true,
  }) async {
    if (requireOnline) await _ensureOnline();
    try {
      return await _dio
          .delete<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          )
          .timeout(AppApi.receiveTimeout);
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
    if (code == 401) {
      return ApiException(ApiErrorType.auth, 'Not authorized.', statusCode: code);
    }
    if (code == 403) {
      return ApiException(ApiErrorType.forbidden, 'Forbidden.', statusCode: code);
    }
    if (code == 404) {
      return const ApiException(
          ApiErrorType.notFound, 'Requested resource not found.',
          statusCode: 404);
    }
    if (code == 409) {
      return const ApiException(ApiErrorType.conflict, 'Conflict.',
          statusCode: 409);
    }
    if (code == 422) {
      return const ApiException(ApiErrorType.validation, 'Invalid request.',
          statusCode: 422);
    }
    if (code == 429) {
      return const ApiException(ApiErrorType.rateLimited, 'Too many requests.',
          statusCode: 429);
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
