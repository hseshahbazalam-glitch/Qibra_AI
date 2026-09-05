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
    return TextFormField(
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
          fillColor: isFocused ? colors.cardMuted : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.border,
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
          _patchUi(() => _selectedGender = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.cardMuted,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
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
                  _patchUi(() => _selectedMadhab = val!);
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
                  _patchUi(() => _selectedPrayerMethod = val!);
                },
              ),
            ],
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
              color: _isLoading
                  ? colors.primary.withValues(alpha: 0.60)
                  : colors.primary,
              borderRadius: AppRadius.buttonRadiusLg,
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black87,
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
