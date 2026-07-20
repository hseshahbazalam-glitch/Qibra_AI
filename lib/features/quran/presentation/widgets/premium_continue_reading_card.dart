// lib/features/quran/presentation/widgets/premium_continue_reading_card.dart
// ============================================================
// QIBRA AI — Premium Continue Reading Card
// Reads live Mushaf progress from Riverpod provider
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/features/quran/providers/reading_progress_provider.dart';

class PremiumContinueReadingCard extends ConsumerWidget {
  const PremiumContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(readingProgressProvider);
    final currentPage = progressState.currentPage;

    if (progressState.isLoading) {
      return const _ContinueReadingLoadingCard();
    }

    if (currentPage == null) {
      return _EmptyContinueReadingCard(
        onTap: () => context.push('${AppRoutes.mushafReader}?page=1'),
      );
    }

    final progressPercent = (currentPage.pageNumber / 604).clamp(0.0, 1.0);
    final progressLabel = '${(progressPercent * 100).toStringAsFixed(1)}%';
    final lastReadText = _formatTimeAgo(currentPage.savedAt);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        context.push(
          '${AppRoutes.mushafReader}?page=${currentPage.pageNumber}',
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1720),
              Color(0xFF122A22),
              Color(0xFF0F1720),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF0E7A53).withValues(alpha: 0.10),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row ───────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFB9922E),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Continue Reading',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open your last Mushaf page instantly',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Page ${currentPage.pageNumber}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Main Info ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'Surah',
                            value: currentPage.surahName,
                            icon: Icons.menu_book_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoTile(
                            label: 'Juz',
                            value: '${currentPage.juzNumber}',
                            icon: Icons.bookmark_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'Last Read',
                            value: lastReadText,
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoTile(
                            label: 'Reading Time',
                            value: currentPage.readingTimeText,
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Progress Header ───────────────────────────────
              Row(
                children: [
                  Text(
                    'Reading Progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Progress Bar ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4AF37),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    'Page ${currentPage.pageNumber} of 604',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ayah ${currentPage.ayahNumber}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── CTA Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.mushafReader}?page=${currentPage.pageNumber}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Continue Reading',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF09110F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1E6B4C).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContinueReadingCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyContinueReadingCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1720),
              Color(0xFF122A22),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Start Your Mushaf Journey',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Open the premium Mushaf reader and begin reading page by page.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Open Mushaf',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
}

class _ContinueReadingLoadingCard extends StatelessWidget {
  const _ContinueReadingLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF101820),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading your reading progress...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
