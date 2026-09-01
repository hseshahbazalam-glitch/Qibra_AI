// lib/shared/widgets/qibra_stat_card.dart
// ============================================================
// QIBRA AI — SHARED STAT CARD (Stage A)
// Promoted from the hand-rolled twins in Home (HomeTodayStats
// ._StatCard) and the Quran tab (._MiniStat). One rhythm: 12dp
// card padding, 18px emerald icon, headline number, tertiary
// unit, secondary footnote. Color budget: icon/progress are
// ALWAYS primary emerald (owner rule — no orange/gold in stat
// trios); meaning never relies on color alone.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/design_system/app_typography.dart';
import '../../core/design_system/qibra_colors.dart';
import 'qibra_ui.dart';

class QibraStatCard extends StatelessWidget {
  const QibraStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.footnote,
    this.progress,
  });

  final IconData icon;
  final String value;

  /// Small tertiary line directly under [value] (e.g. "days").
  final String? unit;

  /// Two-line secondary description (what the number means).
  final String label;

  /// Optional override for the trailing line (else [label]).
  final String? footnote;

  /// Optional 0..1 progress bar (daily goals).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.labelSmall.copyWith(color: colors.textTertiary),
            ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            footnote ?? label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.labelSmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
