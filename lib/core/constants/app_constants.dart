// lib/core/constants/app_constants.dart

// ============================================================
// QIBRA AI — APP CONSTANTS
// Version: 1.0.0
// Description: Single source of truth for all fixed values.
//              App info, API, Storage, Islamic data,
//              Validation, Cache, and Feature flags.
//              Nothing is hardcoded anywhere else in the app.
// ============================================================

// ============================================================
// LIBRARY ROOT — the eleven constant classes live in parts/.
// app_constants.dart remains the ONE public import surface: every
// 'package:qibra_ai/core/constants/app_constants.dart' consumer sees
// the same classes, members and values — zero behavior change.
// ============================================================

part 'parts/app_info.dart';
part 'parts/app_api.dart';
part 'parts/app_storage_keys.dart';
part 'parts/app_pagination.dart';
part 'parts/app_islamic_constants.dart';
part 'parts/app_validation.dart';
part 'parts/app_cache_duration.dart';
part 'parts/app_feature_flags.dart';
part 'parts/app_ui_constants.dart';
part 'parts/app_languages.dart';
part 'parts/app_routes.dart';
