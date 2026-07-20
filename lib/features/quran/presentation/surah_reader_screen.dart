// lib/features/quran/presentation/surah_reader_screen.dart

// ============================================================
// QIBRA AI — PREMIUM AUTO SURAH READER (v5.0)
// ============================================================
// Features:
//   ✅ Individual ayah cards with auto-scroll
//   ✅ Word-by-word progressive highlighting
//   ✅ Smooth 60fps scroll (no jump)
//   ✅ Premium glow on active ayah
//   ✅ Dim previous ayahs
//   ✅ Manual scroll detection
//   ✅ Resume auto-follow after 4 seconds
//   ✅ Progress indicator per ayah
//   ✅ Programmatic scroll flag (no false triggers)
// ============================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_provider.dart';
import 'services/quran_audio_service.dart';
import 'quran_audio_player.dart';

// ============================================================
// FONT SIZE ENUM
// ============================================================

enum QuranFontSize {
  small,
  medium,
  large,
  extraLarge;

  double get arabicSize {
    return switch (this) {
      QuranFontSize.small => 22.0,
      QuranFontSize.medium => 26.0,
      QuranFontSize.large => 30.0,
      QuranFontSize.extraLarge => 34.0,
    };
  }

  double get translationSize {
    return switch (this) {
      QuranFontSize.small => 13.0,
      QuranFontSize.medium => 15.0,
      QuranFontSize.large => 17.0,
      QuranFontSize.extraLarge => 19.0,
    };
  }

  String get label {
    return switch (this) {
      QuranFontSize.small => 'S',
      QuranFontSize.medium => 'M',
      QuranFontSize.large => 'L',
      QuranFontSize.extraLarge => 'XL',
    };
  }

  String get fullLabel {
    return switch (this) {
      QuranFontSize.small => 'Small',
      QuranFontSize.medium => 'Medium',
      QuranFontSize.large => 'Large',
      QuranFontSize.extraLarge => 'Extra Large',
    };
  }
}

// ============================================================
// LOCAL PROVIDERS
// ============================================================

final _readerFontSizeProvider =
    StateProvider.autoDispose<QuranFontSize>((ref) => QuranFontSize.medium);

final _showEnglishProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showUrduProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showRomanProvider = StateProvider.autoDispose<bool>((ref) => false);

// ============================================================
// MAIN SCREEN
// ============================================================

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  final int surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  bool _hasTrackedInitialRead = false;
  bool _isUserScrolling = false;
  bool _isAutoScrollEnabled = true;
  bool _isProgrammaticScroll = false;
  Timer? _resumeAutoScrollTimer;
  int? _lastScrolledAyah;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _resumeAutoScrollTimer?.cancel();
    super.dispose();
  }

  // ─── SCROLL DETECTION ─────────────────────────

  void _onScroll() {
    // Skip if this is our own programmatic scroll
    if (_isProgrammaticScroll) return;
    if (!_scrollController.hasClients) return;

    // User is manually scrolling
    if (!_isUserScrolling) {
      _isUserScrolling = true;
      _isAutoScrollEnabled = false;
      if (mounted) setState(() {});
    }

    // Reset resume timer on every scroll event
    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      setState(() {
        _isAutoScrollEnabled = true;
        _isUserScrolling = false;
        _lastScrolledAyah = null;
      });

      // Auto-scroll to current playing ayah
      final audioState = ref.read(audioProvider);
      if (audioState.surahNumber == widget.surahNumber &&
          audioState.ayahNumber != null) {
        _scrollToAyah(audioState.ayahNumber!, force: true);
      }
    });
  }

  // ─── SMOOTH AUTO-SCROLL ───────────────────────

  void _scrollToAyah(int ayahNumber, {bool force = false}) {
    debugPrint(
        '[AUTO-SCROLL] Request: ayah=$ayahNumber, enabled=$_isAutoScrollEnabled, force=$force');

    if (!_isAutoScrollEnabled && !force) {
      debugPrint('[AUTO-SCROLL] BLOCKED: auto-scroll disabled');
      return;
    }
    if (_lastScrolledAyah == ayahNumber && !force) {
      debugPrint('[AUTO-SCROLL] SKIPPED: already scrolled to $ayahNumber');
      return;
    }
    if (!_scrollController.hasClients) {
      debugPrint('[AUTO-SCROLL] FAILED: no scroll clients');
      return;
    }

    final key = _ayahKeys[ayahNumber];
    if (key == null) {
      debugPrint('[AUTO-SCROLL] FAILED: no key for ayah $ayahNumber');
      return;
    }

    debugPrint('[AUTO-SCROLL] SCROLLING to ayah $ayahNumber');

    _lastScrolledAyah = ayahNumber;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;

      final keyContext = key.currentContext;
      if (keyContext == null) return;

      final renderObject = keyContext.findRenderObject();
      if (renderObject == null) return;

      final viewport = RenderAbstractViewport.of(renderObject);
      final scrollPosition = _scrollController.position;

      // Calculate position to place ayah at 28% from top
      final revealedOffset = viewport.getOffsetToReveal(
        renderObject,
        0.28,
      );

      final targetOffset = revealedOffset.offset.clamp(
        scrollPosition.minScrollExtent,
        scrollPosition.maxScrollExtent,
      );

      // Set programmatic flag to prevent false user-scroll detection
      _isProgrammaticScroll = true;

      try {
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeInOutCubicEmphasized,
        );
      } catch (_) {
        // Scroll interrupted — ignore
      } finally {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _isProgrammaticScroll = false;
          }
        });
      }
    });
  }

  void _updateLastRead(SurahModel surah, int ayahNumber) {
    ref.read(lastReadProvider.notifier).updateLastRead(
          surahNumber: surah.number,
          ayahNumber: ayahNumber,
          surahName: surah.name,
          totalAyahsInSurah: surah.numberOfAyahs,
        );
  }

  void _resumeAutoScroll() {
    HapticFeedback.lightImpact();
    setState(() {
      _isAutoScrollEnabled = true;
      _isUserScrolling = false;
    });
    _resumeAutoScrollTimer?.cancel();
    _lastScrolledAyah = null;

    final audioState = ref.read(audioProvider);
    if (audioState.ayahNumber != null) {
      _scrollToAyah(audioState.ayahNumber!, force: true);
    }
  }

  void _showFontSizeSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FontSizeBottomSheet(),
    );
  }

  void _showSettingsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));

    // Listen to audio ayah changes for auto-scroll
    ref.listen<QuranAudioState>(audioProvider, (previous, next) {
      if (next.surahNumber == widget.surahNumber &&
          next.ayahNumber != null &&
          previous?.ayahNumber != next.ayahNumber) {
        _scrollToAyah(next.ayahNumber!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: surahAsync.when(
        data: (surah) {
          if (surah == null) return _buildNotFound();

          if (!_hasTrackedInitialRead) {
            _hasTrackedInitialRead = true;
            // Initialize keys IMMEDIATELY (not in post frame)
            for (var ayah in surah.ayahs) {
              _ayahKeys.putIfAbsent(ayah.number, () => GlobalKey());
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateLastRead(surah, widget.initialAyah ?? 1);
            });
          }

          return _buildReaderBody(surah);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildReaderBody(SurahModel surah) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                AppColors.background,
                AppColors.background,
              ],
              stops: const [0.0, 0.15, 1.0],
            ),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(surah),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _SurahHeaderCard(surah: surah),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _PlayFullSurahButton(surah: surah),
                ),
              ),
              if (surah.number != 1 && surah.number != 9)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _BismillahWidget(),
                  ),
                ),
              // Individual ayah cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList.separated(
                  itemCount: surah.ayahs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ayah = surah.ayahs[index];
                    final ayahKey = _ayahKeys.putIfAbsent(
                      ayah.number,
                      () => GlobalKey(),
                    );
                    return _PremiumAyahCard(
                      key: ayahKey,
                      ayah: ayah,
                      surahNumber: surah.number,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl3 + AppSpacing.xl4 + AppSpacing.xl3,
                  ),
                  child: _TafseerButton(surah: surah),
                ),
              ),
            ],
          ),
        ),
        // Resume auto-scroll button
        if (!_isAutoScrollEnabled)
          Positioned(
            bottom: 100,
            right: AppSpacing.lg,
            child: _ResumeAutoScrollButton(onTap: _resumeAutoScroll),
          ),
        // Audio player at bottom (above bottom nav)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 70,
          left: 0,
          right: 0,
          child: QuranMiniPlayer(surahName: surah.name),
        ),
      ],
    );
  }

  Widget _buildAppBar(SurahModel surah) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      toolbarHeight: 64,
      leading: const SizedBox.shrink(),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: AppColors.background.withValues(alpha: 0.7),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            child: Row(
              children: [
                _AppBarButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        surah.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${surah.numberOfAyahs} Ayahs • ${surah.revelationType}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _AppBarButton(
                  icon: Icons.text_fields_rounded,
                  onTap: _showFontSizeSheet,
                ),
                const SizedBox(width: AppSpacing.sm),
                _AppBarButton(
                  icon: Icons.tune_rounded,
                  onTap: _showSettingsSheet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text('Surah not found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text('Unable to Load Surah',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(surahDetailProvider(widget.surahNumber)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM AYAH CARD (Individual ayah with auto-highlight)
// ============================================================

class _PremiumAyahCard extends ConsumerWidget {
  const _PremiumAyahCard({
    super.key,
    required this.ayah,
    required this.surahNumber,
  });

  final AyahModel ayah;
  final int surahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final fontSize = ref.watch(_readerFontSizeProvider);
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    final isActive = audioState.surahNumber == surahNumber &&
        audioState.ayahNumber == ayah.number;
    final isPast = audioState.surahNumber == surahNumber &&
        audioState.ayahNumber != null &&
        audioState.ayahNumber! > ayah.number;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      transform: Matrix4.diagonal3Values(
        isActive ? 1.02 : 1.0,
        isActive ? 1.02 : 1.0,
        1.0,
      ),
      transformAlignment: Alignment.center,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isPast ? 0.4 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20),
                      AppColors.accent.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.10),
                    ],
                  )
                : null,
            color: isActive
                ? null
                : AppColors.surfaceElevated.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.primary.withValues(alpha: 0.10),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(isActive, audioState),

              // Arabic text with word-by-word highlighting
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: _SyncedArabicText(
                  text: ayah.text,
                  fontSize: fontSize.arabicSize,
                  isActive: isActive,
                  progress: isActive ? audioState.progress : 0.0,
                ),
              ),

              // Translations
              if (showEnglish && ayah.translation != null)
                _buildTranslation(
                  label: 'English',
                  text: ayah.translation!,
                  color: const Color(0xFF4CAF50),
                  icon: Icons.language_rounded,
                  fontSize: fontSize.translationSize,
                  isActive: isActive,
                ),

              if (showUrdu && ayah.translationUrdu != null)
                _buildTranslation(
                  label: 'اردو',
                  text: ayah.translationUrdu!,
                  color: const Color(0xFF00A86B),
                  icon: Icons.translate_rounded,
                  fontSize: fontSize.translationSize + 2,
                  isActive: isActive,
                  isRtl: true,
                  useUrduFont: true,
                ),

              if (showRoman && ayah.translationRoman != null)
                _buildTranslation(
                  label: 'Roman Urdu',
                  text: ayah.translationRoman!,
                  color: const Color(0xFFFF9800),
                  icon: Icons.abc_rounded,
                  fontSize: fontSize.translationSize,
                  isActive: isActive,
                ),

              // Progress indicator
              if (isActive && audioState.duration > Duration.zero)
                _buildProgressIndicator(audioState),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isActive, QuranAudioState audioState) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.20)
            : AppColors.surface.withValues(alpha: 0.60),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl2),
          topRight: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.60),
                        AppColors.accent.withValues(alpha: 0.40),
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                ayah.number.toString(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isActive && audioState.isPlaying) ...[
            _PlayingWave(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Playing',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (isActive && audioState.isPaused) ...[
            const Icon(Icons.pause_circle_filled_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Text(
              'Paused',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (isActive && audioState.isLoading) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Loading',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Text(
              'Juz ${ayah.juz}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Page ${ayah.page}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslation({
    required String label,
    required String text,
    required Color color,
    required IconData icon,
    required double fontSize,
    required bool isActive,
    bool isRtl = false,
    bool useUrduFont = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.30 : 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontFamily: useUrduFont ? 'Amiri' : null,
              fontSize: fontSize,
              color: AppColors.textPrimary,
              height: useUrduFont ? 2.0 : 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(QuranAudioState audioState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: audioState.progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audioState.positionFormatted,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                audioState.durationFormatted,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SYNCED ARABIC TEXT (Word-by-word highlighting)
// ============================================================

class _SyncedArabicText extends StatelessWidget {
  const _SyncedArabicText({
    required this.text,
    required this.fontSize,
    required this.isActive,
    required this.progress,
  });

  final String text;
  final double fontSize;
  final bool isActive;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize,
          color: AppColors.textPrimary,
          height: 2.2,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Split into words
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const SizedBox.shrink();

    final safeProgress = progress.clamp(0.0, 1.0);
    final activeWordIndex =
        (safeProgress * words.length).floor().clamp(0, words.length - 1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: List.generate(words.length, (index) {
            final isRead = index < activeWordIndex;
            final isCurrent = index == activeWordIndex;

            return TextSpan(
              text: '${words[index]} ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: isCurrent ? fontSize + 2 : fontSize,
                height: 2.25,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                color: isCurrent
                    ? AppColors.accent
                    : isRead
                        ? AppColors.primary.withValues(alpha: 0.95)
                        : AppColors.textPrimary.withValues(alpha: 0.78),
                shadows: isCurrent
                    ? [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ============================================================
// PLAYING WAVE ANIMATION
// ============================================================

class _PlayingWave extends StatefulWidget {
  @override
  State<_PlayingWave> createState() => _PlayingWaveState();
}

class _PlayingWaveState extends State<_PlayingWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = index * 0.2;
              final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final height = 4.0 + (8.0 * (1 - (value * 2 - 1).abs()));
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ============================================================
// RESUME AUTO-SCROLL BUTTON
// ============================================================

class _ResumeAutoScrollButton extends StatelessWidget {
  const _ResumeAutoScrollButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Follow Audio',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SURAH HEADER CARD
// ============================================================

class _SurahHeaderCard extends StatelessWidget {
  const _SurahHeaderCard({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.isMeccan;
    final revelationColor =
        isMeccan ? const Color(0xFF7C4DFF) : const Color(0xFF1E88E5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                surah.number.toString(),
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            surah.nameArabic,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.titleLarge.copyWith(
              fontFamily: 'Amiri',
              fontSize: 32,
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            surah.name,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"${surah.englishNameTranslation}"',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _MetaPill(
                icon: Icons.format_list_numbered_rounded,
                label: '${surah.numberOfAyahs} Ayahs',
                color: AppColors.accent,
              ),
              _MetaPill(
                icon: isMeccan
                    ? Icons.wb_sunny_rounded
                    : Icons.water_drop_rounded,
                label: surah.revelationType,
                color: revelationColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PLAY FULL SURAH BUTTON
// ============================================================

class _PlayFullSurahButton extends ConsumerWidget {
  const _PlayFullSurahButton({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final isThisSurahActive = audioState.surahNumber == surah.number;
    final isPlaying = isThisSurahActive && audioState.isPlaying;
    final isPaused = isThisSurahActive && audioState.isPaused;
    final isLoading = isThisSurahActive && audioState.isLoading;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();
            if (isPlaying) {
              await ref.read(audioProvider.notifier).pause();
            } else if (isPaused) {
              await ref.read(audioProvider.notifier).resume();
            } else if (surah.ayahs.isNotEmpty) {
              final firstAyah = surah.ayahs.first;
              await ref.read(audioProvider.notifier).playAyah(
                    surahNumber: surah.number,
                    ayahNumber: firstAyah.number,
                    globalAyahNumber: firstAyah.numberInQuran,
                  );
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isLoading
                      ? 'Loading...'
                      : isPlaying
                          ? 'Playing Surah'
                          : isPaused
                              ? 'Resume Surah'
                              : 'Play Full Surah',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (isPlaying || isPaused) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ayah ${audioState.ayahNumber}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BISMILLAH
// ============================================================

class _BismillahWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: const Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 28,
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          height: 1.8,
        ),
      ),
    );
  }
}

// ============================================================
// TAFSEER BUTTON
// ============================================================

class _TafseerButton extends StatelessWidget {
  const _TafseerButton({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tafseer Ibn Kathir opening...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Open Tafseer Ibn Kathir',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APP BAR BUTTON
// ============================================================

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.60),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ============================================================
// META PILL
// ============================================================

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FONT SIZE BOTTOM SHEET
// ============================================================

class _FontSizeBottomSheet extends ConsumerWidget {
  const _FontSizeBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(_readerFontSizeProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Font Size',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          ...QuranFontSize.values.map((size) {
            final isSelected = size == currentSize;
            return InkWell(
              onTap: () {
                ref.read(_readerFontSizeProvider.notifier).state = size;
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        size.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      size.fullLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// READER SETTINGS SHEET
// ============================================================

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Translation Languages',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: AppSpacing.lg),
          _buildToggle(
            title: 'English',
            subtitle: 'Standard English translation',
            value: showEnglish,
            onChanged: (v) => ref.read(_showEnglishProvider.notifier).state = v,
            color: const Color(0xFF4CAF50),
          ),
          _buildToggle(
            title: 'اردو',
            subtitle: 'Fateh Muhammad Jalandhry',
            value: showUrdu,
            onChanged: (v) => ref.read(_showUrduProvider.notifier).state = v,
            color: const Color(0xFF00A86B),
          ),
          _buildToggle(
            title: 'Roman Urdu',
            subtitle: 'Maududi Roman transliteration',
            value: showRoman,
            onChanged: (v) => ref.read(_showRomanProvider.notifier).state = v,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color ?? AppColors.primary,
          ),
        ],
      ),
    );
  }
}
