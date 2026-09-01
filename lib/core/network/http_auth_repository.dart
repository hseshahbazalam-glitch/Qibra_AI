// HTTP auth repository. Used only when AppApi.isBackendEnabled is true.
// Never logs tokens, passwords, or emails.

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/network/api_client.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';

class RefreshResult {
  const RefreshResult(this.outcome, {this.access, this.refresh});

  final RefreshOutcome outcome;
  final String? access;
  final String? refresh;
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final resp = await _client.post<Map<String, dynamic>>(
        AppApi.endpointLogin,
        data: {'email': email, 'password': password},
      );
      return _fromAuthPayload(resp.data);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        AppApi.endpointRegister,
        data: {'email': email, 'password': password, 'name': name},
      );
      return login(email: email, password: password);
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    }
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    try {
      await _client.post<Map<String, dynamic>>(
        AppApi.endpointLogout,
        data: refreshToken == null ? null : {'refresh_token': refreshToken},
      );
    } on ApiException {
      // Local logout still proceeds.
    }
  }

  @override
  Future<bool> deleteAccount() async {
    try {
      await _client.delete<Map<String, dynamic>>('/users/me');
      return true;
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.offline || e.type == ApiErrorType.timeout) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>('/auth/me');
      final data = resp.data;
      if (data == null) return null;
      return AppUser.fromJson(data);
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.offline || e.type == ApiErrorType.timeout) {
        rethrow;
      }
      return null;
    }
  }

  Future<RefreshResult> refreshWith(String refreshToken) async {
    try {
      final resp = await _client.post<Map<String, dynamic>>(
        AppApi.endpointRefreshToken,
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data;
      final access = data?['access_token']?.toString();
      final next = data?['refresh_token']?.toString();
      if (access == null || access.isEmpty) {
        return const RefreshResult(RefreshOutcome.rejected);
      }
      _client.setBearer(access);
      return RefreshResult(RefreshOutcome.rotated, access: access, refresh: next);
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.offline || e.type == ApiErrorType.timeout) {
        return const RefreshResult(RefreshOutcome.networkFailure);
      }
      if (e.statusCode == 401) {
        return const RefreshResult(RefreshOutcome.rejected);
      }
      return const RefreshResult(RefreshOutcome.networkFailure);
    }
  }

  AuthResult _fromAuthPayload(Map<String, dynamic>? data) {
    if (data == null) return const AuthResult.failure('empty_response');
    final access = data['access_token']?.toString();
    final refresh = data['refresh_token']?.toString();
    if (access == null || access.isEmpty) {
      return const AuthResult.failure('missing_token');
    }
    _client.setBearer(access);
    final user = AppUser(
      id: data['user_id']?.toString() ?? data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
    );
    return AuthResult.success(user, access, refresh);
  }
}
