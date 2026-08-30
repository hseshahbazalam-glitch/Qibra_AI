// lib/core/providers/auth_provider.dart

// ============================================================
// QIBRA AI — AUTHENTICATION PROVIDER (v2.0 — Anonymous-First)
// P0.1 FIX: No fake JWT, backend-gated, anonymous-first
// ============================================================
// Design:
// - App is anonymous-first when AppApi.isBackendEnabled == false
// - Login/Register return clear "backend not available" error, do NOT
//   create fake tokens. User can continue as Guest (unauthenticated).
// - When backend enabled, real Dio calls would go via AuthRepository.
// - SecureStorage only used for real tokens, never fake.
// - Session restoration checks token existence but validates format,
//   does not create dummy user if token is fake/legacy.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/network/api_client.dart';
import 'package:qibra_ai/core/network/http_auth_repository.dart';
import 'package:qibra_ai/core/providers/app_providers.dart';
import 'package:qibra_ai/core/sync/account_migration.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';

// ============================================================
// SECTION 1: AUTH STATE ENUM
// ============================================================

enum AuthStatus {
  /// Initial state — not yet checked
  initial,

  /// Currently checking auth state (splash)
  loading,

  /// User authenticated (requires backend)
  authenticated,

  /// Anonymous/guest — default when backend disabled or logged out
  unauthenticated,
}

// ============================================================
// SECTION 2: USER MODEL
// ============================================================

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? createdAt;
  final bool isEmailVerified;
  final bool isPremium;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phoneNumber,
    this.createdAt,
    this.isEmailVerified = false,
    this.isPremium = false,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isPremium,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      // Never trust JSON for premium. Billing store is unconfigured.
      isPremium: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'created_at': createdAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'is_premium': isPremium,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, email, name);

  @override
  String toString() => 'AppUser(id: $id, email: $email, name: $name)';
}

// ============================================================
// SECTION 3: AUTH STATE MODEL
// ============================================================

@immutable
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  factory AuthState.loading() {
    return const AuthState(
      status: AuthStatus.loading,
      isLoading: true,
    );
  }

  factory AuthState.authenticated(AppUser user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  factory AuthState.unauthenticated({String? error}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: error,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isGuest => status == AuthStatus.unauthenticated;
  bool get hasError => errorMessage != null;
}

// ============================================================
// SECTION 4: AUTH REPOSITORY ABSTRACTION
// ============================================================
// Future backend integration point.
// When AppApi.isBackendEnabled == true, implement real HTTP calls
// via Dio to AppApi.apiUrl + endpoints. When false, repository
// is no-op and Notifier surfaces friendly "continue as guest".

abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});
  Future<AuthResult> register(
      {required String email, required String password, required String name});
  Future<void> logout({String? refreshToken});
  Future<AppUser?> getCurrentUser();
  Future<bool> deleteAccount();
}

class AuthResult {
  final bool success;
  final AppUser? user;
  final String? token;
  final String? refreshToken;
  final String? error;
  const AuthResult.success(this.user, this.token, this.refreshToken)
      : success = true,
        error = null;
  const AuthResult.failure(this.error)
      : success = false,
        user = null,
        token = null,
        refreshToken = null;
}

// Stub implementation — backend disabled.
// Replace with RealAuthRepository when backend deployed.
class StubAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(
      {required String email, required String password}) async {
    return const AuthResult.failure(
      'Authentication service is not available in this build. '
      'Please continue as Guest — your Quran, Prayer, and Duas work fully offline. '
      'Sign-in will be enabled when the Qibra backend is deployed.',
    );
  }

  @override
  Future<AuthResult> register(
      {required String email,
      required String password,
      required String name}) async {
    return const AuthResult.failure(
      'Registration is not available in this build. '
      'Please continue as Guest. Your progress is saved locally.',
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {}

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<bool> deleteAccount() async => true;
}

// ============================================================
// SECTION 5: AUTH NOTIFIER (Anonymous-First)
// ============================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final AuthRepository _repository;

  AuthNotifier(this._secureStorage, {AuthRepository? repository})
      : _repository = repository ??
            (AppApi.isBackendEnabled ? HttpAuthRepository() : StubAuthRepository()),
        super(AuthState.initial()) {
    if (AppApi.isBackendEnabled) {
      ApiClient.instance.refreshAccess = _rotateAccess;
      ApiClient.instance.onAuthExpired = _onSessionExpired;
    }
    _checkAuthStatus();
  }

  // ── AUTH CHECK ─────────────────────────────────────────
  // Only restores session if backend enabled AND token looks real
  // Legacy fake tokens (fake_jwt_*) are purged as compromised.

  Future<void> _checkAuthStatus() async {
    state = AuthState.loading();
    try {
      // If backend disabled, immediately go to guest — no token check needed
      if (!AppApi.isBackendEnabled) {
        // Clean up any legacy fake tokens if present
        await _purgeLegacyFakeTokens();
        state = AuthState.unauthenticated();
        return;
      }

      final token = await _secureStorage.read(key: AppStorageKeys.accessToken);
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      // Reject legacy fake tokens that were stored by v1.0
      if (_isLegacyFakeToken(token)) {
        await _purgeLegacyFakeTokens();
        state = AuthState.unauthenticated(
          error:
              'Previous session was demo-only and has been cleared. Please sign in again.',
        );
        return;
      }

      ApiClient.instance.setBearer(token);

      // Backend enabled + token looks real → try to fetch user
      try {
        final user = await _repository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      } on ApiException catch (e) {
        if (e.type == ApiErrorType.offline || e.type == ApiErrorType.timeout) {
          final id = await _secureStorage.read(key: AppStorageKeys.userId);
          state = AuthState.authenticated(
            AppUser(id: id ?? '', email: '', name: ''),
          );
          return;
        }
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  bool _isLegacyFakeToken(String token) {
    return token.startsWith('fake_') ||
        token == 'fake_jwt_token_xyz123' ||
        token == 'fake_jwt_token_new_user' ||
        token == 'refreshed_fake_token';
  }

  Future<void> _purgeLegacyFakeTokens() async {
    try {
      final t = await _secureStorage.read(key: AppStorageKeys.accessToken);
      if (t != null && _isLegacyFakeToken(t)) {
        await _secureStorage.delete(key: AppStorageKeys.accessToken);
        await _secureStorage.delete(key: AppStorageKeys.refreshToken);
        await _secureStorage.delete(key: AppStorageKeys.userId);
      }
    } catch (_) {}
  }

  // ── LOGIN ──────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Local validation first (shared)
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password required');
      }
      if (!AppValidation.emailRegex.hasMatch(email)) {
        throw Exception('Invalid email format');
      }
      if (password.length < AppValidation.passwordMinLength) {
        throw Exception(
            'Password must be at least ${AppValidation.passwordMinLength} characters');
      }

      // Backend gate
      if (!AppApi.isBackendEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Sign-in is not available in this build. Please tap "Continue as Guest" — '
              'all Islamic features work offline. Authentication will be enabled with the backend.',
        );
        return false;
      }

      final result = await _repository.login(email: email, password: password);
      if (!result.success || result.user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? 'Login failed',
        );
        return false;
      }

      await _persistTokens(result);
      AccountMigration.attachLocal(queue: SyncEngine.instance.queue, localOps: const []);
      state = AuthState.authenticated(result.user!);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── REGISTER ───────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (name.trim().length < AppValidation.nameMinLength) {
        throw Exception('Name too short');
      }
      if (!AppValidation.emailRegex.hasMatch(email)) {
        throw Exception('Invalid email format');
      }
      if (password.length < AppValidation.passwordMinLength) {
        throw Exception(
            'Password must be at least ${AppValidation.passwordMinLength} characters');
      }

      if (!AppApi.isBackendEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Registration is not available in this build. Please continue as Guest.',
        );
        return false;
      }

      final result = await _repository.register(
          email: email, password: password, name: name);
      if (!result.success || result.user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? 'Registration failed',
        );
        return false;
      }

      await _persistTokens(result);
      AccountMigration.attachLocal(queue: SyncEngine.instance.queue, localOps: const []);
      state = AuthState.authenticated(result.user!);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── CONTINUE AS GUEST ──────────────────────────────────
  // Explicit guest mode — clears any error and ensures unauthenticated
  void continueAsGuest() {
    state = AuthState.unauthenticated();
  }

  // ── LOGOUT ─────────────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      if (AppApi.isBackendEnabled) {
        try {
          final refresh =
              await _secureStorage.read(key: AppStorageKeys.refreshToken);
          await _repository.logout(refreshToken: refresh);
        } catch (_) {}
      }
      ApiClient.instance.setBearer(null);
      await _secureStorage.delete(key: AppStorageKeys.accessToken);
      await _secureStorage.delete(key: AppStorageKeys.refreshToken);
      await _secureStorage.delete(key: AppStorageKeys.userId);
      await _secureStorage.delete(key: AppStorageKeys.tokenExpiry);
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  // ── UPDATE USER ────────────────────────────────────────
  void updateUser(AppUser updatedUser) {
    if (state.isAuthenticated) {
      state = state.copyWith(user: updatedUser);
    }
  }

  // ── CLEAR ERROR ────────────────────────────────────────
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ── REFRESH TOKEN ──────────────────────────────────────
  // Only meaningful when backend enabled

  Future<bool> refreshToken() async {
    final outcome = await _rotateAccess();
    return outcome == RefreshOutcome.rotated;
  }

  Future<RefreshOutcome> _rotateAccess() async {
    if (!AppApi.isBackendEnabled) return RefreshOutcome.skipped;
    try {
      final refreshToken = await _secureStorage.read(
        key: AppStorageKeys.refreshToken,
      );
      if (refreshToken == null || refreshToken.isEmpty) {
        return RefreshOutcome.rejected;
      }
      final repo = _repository;
      if (repo is! HttpAuthRepository) return RefreshOutcome.skipped;
      final result = await repo.refreshWith(refreshToken);
      if (result.outcome == RefreshOutcome.rotated && result.access != null) {
        await _secureStorage.write(
            key: AppStorageKeys.accessToken, value: result.access);
        if (result.refresh != null && result.refresh!.isNotEmpty) {
          await _secureStorage.write(
              key: AppStorageKeys.refreshToken, value: result.refresh);
        }
        ApiClient.instance.setBearer(result.access);
      }
      // Network failure must not log the user out.
      return result.outcome;
    } catch (_) {
      return RefreshOutcome.networkFailure;
    }
  }

  void _onSessionExpired() {
    logout();
  }

  Future<void> _persistTokens(AuthResult result) async {
    if (result.token != null) {
      await _secureStorage.write(
          key: AppStorageKeys.accessToken, value: result.token);
      ApiClient.instance.setBearer(result.token);
    }
    if (result.refreshToken != null) {
      await _secureStorage.write(
          key: AppStorageKeys.refreshToken, value: result.refreshToken);
    }
    if (result.user != null && result.user!.id.isNotEmpty) {
      await _secureStorage.write(
          key: AppStorageKeys.userId, value: result.user!.id);
    }
  }

  /// Delete account remotely when backend is on. Network failure does not invent success.
  Future<bool> deleteAccount() async {
    try {
      if (AppApi.isBackendEnabled) {
        final ok = await _repository.deleteAccount();
        if (!ok) return false;
      }
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }

  CachedProfile cachedProfile({required bool networkOnline}) {
    return CachedProfile(
      user: state.user,
      serverValidated: networkOnline && state.isAuthenticated,
    );
  }
}

@immutable
class CachedProfile {
  const CachedProfile({this.user, this.serverValidated = false});

  final AppUser? user;
  final bool serverValidated;
}

// ============================================================
// SECTION 6: AUTH PROVIDER
// ============================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(secureStorage);
});

// ============================================================
// SECTION 7: CONVENIENCE PROVIDERS
// ============================================================

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});

final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.name ?? 'Guest';
});

final isPremiumUserProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPremium ?? false;
});

// Is the app in guest mode (backend disabled or not logged in)
final isGuestModeProvider = Provider<bool>((ref) {
  return !ref.watch(isAuthenticatedProvider);
});
