// lib/shared/widgets/controls/app_switch_tile.dart
// ===========================================================
// QIBRA AI — FUTURE-PROOF SWITCH LIST TILE
//
// Uses WidgetStateProperty for thumb/track color (Flutter 3.27+
// compatible) instead of the deprecated activeTrackColor /
// inactiveTrackColor / activeColor parameters on Switch/SwitchListTile.
// ===========================================================
import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';

class AppSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final Color? activeColor;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const AppSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.activeColor,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final accent = activeColor ?? colors.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textTertiary;
            }
            if (states.contains(WidgetState.selected)) {
              return colors.onPrimary;
            }
            return colors.textSecondary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.cardMuted.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.selected)) {
              return accent;
            }
            return colors.cardMuted;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return colors.border;
          }),
          trackOutlineWidth: WidgetStateProperty.all(1.5),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
        secondary: secondary,
        dense: dense,
        contentPadding: contentPadding,
      ),
    );
  }
}
