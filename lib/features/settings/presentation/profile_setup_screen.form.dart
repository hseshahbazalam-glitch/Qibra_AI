// QIBRA AI — PROFILE SETUP SCREEN (form widgets + particles part)

part of 'profile_setup_screen.dart';


// ══════════════════════════════════════════════════════════
// Moved by Stage 3 file split — same library (part file),
// private classes/fields still resolve. Behavior unchanged.
// ══════════════════════════════════════════════════════════

extension _ProfileSetupFormWidgets on _ProfileSetupScreenState {
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
    final colors = QibraColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.30),
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
          color: QibraNavy.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: colors.textTertiary,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isFocused ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? colors.primary : colors.textSecondary,
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
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.error,
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
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colors.textSecondary,
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
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          value != null ? Colors.white : colors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.textTertiary,
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
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
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
                      colors.primary.withValues(alpha: 0.30),
                      colors.primary.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.02),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : Colors.white.withValues(alpha: 0.10),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      isSelected ? colors.primary : colors.textSecondary,
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
    final colors = QibraColors.of(context);
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
                colors.accent.withValues(alpha: 0.10),
                colors.accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Section title
              Row(
                children: [
                  Icon(
                    Icons.mosque_rounded,
                    color: colors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ISLAMIC PREFERENCES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.accent,
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: colors.surface,
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: colors.textSecondary,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: QibraNavy.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: colors.textSecondary,
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
                color: QibraNavy.textPrimary,
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
    final colors = QibraColors.of(context);
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
                        colors.primary.withValues(alpha: 0.60),
                        colors.primary.withValues(alpha: 0.60),
                      ],
                    )
                  : AppGradients.emerald,
              borderRadius: AppRadius.buttonRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.50),
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
                          color: QibraNavy.textPrimary,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Save & Continue',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: QibraNavy.textPrimary,
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
                color: colors.textSecondary,
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
      final color = isGold ? QibraNavy.gold : QibraNavy.emeraldDeep;
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
