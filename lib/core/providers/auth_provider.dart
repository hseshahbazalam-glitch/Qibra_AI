// lib/core/providers/auth_provider.dart

// ============================================================
// QIBRA AI — AUTHENTICATION PROVIDER
// Version: 1.0.0
// Description: Complete auth state management using Riverpod.
//              Login, logout, register, token management,
//              user info tracking — all reactive.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/providers/app_providers.dart';

// ============================================================
// SECTION 1: AUTH STATE ENUM
// ============================================================
// Auth ki 4 possible states — clear aur type-safe
// ============================================================

enum AuthStatus {
  /// Initial state — abhi check nahi kiya
  initial,

  /// Currently checking auth state (splash pe)
  loading,

  /// User authenticated hai — logged in
  authenticated,

  /// User authenticated nahi hai — logged out
  unauthenticated,
}

// ============================================================
// SECTION 2: USER MODEL
// ============================================================
// User ki basic info hold karne ke liye
// Baad mein real backend user model se replace hoga
// ============================================================

/// User information model
@immutable
class AppUser {
  /// User ka unique ID
  final String id;

  /// User ka email
  final String email;

  /// User ka full name
  final String name;

  /// Profile picture URL (optional)
  final String? avatarUrl;

  /// Phone number (optional)
  final String? phoneNumber;

  /// Account created date
  final DateTime? createdAt;

  /// Is email verified?
  final bool isEmailVerified;

  /// Is premium user?
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

  /// Copy karo with new values
  /// State update ke liye zaroori
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

  /// JSON se AppUser banao
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
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  /// AppUser ko JSON mein convert karo
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
// Complete auth state — status + user + error
// ============================================================

@immutable
class AuthState {
  /// Current auth status
  final AuthStatus status;

  /// Logged in user (null agar logged out)
  final AppUser? user;

  /// Error message (null agar koi error nahi)
  final String? errorMessage;

  /// Loading flag for async operations
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Initial state factory
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Loading state factory
  factory AuthState.loading() {
    return const AuthState(
      status: AuthStatus.loading,
      isLoading: true,
    );
  }

  /// Authenticated state factory
  factory AuthState.authenticated(AppUser user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  /// Unauthenticated state factory
  factory AuthState.unauthenticated({String? error}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: error,
    );
  }

  /// Copy karo with new values
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

  /// Convenience getters
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => errorMessage != null;
}

// ============================================================
// SECTION 4: AUTH NOTIFIER (State Manager)
// ============================================================
// StateNotifier = state ko update karne wali class
// UI se calls aayenge yahan
// Yeh state update karega
// ============================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._secureStorage) : super(AuthState.initial()) {
    // Constructor mein automatically check karo login state
    _checkAuthStatus();
  }

  // ── AUTH CHECK ─────────────────────────────────────────
  /// App startup pe check karo — token hai ya nahi
  Future<void> _checkAuthStatus() async {
    state = AuthState.loading();

    try {
      // Secure storage se token nikalo
      final token = await _secureStorage.read(
        key: AppStorageKeys.accessToken,
      );

      if (token != null && token.isNotEmpty) {
        // Token hai — user logged in
        // Real app mein yahan token verify + user fetch hoga
        // Abhi ke liye dummy user banao
        final user = AppUser(
          id: '1',
          email: 'user@qibra.ai',
          name: 'QIBRA User',
          createdAt: DateTime.now(),
          isEmailVerified: true,
        );
        state = AuthState.authenticated(user);
      } else {
        // Token nahi hai — logged out
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated(
        error: 'Auth check failed: ${e.toString()}',
      );
    }
  }

  // ── LOGIN ──────────────────────────────────────────────
  /// Email/Password se login karo
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Real app mein yahan API call hogi
      // Abhi ke liye simulate karte hain
      await Future.delayed(const Duration(seconds: 1));

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password required');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 6) {
        throw Exception('Password too short');
      }

      // Simulate successful login
      const fakeToken = 'fake_jwt_token_xyz123';
      const fakeRefreshToken = 'fake_refresh_token_abc456';

      // Tokens save karo secure storage mein
      await _secureStorage.write(
        key: AppStorageKeys.accessToken,
        value: fakeToken,
      );
      await _secureStorage.write(
        key: AppStorageKeys.refreshToken,
        value: fakeRefreshToken,
      );

      // User info banao
      final user = AppUser(
        id: '1',
        email: email,
        name: email.split('@').first,
        createdAt: DateTime.now(),
        isEmailVerified: true,
      );

      // State update karo
      state = AuthState.authenticated(user);
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
  /// New user register karo
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (name.length < 2) {
        throw Exception('Name too short');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      // Simulate registration
      const fakeToken = 'fake_jwt_token_new_user';
      await _secureStorage.write(
        key: AppStorageKeys.accessToken,
        value: fakeToken,
      );

      final user = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
        isEmailVerified: false,
      );

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────
  /// Current user ko logout karo
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Secure storage clear karo
      await _secureStorage.delete(
        key: AppStorageKeys.accessToken,
      );
      await _secureStorage.delete(
        key: AppStorageKeys.refreshToken,
      );
      await _secureStorage.delete(
        key: AppStorageKeys.userId,
      );

      // State reset karo
      state = AuthState.unauthenticated();
    } catch (e) {
      // Even if error — force logout
      state = AuthState.unauthenticated();
    }
  }

  // ── UPDATE USER ────────────────────────────────────────
  /// User info update karo (profile edit ke baad)
  void updateUser(AppUser updatedUser) {
    if (state.isAuthenticated) {
      state = state.copyWith(user: updatedUser);
    }
  }

  // ── CLEAR ERROR ────────────────────────────────────────
  /// Error message clear karo
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ── REFRESH TOKEN ──────────────────────────────────────
  /// Token expire ho gaya to refresh karo
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: AppStorageKeys.refreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        // Refresh token nahi hai — logout karo
        await logout();
        return false;
      }

      // Real app mein API call hogi
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate new token
      const newToken = 'refreshed_fake_token';
      await _secureStorage.write(
        key: AppStorageKeys.accessToken,
        value: newToken,
      );

      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }
}

// ============================================================
// SECTION 5: AUTH PROVIDER
// ============================================================
// Main provider jo AuthNotifier ko expose karta hai
// UI mein iske through auth state access hoga
// ============================================================

/// Auth state provider
/// StateNotifierProvider = notifier ka result state hai
///
/// Usage:
///   final authState = ref.watch(authProvider);
///   final auth = ref.read(authProvider.notifier);
///
///   // State access
///   if (authState.isAuthenticated) { ... }
///
///   // Actions
///   await auth.login(email: '...', password: '...');
///   await auth.logout();
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(secureStorage);
});

// ============================================================
// SECTION 6: CONVENIENCE PROVIDERS
// ============================================================
// Alag alag auth data ke liye specific providers
// UI mein specific value chahiye — poori state nahi
// ============================================================

/// Is user authenticated? (boolean)
///
/// Usage:
///   final isAuth = ref.watch(isAuthenticatedProvider);
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Current logged in user (null if not logged in)
///
/// Usage:
///   final user = ref.watch(currentUserProvider);
///   Text(user?.name ?? 'Guest');
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is auth loading?
///
/// Usage:
///   final isLoading = ref.watch(authLoadingProvider);
///   if (isLoading) return CircularProgressIndicator();
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Current auth error message (null if no error)
///
/// Usage:
///   final error = ref.watch(authErrorProvider);
///   if (error != null) return Text(error);
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});

/// User's display name (fallback: "Guest")
///
/// Usage:
///   final name = ref.watch(userDisplayNameProvider);
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.name ?? 'Guest';
});

/// Is current user premium?
///
/// Usage:
///   final isPremium = ref.watch(isPremiumUserProvider);
final isPremiumUserProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPremium ?? false;
});
