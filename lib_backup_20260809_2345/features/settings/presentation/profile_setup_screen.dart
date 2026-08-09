// lib/features/settings/presentation/profile_setup_screen.dart

// ============================================================
// QIBRA AI — PROFILE SETUP SCREEN (Phase 5 Final)
// Version: 1.0.0
// Description: Premium profile setup with avatar, personal info,
//              and Islamic preferences. Completes Phase 5.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// PROFILE SETUP SCREEN
// ============================================================

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with TickerProviderStateMixin {
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
  String _selectedCountryFlag = '🇵🇰';
  String _selectedMadhab = 'Hanafi';
  String _selectedPrayerMethod = 'Karachi';
  bool _hasAvatar = false;
  bool _isLoading = false;

  // ── ANIMATIONS ───────────────────────────────────────
  late AnimationController _particleController;
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  // ── COUNTRY LIST ─────────────────────────────────────
  final List<Map<String, String>> _countries = [
    {'name': 'Pakistan', 'flag': '🇵🇰', 'code': '+92'},
    {'name': 'India', 'flag': '🇮🇳', 'code': '+91'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦', 'code': '+966'},
    {'name': 'UAE', 'flag': '🇦🇪', 'code': '+971'},
    {'name': 'Turkey', 'flag': '🇹🇷', 'code': '+90'},
    {'name': 'Egypt', 'flag': '🇪🇬', 'code': '+20'},
    {'name': 'Indonesia', 'flag': '🇮🇩', 'code': '+62'},
    {'name': 'Malaysia', 'flag': '🇲🇾', 'code': '+60'},
    {'name': 'Bangladesh', 'flag': '🇧🇩', 'code': '+880'},
    {'name': 'United Kingdom', 'flag': '🇬🇧', 'code': '+44'},
    {'name': 'United States', 'flag': '🇺🇸', 'code': '+1'},
    {'name': 'Canada', 'flag': '🇨🇦', 'code': '+1'},
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

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cityFocus.dispose();
    _particleController.dispose();
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
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
                  color: Colors.white.withValues(alpha: 0.30),
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
                        _mockAvatarUpload('Camera');
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
                        _mockAvatarUpload('Gallery');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Remove option (if avatar exists)
              if (_hasAvatar) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.selectionClick();
                    setState(() => _hasAvatar = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'Remove Photo',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.20),
              AppColors.primary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mockAvatarUpload(String source) {
    HapticFeedback.heavyImpact();
    setState(() => _hasAvatar = true);
    _avatarController.reset();
    _avatarController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Photo selected from $source'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
      ),
    );
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
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.6,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
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
                  color: Colors.white.withValues(alpha: 0.30),
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
                          _selectedCountryFlag = country['flag']!;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.sm,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.20),
                                    AppColors.primary.withValues(alpha: 0.10),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: AppSpacing.md),
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
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
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
      ),
    );
  }

  // ── HANDLERS ─────────────────────────────────────────

  Future<void> _handleSave() async {
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
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text('Profile setup complete!'),
              ],
            ),
            backgroundColor: AppColors.success,
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildParticles(size),
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
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF0D3320),
              Color(0xFF0A1628),
              AppColors.background,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════

  Widget _buildParticles(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ProfileParticlePainter(
              animationValue: _particleController.value,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  '3',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ' / 3 · Profile',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
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
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.30),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.40),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: _hasAvatar
                      ? Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.emerald,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        )
                      : ShaderMask(
                          shaderCallback: (bounds) =>
                              AppGradients.emerald.createShader(bounds),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 48,
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
                    gradient: AppGradients.gold,
                    border: Border.all(
                      color: AppColors.background,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.40),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.background,
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
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.emerald.createShader(bounds),
          child: Text(
            'ALMOST THERE',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
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
              color: AppColors.textSecondary,
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
    return ClipRRect(
      borderRadius: AppRadius.cardRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Section title
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PERSONAL INFORMATION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
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
                icon: Icons.flag_outlined,
                value: '$_selectedCountryFlag  $_selectedCountry',
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
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TEXT FIELD
  // ══════════════════════════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isFocused ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          filled: true,
          fillColor: isFocused
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PICKER FIELD (Date, Country)
  // ══════════════════════════════════════════

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          value != null ? Colors.white : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // GENDER SELECTOR
  // ══════════════════════════════════════════

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildGenderOption('male', 'Male', Icons.male_rounded),
            const SizedBox(width: AppSpacing.sm),
            _buildGenderOption('female', 'Female', Icons.female_rounded),
            const SizedBox(width: AppSpacing.sm),
            _buildGenderOption('other', 'Other', Icons.transgender_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedGender = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.30),
                      AppColors.primary.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.02),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.10),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ISLAMIC PREFS CARD
  // ══════════════════════════════════════════

  Widget _buildIslamicPrefsCard() {
    return ClipRRect(
      borderRadius: AppRadius.cardRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.10),
                AppColors.accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Section title
              Row(
                children: [
                  const Icon(
                    Icons.mosque_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ISLAMIC PREFERENCES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Madhab
              _buildDropdown(
                label: 'Madhab',
                icon: Icons.school_outlined,
                value: _selectedMadhab,
                items: const [
                  'Hanafi',
                  'Shafi',
                  'Maliki',
                  'Hanbali',
                ],
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMadhab = val!);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Prayer Method
              _buildDropdown(
                label: 'Prayer Calculation Method',
                icon: Icons.access_time_rounded,
                value: _selectedPrayerMethod,
                items: const [
                  'Karachi',
                  'ISNA',
                  'MWL',
                  'Egypt',
                  'Makkah',
                ],
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPrayerMethod = val!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // DROPDOWN
  // ══════════════════════════════════════════

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: AppColors.surface,
        icon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ACTIONS (Save + Skip)
  // ══════════════════════════════════════════

  Widget _buildActions() {
    return Column(
      children: [
        // Save button
        GestureDetector(
          onTap: _isLoading ? null : _handleSave,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.60),
                        AppColors.primaryDark.withValues(alpha: 0.60),
                      ],
                    )
                  : AppGradients.emerald,
              borderRadius: AppRadius.buttonRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Save & Continue',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Skip button
        GestureDetector(
          onTap: _isLoading ? null : _handleSkip,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Skip for now',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PARTICLE PAINTER
// ============================================================

class _ProfileParticlePainter extends CustomPainter {
  final double animationValue;

  _ProfileParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(88);

    for (int i = 0; i < 22; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      final particleSize = 1.5 + random.nextDouble() * 2;
      final isGold = i % 3 == 0;
      final color = isGold ? AppColors.accent : AppColors.primary;
      final alpha = 0.15 + (random.nextDouble() * 0.25);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 4,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ProfileParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue;
}
