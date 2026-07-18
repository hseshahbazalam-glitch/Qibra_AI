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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Simple boolean provider — is internet available?
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) {
      return results.any(
        (result) => result != ConnectivityResult.none,
      );
    },
    orElse: () => true,
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
