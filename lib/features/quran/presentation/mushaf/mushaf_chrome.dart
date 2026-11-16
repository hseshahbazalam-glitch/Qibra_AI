// lib/features/quran/presentation/mushaf/mushaf_chrome.dart
// ============================================================
// QIBRA AI — MUSHAF CHROME (Pass M, item 4)
//
// The settled chrome, dressed for a book instead of a settings form:
//  • MushafPageMedallion — the page counter set inside a code-drawn
//    rosette (double rule + four corner diamonds), same tappable
//    behaviour as the flat pill it replaces, same '$page / 604' text
//    the pins already know.
//  • MushafJuzChip — the juz number that already exists in the top
//    bar's second line, re-cut as a marker chip. NO new data: every
//    field is what the page index already carries (ayah.juz, from the
//    authentic alquran.cloud per-page table).
// All paint is vector + tokens; no hex literals, no assets.
// ============================================================

import 'package:flutter/material.dart';

import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';

class MushafPageMedallion extends StatelessWidget {
  const MushafPageMedallion({
    super.key,
    required this.pageLabel,
    required this.onTap,
  });

  final String pageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _RosettePainter(
          border: colors.border,
          // D2 mapping: gilding reads antique-gold deep on paper,
          // AppGold on the navy surface (context-probed — no flag
          // threading through the chrome).
          gild: QibraPaper.isActive(context)
              ? QibraPaper.gild
              : AppGold.s500,
          fill: colors.cardMuted,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 11),
          child: Text(
            pageLabel,
            style: AppTextStyles.labelLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter({
    required this.border,
    required this.gild,
    required this.fill,
  });

  final Color border;
  final Color gild;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(outer, Paint()..color = fill);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(3.5),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..color = gild.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Four corner diamonds — the classic illuminated-rule marker.
    final diamonds = Paint()..color = gild.withValues(alpha: 0.85);
    for (final c in [
      Offset(size.width / 2, 1.5),
      Offset(size.width / 2, size.height - 1.5),
      Offset(4.5, size.height / 2),
      Offset(size.width - 4.5, size.height / 2),
    ]) {
      final p = Path()
        ..moveTo(c.dx, c.dy - 3)
        ..lineTo(c.dx + 3, c.dy)
        ..lineTo(c.dx, c.dy + 3)
        ..lineTo(c.dx - 3, c.dy)
        ..close();
      canvas.drawPath(p, diamonds);
    }
  }

  @override
  bool shouldRepaint(_RosettePainter old) =>
      old.border != border || old.gild != gild || old.fill != fill;
}

/// Static marker chip (not a control — tap does nothing, so it is NOT
/// a QibraChip, which owns a mandatory onTap).
class MushafJuzChip extends StatelessWidget {
  const MushafJuzChip({super.key, required this.juz});

  final int juz;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: (QibraPaper.isActive(context)
                  ? QibraPaper.gild
                  : AppGold.s500)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Juz $juz',
        style: AppTextStyles.labelSmall.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
