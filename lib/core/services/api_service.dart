// lib/core/services/api_service.dart

// ============================================================
// QIBRA AI — API SERVICE
// Version: 1.0.0
// Description: High-level API service that wraps DioClient.
//              All backend endpoints exposed as clean methods.
//              Type-safe, easy to use, easy to test.
// ============================================================

import 'package:dio/dio.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/network/dio_client.dart';

// ============================================================
// SECTION 1: API SERVICE CLASS
// ============================================================
// Poori app mein sirf ek instance hoga (via GetIt)
// Har feature ke endpoints yahan grouped hain
// ============================================================

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // ══════════════════════════════════════════
  // AUTH ENDPOINTS
  // ══════════════════════════════════════════

  /// Login with email and password
  ///
  /// Throws [ApiException] on failure.
  /// Returns response data (token, user info).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointLogin,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data ?? {};
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
    return response.data ?? {};
  }

  /// Logout current user
  Future<void> logout() async {
    await _dioClient.post(AppApi.endpointLogout);
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointRefreshToken,
      data: {'refresh_token': refreshToken},
    );
    return response.data ?? {};
  }

  /// Send forgot password email
  Future<void> forgotPassword({required String email}) async {
    await _dioClient.post(
      AppApi.endpointForgotPassword,
      data: {'email': email},
    );
  }

  /// Reset password with OTP/token
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _dioClient.post(
      AppApi.endpointResetPassword,
      data: {
        'email': email,
        'token': token,
        'new_password': newPassword,
      },
    );
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointVerifyOtp,
      data: {
        'email': email,
        'otp': otp,
      },
    );
    return response.data ?? {};
  }

  /// Resend OTP code
  Future<void> resendOtp({required String email}) async {
    await _dioClient.post(
      AppApi.endpointResendOtp,
      data: {'email': email},
    );
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointGoogleAuth,
      data: {'id_token': idToken},
    );
    return response.data ?? {};
  }

  /// Sign in with Apple
  Future<Map<String, dynamic>> appleAuth({
    required String idToken,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointAppleAuth,
      data: {'id_token': idToken},
    );
    return response.data ?? {};
  }

  // ══════════════════════════════════════════
  // USER ENDPOINTS
  // ══════════════════════════════════════════

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointProfile,
    );
    return response.data ?? {};
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final response = await _dioClient.put<Map<String, dynamic>>(
      AppApi.endpointUpdateProfile,
      data: {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return response.data ?? {};
  }

  /// Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dioClient.put(
      AppApi.endpointUpdatePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Delete user account
  Future<void> deleteAccount({required String password}) async {
    await _dioClient.delete(
      AppApi.endpointDeleteAccount,
      data: {'password': password},
    );
  }

  /// Upload avatar image
  ///
  /// [filePath] = local file path
  /// Returns uploaded URL
  Future<String> uploadAvatar({required String filePath}) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointUploadAvatar,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.data?['url']?.toString() ?? '';
  }

  // ══════════════════════════════════════════
  // PRAYER ENDPOINTS
  // ══════════════════════════════════════════

  /// Get prayer times for a location
  Future<Map<String, dynamic>> getPrayerTimes({
    required double latitude,
    required double longitude,
    int method = 1, // Karachi default
    DateTime? date,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointPrayerTimes,
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'method': method,
        if (date != null) 'date': date.toIso8601String().split('T').first,
      },
    );
    return response.data ?? {};
  }

  /// Get Qibla direction from a location
  Future<Map<String, dynamic>> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQiblaDirection,
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
      },
    );
    return response.data ?? {};
  }

  /// Get nearby mosques
  Future<List<dynamic>> getNearbyMosques({
    required double latitude,
    required double longitude,
    double radius = 5000,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointNearbyMosques,
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radius': radius,
      },
    );
    return response.data?['mosques'] as List<dynamic>? ?? [];
  }

  // ══════════════════════════════════════════
  // QURAN ENDPOINTS
  // ══════════════════════════════════════════

  /// Get all Surahs list
  Future<List<dynamic>> getSurahs() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQuranSurahs,
    );
    return response.data?['surahs'] as List<dynamic>? ?? [];
  }

  /// Get ayahs of a specific surah
  Future<Map<String, dynamic>> getSurahAyahs({
    required int surahNumber,
    String? translationCode,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '${AppApi.endpointQuranAyahs}/$surahNumber',
      queryParameters: {
        if (translationCode != null) 'translation': translationCode,
      },
    );
    return response.data ?? {};
  }

  /// Search in Quran
  Future<List<dynamic>> searchQuran({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQuranSearch,
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      },
    );
    return response.data?['results'] as List<dynamic>? ?? [];
  }

  /// Get audio recitation URL for a surah
  Future<String> getSurahAudio({
    required int surahNumber,
    required String reciterId,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '${AppApi.endpointQuranAudio}/$surahNumber',
      queryParameters: {'reciter': reciterId},
    );
    return response.data?['audio_url']?.toString() ?? '';
  }

  /// Get available translations list
  Future<List<dynamic>> getTranslations() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQuranTranslations,
    );
    return response.data?['translations'] as List<dynamic>? ?? [];
  }

  /// Get user's Quran bookmarks
  Future<List<dynamic>> getBookmarks() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQuranBookmarks,
    );
    return response.data?['bookmarks'] as List<dynamic>? ?? [];
  }

  /// Add a bookmark
  Future<void> addBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    await _dioClient.post(
      AppApi.endpointQuranBookmarks,
      data: {
        'surah': surahNumber,
        'ayah': ayahNumber,
      },
    );
  }

  /// Remove a bookmark
  Future<void> removeBookmark({required String bookmarkId}) async {
    await _dioClient.delete(
      '${AppApi.endpointQuranBookmarks}/$bookmarkId',
    );
  }

  /// Save last read position
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    await _dioClient.post(
      AppApi.endpointQuranLastRead,
      data: {
        'surah': surahNumber,
        'ayah': ayahNumber,
      },
    );
  }

  /// Get last read position
  Future<Map<String, dynamic>> getLastRead() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointQuranLastRead,
    );
    return response.data ?? {};
  }

  // ══════════════════════════════════════════
  // HADITH ENDPOINTS
  // ══════════════════════════════════════════

  /// Get all hadith collections
  Future<List<dynamic>> getHadithCollections() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointHadithCollections,
    );
    return response.data?['collections'] as List<dynamic>? ?? [];
  }

  /// Get books of a collection
  Future<List<dynamic>> getHadithBooks({
    required String collectionId,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '${AppApi.endpointHadithBooks}/$collectionId',
    );
    return response.data?['books'] as List<dynamic>? ?? [];
  }

  /// Search hadiths
  Future<List<dynamic>> searchHadith({
    required String query,
    String? collectionId,
    int page = 1,
    int limit = 15,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointHadithSearch,
      queryParameters: {
        'q': query,
        if (collectionId != null) 'collection': collectionId,
        'page': page,
        'limit': limit,
      },
    );
    return response.data?['results'] as List<dynamic>? ?? [];
  }

  /// Get daily hadith
  Future<Map<String, dynamic>> getDailyHadith() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointHadithDaily,
    );
    return response.data ?? {};
  }

  /// Get user's hadith bookmarks
  Future<List<dynamic>> getHadithBookmarks() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointHadithBookmarks,
    );
    return response.data?['bookmarks'] as List<dynamic>? ?? [];
  }

  // ══════════════════════════════════════════
  // AI CHAT ENDPOINTS
  // ══════════════════════════════════════════

  /// Send message to AI
  Future<Map<String, dynamic>> sendAiMessage({
    required String message,
    String? conversationId,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointAiChat,
      data: {
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    return response.data ?? {};
  }

  /// Get AI chat history
  Future<List<dynamic>> getAiChatHistory({
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointAiChatHistory,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data?['messages'] as List<dynamic>? ?? [];
  }

  /// Ask Islamic question to AI
  Future<Map<String, dynamic>> askIslamicQuestion({
    required String question,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      AppApi.endpointAiIslamicQuestion,
      data: {'question': question},
    );
    return response.data ?? {};
  }

  // ══════════════════════════════════════════
  // DUA ENDPOINTS
  // ══════════════════════════════════════════

  /// Get dua categories
  Future<List<dynamic>> getDuaCategories() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointDuaCategories,
    );
    return response.data?['categories'] as List<dynamic>? ?? [];
  }

  /// Get duas in a category
  Future<List<dynamic>> getDuas({
    String? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointDuaList,
      queryParameters: {
        if (categoryId != null) 'category': categoryId,
        'page': page,
        'limit': limit,
      },
    );
    return response.data?['duas'] as List<dynamic>? ?? [];
  }

  /// Get user's favorite duas
  Future<List<dynamic>> getFavoriteDuas() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointDuaFavorites,
    );
    return response.data?['favorites'] as List<dynamic>? ?? [];
  }

  // ══════════════════════════════════════════
  // CALENDAR ENDPOINTS
  // ══════════════════════════════════════════

  /// Get Hijri date for gregorian date
  Future<Map<String, dynamic>> getHijriDate({
    DateTime? gregorianDate,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointHijriDate,
      queryParameters: {
        if (gregorianDate != null)
          'date': gregorianDate.toIso8601String().split('T').first,
      },
    );
    return response.data ?? {};
  }

  /// Get Islamic events
  Future<List<dynamic>> getIslamicEvents({
    int? hijriYear,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointIslamicEvents,
      queryParameters: {
        if (hijriYear != null) 'year': hijriYear,
      },
    );
    return response.data?['events'] as List<dynamic>? ?? [];
  }

  /// Get Ramadan calendar
  Future<Map<String, dynamic>> getRamadanCalendar({
    required int year,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointRamadanCalendar,
      queryParameters: {
        'year': year,
        'lat': latitude,
        'lng': longitude,
      },
    );
    return response.data ?? {};
  }

  // ══════════════════════════════════════════
  // NOTIFICATION ENDPOINTS
  // ══════════════════════════════════════════

  /// Get user notifications
  Future<List<dynamic>> getNotifications({
    int page = 1,
    int limit = 25,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointNotifications,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data?['notifications'] as List<dynamic>? ?? [];
  }

  /// Mark notification as read
  Future<void> markNotificationRead({
    required String notificationId,
  }) async {
    await _dioClient.post(
      '${AppApi.endpointNotificationRead}/$notificationId',
    );
  }

  /// Register FCM device token
  Future<void> registerDevice({
    required String fcmToken,
    required String deviceType,
  }) async {
    await _dioClient.post(
      AppApi.endpointRegisterDevice,
      data: {
        'fcm_token': fcmToken,
        'device_type': deviceType,
      },
    );
  }

  // ══════════════════════════════════════════
  // TASBIH ENDPOINTS
  // ══════════════════════════════════════════

  /// Save tasbih count
  Future<void> saveTasbihCount({
    required String dhikr,
    required int count,
  }) async {
    await _dioClient.post(
      AppApi.endpointTasbihSave,
      data: {
        'dhikr': dhikr,
        'count': count,
      },
    );
  }

  /// Get tasbih history
  Future<List<dynamic>> getTasbihHistory() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      AppApi.endpointTasbihHistory,
    );
    return response.data?['history'] as List<dynamic>? ?? [];
  }
}
