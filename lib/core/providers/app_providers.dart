// lib/core/providers/app_providers.dart

// ============================================================
// QIBRA AI — CORE APP PROVIDERS
// Version: 3.0.0
// Description: Base Riverpod providers for the entire app.
//              SharedPreferences, SecureStorage, Connectivity,
//              PackageInfo, and app initialization state.
//              NOTE: onboardingProvider is in theme_provider.dart
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/quran/data/repository/quran_repository.dart';
import '../constants/app_constants.dart';
import '../offline/data_status.dart';
import '../offline/reachability.dart';
import '../services/notification_service.dart';

// ============================================================
// SECTION 1: SHARED PREFERENCES PROVIDER
// ============================================================

/// SharedPreferences instance provider
/// Async — initialization time lagta hai
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ============================================================
// SECTION 2: SECURE STORAGE PROVIDER
// ============================================================

/// FlutterSecureStorage instance provider
/// Synchronous — instant access
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

// ============================================================
// SECTION 3: PACKAGE INFO PROVIDER
// ============================================================

/// Package info async provider
/// App version, build number, package name
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// ============================================================
// SECTION 4: CONNECTIVITY PROVIDER
// ============================================================

/// Connectivity status stream provider
/// Real-time internet status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final reachabilityProvider = Provider<ReachabilityState>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) {
      return ReachabilityMapper.fromConnectivityLabels(
        results.map((r) => r.name),
      );
    },
    orElse: () => const ReachabilityState(Reachability.unknown),
  );
});

/// Simple boolean provider — unknown is NOT online.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(reachabilityProvider).isOnline;
});

/// Transport online ≠ Qibra API healthy. Health is never assumed.
final serviceAvailabilityProvider = Provider<ServiceAvailability>((ref) {
  return ServiceAvailability(
    reachability: ref.watch(reachabilityProvider),
    backendEnabled: AppApi.isBackendEnabled,
    backendHealthy: false,
  );
});

// ============================================================
// SECTION 5: APP INITIALIZATION PROVIDER
// ============================================================

/// App initialization state model
class AppInitState {
  final SharedPreferences prefs;
  final PackageInfo packageInfo;

  const AppInitState({
    required this.prefs,
    required this.packageInfo,
  });
}

/// App initialization provider
/// Waits for all critical async providers
final appInitializationProvider = FutureProvider<AppInitState>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final packageInfo = await ref.watch(packageInfoProvider.future);

  return AppInitState(
    prefs: prefs,
    packageInfo: packageInfo,
  );
});

// ============================================================
// SECTION 5.5: DATA BOOTSTRAP (perf pass item 2, owner 2026-09-05)
// ============================================================

/// Boot work that used to be `await`ed in main() BEFORE runApp — Quran
/// corpus decode and notification-service init — runs HERE, started by
/// the splash's first frame, so the first frame never waits on data.
/// Every screen stays independently safe through its own initialization
/// (quranInitProvider / lazy repository init; hadith keeps loading
/// unawaited in main as before). Errors are logged, never rethrown —
/// the splash watches this provider for its REAL loading→ready state,
/// which is exactly what replaces the old decorative spinner (no fake
/// progress, owner rule).
final dataBootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    () async {
      try {
        await NotificationService().initialize();
        debugPrint('✅ Notification Service ready');
      } catch (e) {
        debugPrint('⚠️ Notification Service failed: $e');
      }
    }(),
    () async {
      try {
        await QuranRepository().initialize();
        debugPrint('✅ Quran data loaded successfully!');
      } catch (e) {
        debugPrint('⚠️ Quran data loading failed: $e');
      }
    }(),
  ]);
});

// ============================================================
// SECTION 6: APP LIFECYCLE PROVIDER
// ============================================================

/// App lifecycle states enum
enum AppLifecycleStatus {
  resumed,
  inactive,
  paused,
  detached,
  hidden,
}

/// Current app lifecycle state
final appLifecycleProvider = StateProvider<AppLifecycleStatus>((ref) {
  return AppLifecycleStatus.resumed;
});
