// lib/core/constants/parts/app_validation.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 6: VALIDATION CONSTANTS
// ============================================================
// Form validation ke liye rules aur patterns
// Regex patterns = input format check karne ke liye
// ============================================================

abstract final class AppValidation {
  // --- Length Limits ---

  /// Minimum password length
  static const int passwordMinLength = 8;

  /// Maximum password length
  static const int passwordMaxLength = 32;

  /// Minimum name length
  static const int nameMinLength = 2;

  /// Maximum name length
  static const int nameMaxLength = 50;

  /// Maximum email length
  static const int emailMaxLength = 100;

  /// Maximum bio length
  static const int bioMaxLength = 200;

  /// OTP length (6 digits)
  static const int otpLength = 6;

  /// Maximum AI chat message length
  static const int aiChatMaxLength = 500;

  /// Maximum search query length
  static const int searchMaxLength = 100;

  // --- Regex Patterns ---
  // Regex = Regular Expression — input format check karne ka pattern
  // ^ = start, $ = end, + = one or more, * = zero or more
  // [a-z] = any lowercase letter, \d = any digit

  /// Valid email pattern
  /// Example valid: user@example.com, user.name@domain.co.uk
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Strong password pattern
  /// Must have: uppercase, lowercase, number, special char, 8+ chars
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Phone number pattern (international format)
  /// Example: +923001234567, +14155552671
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');

  /// Name pattern — only letters, spaces, hyphens
  static final RegExp nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']{2,50}$");

  /// OTP pattern — exactly 6 digits
  static final RegExp otpRegex = RegExp(r'^\d{6}$');

  /// URL pattern
  static final RegExp urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  // --- Error Messages ---

  /// Required field error
  static const String errorRequired = 'This field is required';

  /// Invalid email error
  static const String errorEmail = 'Please enter a valid email address';

  /// Weak password error
  static const String errorPassword =
      'Password must be 8+ chars with uppercase, lowercase, number & special character';

  /// Password too short error
  static const String errorPasswordShort =
      'Password must be at least 8 characters';

  /// Passwords don't match error
  static const String errorPasswordMatch = 'Passwords do not match';

  /// Invalid phone error
  static const String errorPhone =
      'Please enter a valid phone number with country code';

  /// Invalid name error
  static const String errorName = 'Name must be 2-50 characters (letters only)';

  /// Invalid OTP error
  static const String errorOtp = 'Please enter a valid 6-digit OTP';

  /// Name too short error
  static const String errorNameShort = 'Name must be at least 2 characters';

  /// Text too long error
  static String errorTooLong(int max) => 'Maximum $max characters allowed';
}
