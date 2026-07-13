// lib/core/di/service_locator.dart

// ============================================================
// QIBRA AI — SERVICE LOCATOR (Dependency Injection)
// Version: 1.0.0
// Description: GetIt-based service locator for the entire app.
//              Register all singletons and services here.
//              Access from anywhere: sl<ServiceType>()
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibra_ai/core/network/dio_client.dart';
import 'package:qibra_ai/core/services/api_service.dart';

// ============================================================
// SECTION 1: GLOBAL SERVICE LOCATOR INSTANCE
// ============================================================
// 'sl' = short for 'service locator'
// Poori app mein isse services access honge
//
// Usage:
//   final apiService = sl<ApiService>();
//   await sl<ApiService>().login(...);
// ============================================================

/// Global GetIt instance
/// Short alias for easy usage throughout the app
final GetIt sl = GetIt.instance;

// ============================================================
// SECTION 2: SERVICE LOCATOR SETUP
// ============================================================

class ServiceLocator {
  // Private constructor — koi object nahi bana sakta
  ServiceLocator._();

  /// Initialize all services
  /// main.dart se call hoga app start pe
  ///
  /// Usage in main.dart:
  ///   await ServiceLocator.init();
  ///   runApp(...);
  static Future<void> init() async {
    // Debug mode mein log dikhao
    if (kDebugMode) {
      debugPrint('🔧 ServiceLocator initializing...');
    }

    try {
      // Register services in dependency order
      // Jo dusron pe depend karta hai, woh baad mein register hoga

      await _registerExternalServices();
      _registerCoreServices();
      _registerNetworkServices();
      _registerFeatureServices();

      if (kDebugMode) {
        debugPrint('✅ ServiceLocator initialized successfully');
        _printRegisteredServices();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ ServiceLocator initialization failed: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }

  // ══════════════════════════════════════════
  // EXTERNAL SERVICES (Third-party)
  // ══════════════════════════════════════════
  // Yeh services async initialize hoti hain
  // ══════════════════════════════════════════

  static Future<void> _registerExternalServices() async {
    // ── SharedPreferences ────────────────────────────────
    // Local key-value storage
    // registerSingletonAsync = async initialization
    // Ya seedha instance register kar sakte hain (better)
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(
      () => sharedPreferences,
    );

    // ── FlutterSecureStorage ─────────────────────────────
    // Encrypted storage for tokens
    // Instant initialization
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // CORE SERVICES (App-level utilities)
  // ══════════════════════════════════════════

  static void _registerCoreServices() {
    // Yahan future mein add hoga:
    // - Logger service
    // - Analytics service
    // - Crash reporting service
    // - Cache manager
  }

  // ══════════════════════════════════════════
  // NETWORK SERVICES (HTTP, API)
  // ══════════════════════════════════════════

  static void _registerNetworkServices() {
    // ── DioClient ────────────────────────────────────────
    // HTTP client wrapper with interceptors
    // SecureStorage pe depend karta hai (token access)
    sl.registerLazySingleton<DioClient>(
      () => DioClient(sl<FlutterSecureStorage>()),
    );

    // ── ApiService ───────────────────────────────────────
    // High-level API endpoints
    // DioClient pe depend karta hai
    sl.registerLazySingleton<ApiService>(
      () => ApiService(sl<DioClient>()),
    );
  }

  // ══════════════════════════════════════════
  // FEATURE SERVICES (Domain-specific)
  // ══════════════════════════════════════════

  static void _registerFeatureServices() {
    // Yahan future mein add hoga:
    // - AuthRepository
    // - QuranRepository
    // - PrayerRepository
    // - HadithRepository
    // - LocationService
    // - NotificationService
  }

  // ══════════════════════════════════════════
  // RESET (For testing or logout)
  // ══════════════════════════════════════════

  /// Reset all services
  /// Testing mein useful — fresh state ke liye
  static Future<void> reset() async {
    await sl.reset();
    if (kDebugMode) {
      debugPrint('🔄 ServiceLocator reset complete');
    }
  }

  /// Reset and re-initialize
  /// Complete restart for services
  static Future<void> resetAndInit() async {
    await reset();
    await init();
  }

  // ══════════════════════════════════════════
  // DEBUG HELPERS
  // ══════════════════════════════════════════

  /// Print all registered services (debug only)
  static void _printRegisteredServices() {
    debugPrint('┌─── Registered Services ────────────────');
    debugPrint('│ ✓ SharedPreferences');
    debugPrint('│ ✓ FlutterSecureStorage');
    debugPrint('│ ✓ DioClient');
    debugPrint('│ ✓ ApiService');
    debugPrint('└────────────────────────────────────────');
  }

  /// Check if a service is registered
  /// Useful for conditional logic
  static bool isRegistered<T extends Object>() {
    return sl.isRegistered<T>();
  }
}

// ============================================================
// SECTION 3: CONVENIENCE ACCESSORS
// ============================================================
// Type-safe shortcuts for common services
// Optional — sl<Type>() bhi kaam karta hai
// ============================================================

/// Get SharedPreferences instance
SharedPreferences get prefs => sl<SharedPreferences>();

/// Get SecureStorage instance
FlutterSecureStorage get secureStorage => sl<FlutterSecureStorage>();

/// Get DioClient instance
DioClient get dioClient => sl<DioClient>();

/// Get ApiService instance
ApiService get apiService => sl<ApiService>();
