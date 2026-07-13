// lib/core/providers/app_providers.dart

// ============================================================
// QIBRA AI — CORE APP PROVIDERS
// Version: 1.0.0
// Description: Base Riverpod providers for the entire app.
//              SharedPreferences, SecureStorage, Connectivity,
//              PackageInfo, and app initialization state.
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// SECTION 1: SHARED PREFERENCES PROVIDER
// ============================================================
// SharedPreferences = simple key-value local storage
// Use: User preferences, settings, flags
// Data persist rehta hai app close hone par bhi
// ============================================================

/// SharedPreferences instance provider
/// Async hai kyunki initialization mein time lagta hai
///
/// Usage in widget:
///   final prefs = ref.watch(sharedPreferencesProvider);
///   prefs.when(
///     data: (p) => p.setBool('key', true),
///     loading: () => CircularProgressIndicator(),
///     error: (e, s) => Text('Error'),
///   );
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ============================================================
// SECTION 2: SECURE STORAGE PROVIDER
// ============================================================
// FlutterSecureStorage = encrypted storage
// Use: JWT tokens, passwords, sensitive data
// iOS: Keychain, Android: EncryptedSharedPreferences
// ============================================================

/// FlutterSecureStorage instance provider
/// Synchronous — instant access
///
/// Usage:
///   final storage = ref.read(secureStorageProvider);
///   await storage.write(key: 'token', value: 'xyz123');
///   final token = await storage.read(key: 'token');
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    // Android specific options
    aOptions: AndroidOptions(
      // EncryptedSharedPreferences use karo
      encryptedSharedPreferences: true,
    ),
    // iOS specific options
    iOptions: IOSOptions(
      // First unlock ke baad hi accessible
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

// ============================================================
// SECTION 3: PACKAGE INFO PROVIDER
// ============================================================
// PackageInfo = app ki metadata (version, build number)
// Runtime pe access karne ke liye
// ============================================================

/// Package info async provider
/// App version, build number, package name
///
/// Usage:
///   final info = ref.watch(packageInfoProvider);
///   info.when(
///     data: (i) => Text('v${i.version}'),
///     loading: () => Text('...'),
///     error: (e, s) => Text('Error'),
///   );
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// ============================================================
// SECTION 4: CONNECTIVITY PROVIDER
// ============================================================
// Connectivity = internet connection status
// StreamProvider = value continuously change hoti hai
// Automatically updates jab internet gaya/aaya
// ============================================================

/// Connectivity status stream provider
/// Real-time internet status
///
/// Usage:
///   final connectivity = ref.watch(connectivityProvider);
///   connectivity.when(
///     data: (result) {
///       final isOnline = result.first != ConnectivityResult.none;
///       return isOnline ? OnlineWidget() : OfflineBanner();
///     },
///     loading: () => SizedBox(),
///     error: (e, s) => SizedBox(),
///   );
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Simple boolean provider — is internet available?
/// Convenience wrapper around connectivityProvider
///
/// Usage:
///   final isOnline = ref.watch(isOnlineProvider);
///   if (!isOnline) return OfflineBanner();
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) {
      // Agar koi bhi connection type ho (wifi, mobile, ethernet)
      return results.any(
        (result) => result != ConnectivityResult.none,
      );
    },
    // Default true — connection assume karo
    orElse: () => true,
  );
});

// ============================================================
// SECTION 5: APP INITIALIZATION PROVIDER
// ============================================================
// App startup pe sab kuch initialize karta hai
// SharedPreferences, PackageInfo dono ready hone chahiye
// ============================================================

/// App initialization state
/// Sab providers ready hone tak wait karta hai
///
/// Usage in splash screen:
///   final initState = ref.watch(appInitializationProvider);
///   initState.when(
///     data: (_) => context.go(AppRoutes.home),
///     loading: () => LoadingScreen(),
///     error: (e, s) => ErrorScreen(),
///   );
final appInitializationProvider = FutureProvider<AppInitState>((ref) async {
  // Wait for all critical async providers
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final packageInfo = await ref.watch(packageInfoProvider.future);

  return AppInitState(
    prefs: prefs,
    packageInfo: packageInfo,
  );
});

/// App initialization state model
class AppInitState {
  final SharedPreferences prefs;
  final PackageInfo packageInfo;

  const AppInitState({
    required this.prefs,
    required this.packageInfo,
  });
}

// ============================================================
// SECTION 6: APP LIFECYCLE PROVIDER
// ============================================================
// App state changes track karta hai
// Foreground, Background, Paused, Resumed
// ============================================================

/// Current app lifecycle state
/// StateProvider = simple mutable state
///
/// Usage:
///   final appState = ref.watch(appLifecycleProvider);
///   if (appState == AppLifecycleState.paused) {
///     // Save data before backgrounding
///   }
final appLifecycleProvider = StateProvider<AppLifecycleStatus>((ref) {
  return AppLifecycleStatus.resumed;
});

/// App lifecycle states enum
enum AppLifecycleStatus {
  /// App visible aur user interact kar raha hai
  resumed,

  /// App visible hai but user interact nahi kar raha
  inactive,

  /// App background mein hai
  paused,

  /// App terminate ho gayi
  detached,

  /// App hidden hai
  hidden,
}
