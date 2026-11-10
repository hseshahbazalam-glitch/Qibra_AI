// lib/features/quran/presentation/surah_reading_handle.dart
// ============================================================
// PASS QH — the SURAH-READER QUICK READING HANDLE.
// A pull-tab on the reader's LEFT edge (the spine side is free here —
// the mushaf ribbon owns the right) opening a floating panel with ONLY
// what this screen owns: Reading Theme (Night | Paper, the shared D2
// store), the split Arabic/Translation scales, and the translation
// edition list (the E-pass resolver's pickerEntries — the same mirror
// pattern H2 shipped for the hadith language sheet).
//
// Design rules this file enforces:
//  - tokens ONLY — zero raw hex literals anywhere in this file;
//  - NO backdrop blurring (the S1 raster-diet keeps this promise);
//  - screen-scoped: SurahReaderScreen hosts it; no other surface may;
//  - rest-quiet: closed = one static tab; the ticker is idle at rest
//    and the subtree lives under a RepaintBoundary;
//  - physics/page-turn: untouched (this never wraps or replaces the
//    reading content, it only rides beside it).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';

/// The handle + panel. Public only as the reader's integration seam and
/// as the widget-test handle; nothing outside SurahReaderScreen renders
/// it (pinned by the QH screen-scope test).
class SurahReadingHandle extends ConsumerStatefulWidget {
  const SurahReadingHandle({super.key});

  @override
  ConsumerState<SurahReadingHandle> createState() =>
      _SurahReadingHandleState();
}

class _SurahReadingHandleState extends ConsumerState<SurahReadingHandle>
    with SingleTickerProviderStateMixin {
  // ~220ms + the house easing (Curves.easeOutCubic — the same curve the
  // reader's own strips animate with at 250/260ms).
  final AnimationController _anim = AnimationController(
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 220),
  );
  final FocusNode _escFocus = FocusNode(debugLabel: 'qrah-esc');
  double _drag = 0;

  static const double _panelWidth = 272;

  @override
  void initState() {
    super.initState();
    _anim.addListener(_onAnim);
  }

  void _onAnim() {
    // Rebuild at BOTH ends: completed → canPop flips and the subtree
    // settles; dismissed → the now-hidden panel/barrier leave the tree
    // so the resting frame is literally just the tab (rest-quiet pin).
    if (_anim.status == AnimationStatus.completed ||
        _anim.status == AnimationStatus.dismissed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _anim.removeListener(_onAnim);
    _anim.dispose();
    _escFocus.dispose();
    super.dispose();
  }

  bool get _open => _anim.value > 0;

  void _show() {
    HapticFeedback.selectionClick();
    // Force the tree on the FIRST frame (the overlay children are gated
    // on _open; without this the panel would only appear at completion).
    setState(() {});
    _anim.forward();
    _escFocus.requestFocus();
  }

  void _hide() {
    _anim.reverse();
    _escFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final strings = AppStrings.of(context);
    final prefs = ref.watch(readingPreferencesProvider);
    return PopScope(
      // Back/ESC only when open; closed, the route pops untouched.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _hide();
      },
      child: RepaintBoundary(
        child: Focus(
          focusNode: _escFocus,
          onKeyEvent: (node, event) {
            if (_open &&
                event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _hide();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              if (_open)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('qrah-barrier'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _hide,
                    // Invisible blocker: taps outside close, the page
                    // itself never dims (zero alphas written here; the
                    // panel carries its own elevation instead).
                  ),
                ),
              if (_open)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _anim,
                      curve: Curves.easeOutCubic,
                    )),
                    child: GestureDetector(
                      // Swipe left to dismiss (mirrors opening by swipe
                      // right on the tab).
                      onHorizontalDragUpdate: (d) =>
                          _drag += d.delta.dx,
                      onHorizontalDragEnd: (_) {
                        if (_drag < -24) _hide();
                        _drag = 0;
                      },
                      child: _panel(context, colors, strings, prefs),
                    ),
                  ),
                ),
              // THE TAB — the only thing that exists at rest.
              Align(
                alignment: const Alignment(-1.0, -0.25),
                child: Semantics(
                  button: true,
                  label: strings.tooltipReadingSettings,
                  child: GestureDetector(
                    key: const ValueKey('qrah-tab'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _show,
                    onHorizontalDragUpdate: (d) {
                      _drag += d.delta.dx;
                      if (_drag > 24) {
                        _drag = 0;
                        _show();
                      }
                    },
                    onHorizontalDragEnd: (_) => _drag = 0,
                    child: Container(
                      width: 30,
                      height: 92,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          top: BorderSide(color: colors.border),
                          right: BorderSide(color: colors.border),
                          bottom: BorderSide(color: colors.border),
                        ),
                        boxShadow: QibraNavy.navyCard,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 16, color: colors.textPrimary),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right_rounded,
                              size: 14, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, QibraColors colors,
      AppStrings strings, ReadingPreferences prefs) {
    final notifier = ref.read(readingPreferencesProvider.notifier);
    return Container(
      key: const ValueKey('qrah-panel'),
      width: _panelWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: colors.border),
          right: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
        boxShadow: QibraNavy.navyCard,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.tooltipReadingSettings,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: strings.close,
                      child: GestureDetector(
                        key: const ValueKey('qrah-close'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _hide,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              size: 20, color: colors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Reading theme'),
                const SizedBox(height: 8),
                // Mirrors the settings-screen selector VERBATIM (same
                // store, same widget, instant switch — no restart).
                SegmentedButton<QibraReadingTheme>(
                  key: const ValueKey('qrah-theme'),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                      visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(
                        value: QibraReadingTheme.night,
                        label: Text('Night')),
                    ButtonSegment(
                        value: QibraReadingTheme.paper,
                        label: Text('Paper')),
                  ],
                  selected: {
                    ref.watch(readingPreferencesProvider
                        .select((p) => p.readingTheme))
                  },
                  onSelectionChanged: (sel) {
                    HapticFeedback.lightImpact();
                    notifier.setReadingTheme(sel.first);
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Text size'),
                const SizedBox(height: 4),
                _scaleRow(
                  label: 'Arabic',
                  scale: prefs.arabicScale,
                  keyBase: 'qrah-arabic',
                  onStep: (delta) =>
                      notifier.setArabicScale(prefs.arabicScale + delta),
                ),
                _scaleRow(
                  label: 'Translation',
                  scale: prefs.translationScale,
                  keyBase: 'qrah-translation',
                  onStep: (delta) => notifier.setTranslationScale(
                      prefs.translationScale + delta),
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Translation edition'),
                const SizedBox(height: 4),
                _editionList(context, colors, notifier, prefs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = QibraColors.of(context);
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _scaleRow({
    required String label,
    required double scale,
    required String keyBase,
    required void Function(double delta) onStep,
  }) {
    final colors = QibraColors.of(context);
    Widget step(String kind, IconData icon, double delta, String semantics) {
      return Semantics(
        button: true,
        label: semantics,
        child: GestureDetector(
          key: ValueKey('$keyBase-$kind'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onStep(delta);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.cardMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, size: 16, color: colors.textPrimary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // The ×N readout is the hadith book screen's split-sheet idiom
          // (no percent sign, no invented badge).
          Text(
            '${scale.toStringAsFixed(2)}\u00d7',
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          step('minus', Icons.remove_rounded, -0.1,
              'Decrease $label size'),
          const SizedBox(width: 8),
          step('plus', Icons.add_rounded, 0.1, 'Increase $label size'),
        ],
      ),
    );
  }

  Widget _editionList(BuildContext context, QibraColors colors,
      ReadingPreferencesNotifier notifier, ReadingPreferences prefs) {
    final current = EditionResolver.canonical(prefs.translationId);
    return Column(
      children: [
        for (final edition in EditionResolver.pickerEntries())
          Semantics(
            button: true,
            selected: edition.id == current,
            child: GestureDetector(
              key: ValueKey('qrah-edition-${edition.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.setTranslation(edition.id);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: edition.id == current
                      ? colors.primarySoft
                      : colors.cardMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: edition.id == current
                        ? colors.primary
                        : colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        edition.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: edition.id == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (edition.id == current)
                      Icon(Icons.check_rounded,
                          size: 16, color: colors.primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
