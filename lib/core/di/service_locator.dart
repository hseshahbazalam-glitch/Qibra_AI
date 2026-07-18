// lib/core/di/service_locator.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibra_ai/core/network/dio_client.dart';
import 'package:qibra_ai/core/services/api_service.dart';
import 'package:qibra_ai/core/services/storage_service.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  ServiceLocator._();

  static Future<void> init() async {
    if (kDebugMode) {
      debugPrint('🔧 ServiceLocator initializing...');
    }

    try {
      await _registerExternalServices();
      _registerCoreServices();
      _registerNetworkServices();

      if (kDebugMode) {
        debugPrint('✅ ServiceLocator initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ServiceLocator failed: $e');
      }
      rethrow;
    }
  }

  static Future<void> _registerExternalServices() async {
    if (!sl.isRegistered<SharedPreferences>()) {
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<SharedPreferences>(prefs);
      if (kDebugMode) debugPrint('  ✅ SharedPreferences registered');
    }

    if (!sl.isRegistered<FlutterSecureStorage>()) {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      sl.registerSingleton<FlutterSecureStorage>(secureStorage);
      if (kDebugMode) debugPrint('  ✅ FlutterSecureStorage registered');
    }
  }

  static void _registerCoreServices() {
    if (!sl.isRegistered<StorageService>()) {
      sl.registerLazySingleton<StorageService>(
        () => StorageService(),
      );
      if (kDebugMode) debugPrint('  ✅ StorageService registered');
    }
  }

  static void _registerNetworkServices() {
    if (!sl.isRegistered<DioClient>()) {
      sl.registerLazySingleton<DioClient>(
        () => DioClient(sl<FlutterSecureStorage>()),
      );
      if (kDebugMode) debugPrint('  ✅ DioClient registered');
    }

    if (!sl.isRegistered<ApiService>()) {
      sl.registerLazySingleton<ApiService>(
        () => ApiService(sl<DioClient>()),
      );
      if (kDebugMode) debugPrint('  ✅ ApiService registered');
    }
  }

  static Future<void> reset() async {
    await sl.reset();
    if (kDebugMode) debugPrint('🔄 ServiceLocator reset');
  }

  static bool isRegistered<T extends Object>() {
    return sl.isRegistered<T>();
  }
}
