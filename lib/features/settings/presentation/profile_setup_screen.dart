// lib/features/settings/presentation/profile_setup_screen.dart

// ============================================================
// QIBRA AI — PROFILE SETUP SCREEN (Phase 5 Final)
// Version: 1.0.0
// Description: Premium profile setup with avatar, personal info,
//              and Islamic preferences. Completes Phase 5.
// ============================================================


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

part 'profile_setup_screen.form.dart';

// ============================================================
// PROFILE SETUP SCREEN
// ============================================================

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  /// Pure path shape (Windows separators normalized) — unit-tested.
  static String avatarDestPath(String appSupportRoot) {
    return '${appSupportRoot.replaceAll('\\', '/')}/profile/avatar.jpg';
  }

  /// Pure pick semantics — unit-tested: a null result (user cancelled or
  /// the pick/copy failed) NEVER changes the stored path.
  static String? nextAvatarPath({
    required String? current,
    required String? pickedAndStored,
  }) {
    return pickedAndStored ?? current;
  }

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with TickerProviderStateMixin {
  // (Rev) Part-file widget builders live in extensions, and the
  // analyzer treats setState as protected — this thin in-class wrapper
  // keeps their updates legal with zero runtime difference.
  void _patchUi(VoidCallback fn) => setState(fn);

  // ── FORM ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cityFocus = FocusNode();

  bool _isNameFocused = false;
  bool _isPhoneFocused = false;
  bool _isCityFocused = false;

  // ── STATE ────────────────────────────────────────────
  DateTime? _dateOfBirth;
  String _selectedGender = 'male';
  String _selectedCountry = 'Pakistan';
  String _selectedMadhab = 'Hanafi';
  String _selectedPrayerMethod = 'Karachi';
  /// Path of the REAL stored avatar file, or null when none exists.
  /// The single source of truth: UI state mirrors the filesystem, never
  /// the other way around.
  String? _avatarPath;
  bool _isLoading = false;

  // ── ANIMATIONS ───────────────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  // ── COUNTRY LIST ─────────────────────────────────────
  final List<Map<String, String>> _countries = [
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'UAE', 'code': '+971'},
    {'name': 'Turkey', 'code': '+90'},
    {'name': 'Egypt', 'code': '+20'},
    {'name': 'Indonesia', 'code': '+62'},
    {'name': 'Malaysia', 'code': '+60'},
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'Canada', 'code': '+1'},
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill name (in real app, from register)
    _nameController.text = 'User';

    // Focus listeners
    _nameFocus.addListener(() {
      setState(() => _isNameFocused = _nameFocus.hasFocus);
      if (_nameFocus.hasFocus) HapticFeedback.selectionClick();
    });
    _phoneFocus.addListener(() {
      setState(() => _isPhoneFocused = _phoneFocus.hasFocus);
      if (_phoneFocus.hasFocus) HapticFeedback.selectionClick();
    });
    _cityFocus.addListener(() {
      setState(() => _isCityFocused = _cityFocus.hasFocus);
      if (_cityFocus.hasFocus) HapticFeedback.selectionClick();
    });

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeIn,
      ),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Avatar
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _avatarScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarController,
        curve: Curves.elasticOut,
      ),
    );

    _entranceController.forward();
    _avatarController.forward();
    _loadStoredAvatar();
  }

  /// Read the avatar back from its stored file at init — what the screen
  /// shows is what the app-internal storage actually holds.
  Future<void> _loadStoredAvatar() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final path = ProfileSetupScreen.avatarDestPath(dir.path);
      if (await File(path).exists() && mounted) {
        setState(() => _avatarPath = path);
      }
    } catch (e) {
      debugPrint('\u26a0\ufe0f profile avatar load failed: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cityFocus.dispose();
    _entranceController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  // ── VALIDATORS ───────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name too short';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (value.length < 8) {
      return 'Enter valid phone number';
    }
    return null;
  }

  // ── AVATAR PICKER ────────────────────────────────────

  void _handleAvatarPick() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvatarPickerSheet(),
    );
  }

  Widget _buildAvatarPickerSheet() {
    final colors = QibraColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Choose Photo',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Options
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        pickAvatar(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        pickAvatar(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Remove option — visible only when a REAL file exists, and
              // it deletes that file before the state changes.
              if (_avatarPath != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.selectionClick();
                    _removeAvatar();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'Remove Photo',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: colors.primary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real avatar selection via image_picker (already a dependency — no
  /// new package, no manifest edits, no cloud upload). Rules:
  ///   • cancel (null) → NOTHING happens — cancel is not an error;
  ///   • success → the bytes are copied into app-internal storage and the
  ///     UI updates from that real file — a success toast is only ever
  ///     shown after a verified stored file;
  ///   • failure (permission denied, copy error) → the real error text is
  ///     shown and the stored avatar state stays exactly as it was.
  Future<void> pickAvatar(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return; // user cancelled — no toast, no state change
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw StateError('the picked file was empty');
      final dir = await getApplicationSupportDirectory();
      final dest = ProfileSetupScreen.avatarDestPath(dir.path);
      await File(dest).parent.create(recursive: true);
      final tmp = File('$dest.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      // staged copy verified non-empty, then atomic-ish swap
      if (await tmp.length() > 0) {
        if (await File(dest).exists()) await File(dest).delete();
        await tmp.rename(dest);
      } else {
        await tmp.delete();
        throw StateError('could not store the avatar file');
      }
      if (!mounted) return;
      final stored =
          ProfileSetupScreen.nextAvatarPath(current: _avatarPath, pickedAndStored: dest);
      setState(() => _avatarPath = stored);
      _avatarController.reset();
      _avatarController.forward();
      final colors = QibraColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: QibraNavy.textPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Photo selected from '
                '${source == ImageSource.camera ? 'Camera' : 'Gallery'}',
              ),
            ],
          ),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
    } catch (e) {
      // Honest failure copy; the existing avatar state is untouched.
      debugPrint('\u26a0\ufe0f profile avatar pick failed: $e');
      if (!mounted) return;
      final colors = QibraColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar not changed — $e'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
    }
  }

  /// Delete the stored file first; only on a real delete does the UI
  /// drop the avatar. A failed delete keeps the avatar (the file exists).
  Future<void> _removeAvatar() async {
    final path = _avatarPath;
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('\u26a0\ufe0f profile avatar delete failed: $e');
      if (!mounted) return;
      final colors = QibraColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo still stored — delete failed: $e'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
      return; // state unchanged — the file is genuinely still there
    }
    if (!mounted) return;
    setState(() => _avatarPath = null);
  }

  // ── DATE PICKER ──────────────────────────────────────

  Future<void> _pickDateOfBirth() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: QibraColors.of(context).primary,
              onPrimary: Colors.white,
              surface: QibraColors.of(context).surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  // ── COUNTRY PICKER ───────────────────────────────────

  void _pickCountry() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCountryPickerSheet(),
    );
  }

  Widget _buildCountryPickerSheet() {
    final colors = QibraColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.6,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
        ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select Country',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final isSelected = _selectedCountry == country['name'];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCountry = country['name']!;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.sm,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : Colors.white.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                country['name']!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              country['code']!,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.check_circle,
                                color: colors.primary,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ── HANDLERS ─────────────────────────────────────────

  Future<void> _handleSave() async {
    final colors = QibraColors.of(context);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: QibraNavy.textPrimary,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text('Profile setup complete!'),
              ],
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius,
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _handleSkip() {
    HapticFeedback.selectionClick();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _entranceFade,
              child: SlideTransition(
                position: _entranceSlide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xl2),
                      _buildAvatarSection(),
                      const SizedBox(height: AppSpacing.xl2),
                      _buildTitle(),
                      const SizedBox(height: AppSpacing.xl2),
                      Form(
                        key: _formKey,
                        child: _buildFormCard(),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      _buildIslamicPrefsCard(),
                      const SizedBox(height: AppSpacing.xl2),
                      _buildActions(),
                      const SizedBox(height: AppSpacing.xl2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildBackground() {
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.cardMuted,
              border: Border.all(color: colors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: QibraNavy.textPrimary,
              size: 20,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.cardMuted,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '3',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / 3 · Profile',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // AVATAR SECTION
  // ══════════════════════════════════════════

  Widget _buildAvatarSection() {
    final colors = QibraColors.of(context);
    return Center(
      child: GestureDetector(
        onTap: _handleAvatarPick,
        child: ScaleTransition(
          scale: _avatarScale,
          child: Stack(
            children: [
              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.card,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.24),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _avatarPath == null
                      ? const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: QibraNavy.textPrimary,
                          size: 48,
                        )
                      // The REAL picked photo; the icon fallback only
                      // renders if the stored file fails to decode.
                      : Container(
                          width: 100,
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                          child: Image.file(
                            File(_avatarPath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person_rounded,
                              color: QibraNavy.textPrimary,
                              size: 60,
                            ),
                          ),
                        ),
                ),
              ),

              // Camera button
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent,
                    border: Border.all(
                      color: colors.background,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: colors.background,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TITLE
  // ══════════════════════════════════════════

  Widget _buildTitle() {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Text(
          'ALMOST THERE',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.primary,
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Complete Your Profile',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Personalize your Islamic experience',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // FORM CARD (Personal Info)
  // ══════════════════════════════════════════

  Widget _buildFormCard() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
          child: Column(
            children: [
              // Section title
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PERSONAL INFORMATION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.primary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Name
              _buildTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                isFocused: _isNameFocused,
                label: 'Full Name',
                hint: 'Enter your name',
                icon: Icons.person_outline_rounded,
                validator: _validateName,
              ),

              const SizedBox(height: AppSpacing.md),

              // Phone
              _buildTextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                isFocused: _isPhoneFocused,
                label: 'Phone (Optional)',
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),

              const SizedBox(height: AppSpacing.md),

              // Date of Birth
              _buildPickerField(
                label: 'Date of Birth',
                icon: Icons.calendar_today_rounded,
                value: _dateOfBirth != null
                    ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                    : null,
                placeholder: 'Select date',
                onTap: _pickDateOfBirth,
              ),

              const SizedBox(height: AppSpacing.md),

              // Gender
              _buildGenderSelector(),

              const SizedBox(height: AppSpacing.md),

              // Country
              _buildPickerField(
                label: 'Country',
                icon: Icons.public_rounded,
                value: _selectedCountry,
                placeholder: 'Select country',
                onTap: _pickCountry,
              ),

              const SizedBox(height: AppSpacing.md),

              // City
              _buildTextField(
                controller: _cityController,
                focusNode: _cityFocus,
                isFocused: _isCityFocused,
                label: 'City (Optional)',
                hint: 'Enter your city',
                icon: Icons.location_city_rounded,
                validator: null,
              ),
            ],
          ),
    );
  }

  // ══════════════════════════════════════════
  // TEXT FIELD
  // ══════════════════════════════════════════

}