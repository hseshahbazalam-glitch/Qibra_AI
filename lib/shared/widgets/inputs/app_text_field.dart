// lib/shared/widgets/inputs/app_text_field.dart

// ============================================================
// QIBRA AI — REUSABLE INPUT FIELD COMPONENTS
// Version: 1.0.0
// Description: All input field types for QIBRA AI.
//              Standard, Password, Search, OTP, TextArea.
//              Validation states, focus animations,
//              error/success states — production ready.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// SECTION 1: APP TEXT FIELD (Standard)
// ============================================================
// General purpose text input
// Use: Name, Email, Any general input
// ============================================================

class AppTextField extends StatefulWidget {
  /// Controller — input ki value control karta hai
  final TextEditingController? controller;

  /// Label text (floating label)
  final String label;

  /// Hint text (placeholder)
  final String? hint;

  /// Helper text (below field)
  final String? helperText;

  /// Error message (validation fail hone par)
  final String? errorText;

  /// Success message (validation pass hone par)
  final String? successText;

  /// Left side icon
  final IconData? prefixIcon;

  /// Right side icon
  final IconData? suffixIcon;

  /// Suffix icon press handler
  final VoidCallback? onSuffixTap;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Text input action (next, done, search)
  final TextInputAction textInputAction;

  /// Focus node — programmatically focus control karne ke liye
  final FocusNode? focusNode;

  /// Field change callback
  final ValueChanged<String>? onChanged;

  /// Field submit callback
  final ValueChanged<String>? onSubmitted;

  /// Validation function
  /// Returns error string agar invalid, null agar valid
  final String? Function(String?)? validator;

  /// Read only mode
  final bool readOnly;

  /// Enabled/disabled
  final bool enabled;

  /// Max length
  final int? maxLength;

  /// Auto validate on change
  final bool autoValidate;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.successText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.autoValidate = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  // Internal focus node — agar external nahi diya to yeh use hoga
  late FocusNode _focusNode;

  // Animation controller — focus/blur animation ke liye
  late AnimationController _animationController;

  // Border color animation
  late Animation<Color?> _borderColorAnimation;

  // Focus state track karna
  bool _isFocused = false;

  // Internal validation error
  String? _validationError;

  @override
  void initState() {
    super.initState();

    // External ya internal focus node
    _focusNode = widget.focusNode ?? FocusNode();

    // Animation controller — 200ms
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );

    // Border color: unfocused (standard) → focused (emerald)
    _borderColorAnimation = ColorTween(
      begin: AppColors.borderStandard,
      end: AppColors.borderFocus,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.standard,
      ),
    );

    // Focus listener — focus change hone par animation play karo
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      // Focus mila — animate forward
      _animationController.forward();
    } else {
      // Focus gaya — animate reverse
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    // Agar humne internal focus node banaya to dispose karo
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  // Validation run karna
  void _validate(String value) {
    if (widget.validator != null) {
      setState(() {
        _validationError = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error decide karo — external ya internal
    final String? displayError = widget.errorText ?? _validationError;

    // Current border color
    final bool hasError = displayError != null;
    final bool hasSuccess = widget.successText != null && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input Field ──────────────────────────────
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (_isFocused
                        ? AppColors.inputFocused
                        : AppColors.inputBackground)
                    : AppColors.inputBackground.withValues(alpha: 0.50),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: hasError
                      ? AppColors.borderError
                      : hasSuccess
                          ? AppColors.success.withValues(alpha: 0.70)
                          : _borderColorAnimation.value ??
                              AppColors.borderStandard,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                // Focus hone par subtle glow
                boxShadow: _isFocused && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : hasError
                        ? [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.08),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                maxLength: widget.maxLength,
                style: AppTextStyles.inputText,
                // Remove default counter
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                decoration: InputDecoration(
                  // Remove default border (humara custom hai)
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,

                  // Label
                  labelText: widget.label,
                  labelStyle: AppTextStyles.inputLabel.copyWith(
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
                    fontSize: 11,
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textTertiary,
                  ),

                  // Hint
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.inputHint,

                  // Prefix icon
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: hasError
                              ? AppColors.error.withValues(alpha: 0.70)
                              : _isFocused
                                  ? AppColors.primary
                                  : AppColors.iconSecondary,
                          size: AppIconSizes.md,
                        )
                      : null,

                  // Suffix icon
                  suffixIcon: _buildSuffixIcon(hasError),

                  // Content padding
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),

                  // Remove fill (humara custom background hai)
                  filled: false,
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (widget.autoValidate) {
                    _validate(value);
                  }
                },
                onSubmitted: (value) {
                  _validate(value);
                  widget.onSubmitted?.call(value);
                },
              ),
            );
          },
        ),

        // ── Helper / Error / Success Text ────────────
        if (displayError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildStatusText(
            text: displayError,
            color: AppColors.error,
            icon: Icons.error_outline,
          ),
        ] else if (hasSuccess) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildStatusText(
            text: widget.successText!,
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.helperText!,
            style: AppTextStyles.labelSmall.secondary,
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(bool hasError) {
    // Error icon
    if (hasError) {
      return const Icon(
        Icons.error_outline,
        color: AppColors.error,
        size: AppIconSizes.md,
      );
    }

    // Success icon
    if (widget.successText != null) {
      return const Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: AppIconSizes.md,
      );
    }

    // Custom suffix
    if (widget.suffixIcon != null) {
      return GestureDetector(
        onTap: widget.onSuffixTap,
        child: Icon(
          widget.suffixIcon,
          color: _isFocused ? AppColors.primary : AppColors.iconSecondary,
          size: AppIconSizes.md,
        ),
      );
    }

    return null;
  }

  Widget _buildStatusText({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: AppIconSizes.xs),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.errorText.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION 2: APP PASSWORD FIELD
// ============================================================
// Password input with show/hide toggle
// Use: Login, Register, Change Password
// ============================================================

class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool autoValidate;
  final bool enabled;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint,
    this.errorText,
    this.helperText,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autoValidate = false,
    this.enabled = true,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;

  bool _isFocused = false;
  bool _isObscured = true; // Password hidden by default
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _borderColorAnimation = ColorTween(
      begin: AppColors.borderStandard,
      end: AppColors.borderFocus,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.standard,
      ),
    );
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      setState(() => _validationError = widget.validator!(value));
    }
  }

  // Password visibility toggle
  void _toggleObscure() {
    HapticFeedback.selectionClick();
    setState(() => _isObscured = !_isObscured);
  }

  @override
  Widget build(BuildContext context) {
    final String? displayError = widget.errorText ?? _validationError;
    final bool hasError = displayError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (_isFocused
                        ? AppColors.inputFocused
                        : AppColors.inputBackground)
                    : AppColors.inputBackground.withValues(alpha: 0.50),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: hasError
                      ? AppColors.borderError
                      : _borderColorAnimation.value ?? AppColors.borderStandard,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                boxShadow: _isFocused && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: _isObscured,
                textInputAction: widget.textInputAction,
                enabled: widget.enabled,
                style: AppTextStyles.inputText,
                // obscuringCharacter — password dots
                obscuringCharacter: '●',
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  labelText: widget.label,
                  labelStyle: AppTextStyles.inputLabel.copyWith(
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
                    fontSize: 11,
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textTertiary,
                  ),
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: hasError
                        ? AppColors.error.withValues(alpha: 0.70)
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.iconSecondary,
                    size: AppIconSizes.md,
                  ),
                  // Show/hide password toggle
                  suffixIcon: GestureDetector(
                    onTap: _toggleObscure,
                    child: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.iconSecondary,
                      size: AppIconSizes.md,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  filled: false,
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (widget.autoValidate) _validate(value);
                },
                onSubmitted: (value) {
                  _validate(value);
                  widget.onSubmitted?.call(value);
                },
              ),
            );
          },
        ),
        if (displayError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: AppIconSizes.xs),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(displayError, style: AppTextStyles.errorText),
            ),
          ]),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.helperText!, style: AppTextStyles.labelSmall.secondary),
        ],
      ],
    );
  }
}

// ============================================================
// SECTION 3: APP SEARCH FIELD
// ============================================================
// Search input with clear button and search icon
// Use: Quran search, Hadith search, Global search
// ============================================================

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: _isFocused ? AppColors.inputFocused : AppColors.inputBackground,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: _isFocused ? AppColors.borderFocus : AppColors.borderStandard,
          width: _isFocused ? 2.0 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.hint,
          hintStyle: AppTextStyles.inputHint,
          // Search icon (left)
          prefixIcon: Icon(
            Icons.search,
            color: _isFocused ? AppColors.primary : AppColors.iconSecondary,
            size: AppIconSizes.md,
          ),
          // Clear button (right) — sirf tab dikhao jab text ho
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.iconSecondary,
                    size: AppIconSizes.md,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          filled: false,
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

// ============================================================
// SECTION 4: APP OTP FIELD
// ============================================================
// 6-digit OTP input — auto advance between boxes
// Use: Phone verification, Email OTP
// ============================================================

class AppOtpField extends StatefulWidget {
  /// OTP length (default: 6)
  final int otpLength;

  /// OTP complete hone par callback
  final ValueChanged<String>? onCompleted;

  /// OTP change hone par callback
  final ValueChanged<String>? onChanged;

  /// Error message
  final String? errorText;

  const AppOtpField({
    super.key,
    this.otpLength = 6,
    this.onCompleted,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  // Har box ke liye alag controller aur focus node
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.otpLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Current OTP string
  String get _currentOtp => _controllers.map((c) => c.text).join();

  // Ek box ki value change hone par
  void _onBoxChanged(int index, String value) {
    if (value.length == 1) {
      // Value dali — next box pe jaao
      if (index < widget.otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last box — keyboard band karo
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty) {
      // Value hatayi — previous box pe jaao
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final otp = _currentOtp;
    widget.onChanged?.call(otp);

    // Sab boxes full hone par complete callback
    if (otp.length == widget.otpLength) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.otpLength,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index < widget.otpLength - 1 ? AppSpacing.sm : 0,
              ),
              child: _OtpBox(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                hasError: widget.errorText != null,
                onChanged: (value) => _onBoxChanged(index, value),
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: AppIconSizes.xs),
              const SizedBox(width: AppSpacing.xs),
              Text(widget.errorText!, style: AppTextStyles.errorText),
            ],
          ),
        ],
      ],
    );
  }
}

// Single OTP box widget
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused ? AppColors.inputFocused : AppColors.inputBackground,
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(
          color: widget.hasError
              ? AppColors.borderError
              : _isFocused
                  ? AppColors.borderFocus
                  : AppColors.borderStandard,
          width: _isFocused ? 2.0 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        // Sirf ek character allow karo
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyles.titleMedium.copyWith(
          color: _isFocused ? AppColors.primary : AppColors.textPrimary,
        ),
        // Input formatters — sirf digits
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '', // Counter hide karo
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ============================================================
// SECTION 5: APP TEXT AREA
// ============================================================
// Multi-line text input
// Use: Message, Feedback, Bio, Description
// ============================================================

class AppTextArea extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool autoValidate;
  final bool enabled;

  const AppTextArea({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.maxLines = 5,
    this.minLines = 3,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.autoValidate = false,
    this.enabled = true,
  });

  @override
  State<AppTextArea> createState() => _AppTextAreaState();
}

class _AppTextAreaState extends State<AppTextArea>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late TextEditingController _controller;

  bool _isFocused = false;
  String? _validationError;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _borderColorAnimation = ColorTween(
      begin: AppColors.borderStandard,
      end: AppColors.borderFocus,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppCurves.standard,
      ),
    );
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      setState(() => _validationError = widget.validator!(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? displayError = widget.errorText ?? _validationError;
    final bool hasError = displayError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (_isFocused
                        ? AppColors.inputFocused
                        : AppColors.inputBackground)
                    : AppColors.inputBackground.withValues(alpha: 0.50),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: hasError
                      ? AppColors.borderError
                      : _borderColorAnimation.value ?? AppColors.borderStandard,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                boxShadow: _isFocused && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                enabled: widget.enabled,
                style: AppTextStyles.inputText,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  labelText: widget.label,
                  labelStyle: AppTextStyles.inputLabel.copyWith(
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
                    fontSize: 11,
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.textTertiary,
                  ),
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.inputHint,
                  contentPadding: const EdgeInsets.all(
                    AppSpacing.lg,
                  ),
                  filled: false,
                  counterText: '',
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (widget.autoValidate) _validate(value);
                },
              ),
            );
          },
        ),

        // Bottom row: error + char count
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              // Error or helper
              Expanded(
                child: displayError != null
                    ? Row(children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: AppIconSizes.xs),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(displayError,
                              style: AppTextStyles.errorText),
                        ),
                      ])
                    : widget.helperText != null
                        ? Text(widget.helperText!,
                            style: AppTextStyles.labelSmall.secondary)
                        : const SizedBox.shrink(),
              ),

              // Character counter
              if (widget.maxLength != null)
                Text(
                  '$_charCount/${widget.maxLength}',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: _charCount > (widget.maxLength ?? 0)
                        ? AppColors.error
                        : AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION 6: APP DROPDOWN FIELD
// ============================================================
// Dropdown selection field
// Use: Language selection, Prayer method, Gender
// ============================================================

class AppDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final String? hint;
  final IconData? prefixIcon;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.errorText,
    this.hint,
    this.prefixIcon,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: _isOpen ? AppColors.inputFocused : AppColors.inputBackground,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: hasError
                  ? AppColors.borderError
                  : _isOpen
                      ? AppColors.borderFocus
                      : AppColors.borderStandard,
              width: _isOpen ? 2.0 : 1.0,
            ),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: widget.value,
            items: widget.items,
            onChanged: widget.onChanged,
            onTap: () => setState(() => _isOpen = !_isOpen),
            style: AppTextStyles.inputText,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: _isOpen ? AppColors.primary : AppColors.iconSecondary,
            ),
            dropdownColor: AppColors.surfaceHigh,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              labelText: widget.label,
              labelStyle: AppTextStyles.inputLabel,
              floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
                fontSize: 11,
                color: _isOpen ? AppColors.primary : AppColors.textTertiary,
              ),
              hintText: widget.hint,
              hintStyle: AppTextStyles.inputHint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: AppColors.iconSecondary,
                      size: AppIconSizes.md,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              filled: false,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: AppIconSizes.xs),
            const SizedBox(width: AppSpacing.xs),
            Text(widget.errorText!, style: AppTextStyles.errorText),
          ]),
        ],
      ],
    );
  }
}
