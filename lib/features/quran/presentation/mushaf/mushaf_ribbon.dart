// lib/features/quran/presentation/mushaf/mushaf_ribbon.dart
// ============================================================
// QIBRA AI — SILK RIBBON BOOKMARK (Pass M, item 3)
//
// A code-drawn ribbon hangs from the top screen edge, its horizontal
// position carrying the reading progress (a right-bound codex fills
// its right-hand stack as you read — the ribbon therefore travels
// LEFT → RIGHT with progress). Tap = jump back to the last-read page;
// drag it DOWN and release = 'drop the ribbon here' → the CURRENT
// page becomes the saved progress. No new storage: both actions go
// through the screen's existing reading-progress paths (repository +
// _saveProgress), which is exactly the store the restore-on-open
// already uses.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';

class MushafRibbon extends StatefulWidget {
  const MushafRibbon({
    super.key,
    required this.totalPages,
    required this.lastReadPage,
    required this.currentPage,
    required this.onJumpToLastRead,
    required this.onDropHere,
  });

  final int totalPages;

  /// The saved reading-progress page (null = nothing saved yet).
  final int? lastReadPage;
  final int currentPage;

  /// Tap: return to the saved page (the screen toasts honestly when
  /// nothing is saved — it owns that knowledge).
  final VoidCallback onJumpToLastRead;

  /// Release after dragging past the arm threshold: save the CURRENT
  /// page as the progress.
  final VoidCallback onDropHere;

  static const double ribbonWidth = 12;
  static const double restLength = 30;
  static const double maxDrag = 56;
  static const double armDistance = 26;

  /// Progress fraction → horizontal position. 0 sits at the left
  /// margin, 1 at the right margin (see the codex note above).
  static double progressFraction(int? page, int total) {
    if (page == null || total <= 1) return 0;
    final f = (page - 1) / (total - 1);
    return f.clamp(0.0, 1.0);
  }

  @override
  State<MushafRibbon> createState() => _MushafRibbonState();
}

class _MushafRibbonState extends State<MushafRibbon> {
  double _drag = 0;

  bool get _armed => _drag >= MushafRibbon.armDistance;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = QibraColors.of(context);
    final anchor = widget.lastReadPage ?? widget.currentPage;
    final f = MushafRibbon.progressFraction(anchor, widget.totalPages);
    return LayoutBuilder(
      key: const ValueKey('mushaf-ribbon'),
      builder: (context, constraints) {
        final hit = MushafRibbon.ribbonWidth + 16;
        final usable =
            math.max(0.0, constraints.maxWidth - 2 * 10 - hit);
        final left = 10 + usable * f;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: 0,
              child: Semantics(
                button: true,
                label: strings.mushafRibbonA11y,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onJumpToLastRead,
                  onVerticalDragStart: (_) => setState(() => _drag = 0),
                  onVerticalDragUpdate: (d) {
                    setState(() {
                      final wasArmed = _armed;
                      _drag = (_drag + d.delta.dy)
                          .clamp(0.0, MushafRibbon.maxDrag);
                      if (!wasArmed && _armed) {
                        HapticFeedback.selectionClick();
                      }
                    });
                  },
                  onVerticalDragEnd: (_) {
                    final armed = _armed;
                    setState(() => _drag = 0);
                    if (armed) {
                      HapticFeedback.mediumImpact();
                      widget.onDropHere();
                    }
                  },
                  onVerticalDragCancel: () => setState(() => _drag = 0),
                  child: SizedBox(
                    width: hit,
                    height: MushafRibbon.restLength +
                        MushafRibbon.maxDrag +
                        8,
                    child: CustomPaint(
                      painter: _RibbonPainter(
                        length: MushafRibbon.restLength + _drag,
                        armed: _armed,
                        base: colors.primary,
                        trim: AppGold.s500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The drop hint rides below the ribbon only while armed —
            // localized text, token pill chrome, zero invented state.
            if (_armed)
              Positioned(
                key: const ValueKey('mushaf-ribbon-hint'),
                left: left + hit + 4,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppGold.s500.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    strings.mushafRibbonDropHint,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Silk ribbon: navy body with a subtle vertical shade and a V-cut
/// tail; the gilded 1px trims sit on the edges only (gold discipline
/// — the ribbon is ~12px of an edge, not a surface).
class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({
    required this.length,
    required this.armed,
    required this.base,
    required this.trim,
  });

  final double length;
  final bool armed;
  final Color base;
  final Color trim;

  static const double _w = MushafRibbon.ribbonWidth;
  static const double _notch = 7;

  @override
  void paint(Canvas canvas, Size size) {
    // Center the silk inside its (wider) tap column.
    final left = (size.width - _w) / 2;
    final body = Path()
      ..moveTo(left, 0)
      ..lineTo(left + _w, 0)
      ..lineTo(left + _w, length)
      ..lineTo(left + _w / 2, length - _notch)
      ..lineTo(left, length)
      ..close();
    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          base,
          Color.lerp(base, Colors.black, 0.22)!,
        ],
      ).createShader(Rect.fromLTWH(left, 0, _w, length));
    canvas.drawPath(body, shade);
    // sheen line — the silk read
    canvas.drawLine(
      Offset(left + 2.5, 2),
      Offset(left + 2.5, length - _notch - 1),
      Paint()
        ..color = Colors.white.withValues(alpha: armed ? 0.34 : 0.18)
        ..strokeWidth = 1.2,
    );
    final trimPaint = Paint()
      ..color = trim.withValues(alpha: armed ? 0.95 : 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(body, trimPaint);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) =>
      old.length != length || old.armed != armed;
}
