// lib/features/quran/presentation/quran_screen.dart
// ============================================================
// QIBRA AI — QURAN HOME (Exact Gold & Emerald Flagship UI)
// ============================================================

import 'package:flutter/material.dart';
import '../../../shared/widgets/media/safe_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;
import '../providers/reading_progress_provider.dart';
import 'bookmarks_screen.dart';
import 'mushaf_reader_screen.dart';
import 'quran_search_screen.dart';
import 'surah_list_screen.dart';
import 'surah_reader_screen.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String _selectedBrowseTab = 'Surah';
  final Set<int> _bookmarkedSurahs = {1, 2};

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(allSurahsProvider);
    final readingProgress = ref.watch(readingProgressProvider);
    final isInitialized = ref.watch(quranInitProvider).value ?? true;

    final lastSurahName =
        readingProgress.currentPage?.surahName ?? 'Al-Baqarah';
    final lastPage = readingProgress.currentPage?.pageNumber ?? 36;
    final lastJuz = readingProgress.currentPage?.juzNumber ?? 2;
    final lastAyah = readingProgress.currentPage?.ayahNumber ?? 45;
    final lastSurahNum = readingProgress.currentPage?.surahNumber ?? 2;

    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    final gregDateStr = DateFormat('MMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP APP BAR
              _buildTopBar(context),
              const SizedBox(height: 14),

              // 2. HERO VERSE OF THE DAY CARD
              _buildVerseOfTheDayHero(context, hijriStr, gregDateStr),
              const SizedBox(height: 16),

              // 3. READING PROGRESS & DAY STREAK (TWO-COLUMN)
              _buildProgressAndStreakRow(context, readingProgress),
              const SizedBox(height: 16),

              // 4. LAST READ CARD
              _buildLastReadCard(
                context,
                surahName: lastSurahName,
                page: lastPage,
                juz: lastJuz,
                ayah: lastAyah,
                surahNum: lastSurahNum,
              ),
              const SizedBox(height: 18),

              // 5. QUICK ACCESS (6 LUXURY ICONS)
              _buildQuickAccessSection(context),
              const SizedBox(height: 18),

              // 6. BROWSE BY TABS + FILTER BUTTON
              _buildBrowseByTabsAndFilter(),
              const SizedBox(height: 12),

              // 7. SURAH LIST TILES WITH PROGRESS
              if (!isInitialized)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF00E676)),
                  ),
                )
              else
                surahsAsync.when(
                  data: (surahs) => _buildSurahList(context, surahs),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          CircularProgressIndicator(color: Color(0xFF00E676)),
                    ),
                  ),
                  error: (_, __) => _buildFallbackSurahList(context),
                ),
              const SizedBox(height: 10),

              // 8. VIEW ALL SURAHS BUTTON
              _buildViewAllSurahsButton(context),
              const SizedBox(height: 18),

              // 9. YOUR QURAN JOURNEY (MONTHLY ANALYTICS CARD)
              _buildQuranJourneyCard(),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // 1. TOP APP BAR
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.tools),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0C100E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2620)),
            ),
            child:
                const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QURAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Allah\'s Guidance for Mankind ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                  ),
                  Text('💛', style: TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        _buildTopActionBtn(
          icon: Icons.search_rounded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuranSearchScreen())),
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.bookmark_border_rounded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen())),
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.settings_outlined,
          onTap: () => context.go(AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildTopActionBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0C100E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2620)),
        ),
        child: Icon(icon, color: const Color(0xFFFFB703), size: 18),
      ),
    );
  }

  // 2. HERO VERSE OF THE DAY CARD
  Widget _buildVerseOfTheDayHero(
      BuildContext context, String hijriStr, String gregDateStr) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: 10,
              child: Opacity(
                opacity: 0.35,
                child: SafeImage(
                  assetPath: 'assets/images/hero/mosque_night.png',
                  fit: BoxFit.cover,
                  height: 160,
                  fallback: SafeImageFallback.mosque,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xEA050806), Color(0xFA020302)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('✦ ',
                              style: TextStyle(
                                  color: Color(0xFFFFB703), fontSize: 11)),
                          Text(
                            'VERSE OF THE DAY',
                            style: TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$hijriStr | $gregDateStr',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 9.5),
                          ),
                          const SizedBox(width: 4),
                          const Text('🌙', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C120E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFB703)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Text('📖', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B2E21),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF00E676)),
                                  ),
                                  child: const Text(
                                    '19',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'وَاللَّهُ جَعَلَ لَكُمُ الْأَرْضَ بِسَاطًا',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Amiri',
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '"And Allah has made the earth a wide expanse for you."',
                              style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 11,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    color: Color(0xFFFFB703), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Surah Nuh (71:19)',
                                  style: TextStyle(
                                      color: Color(0xFFFFB703),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C120E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1C2620)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeroAction(
                            Icons.play_circle_outline_rounded, 'Listen', () {}),
                        _buildHeroAction(
                            Icons.menu_book_rounded, 'Tafsir', () {}),
                        _buildHeroAction(
                            Icons.bookmark_border_rounded, 'Bookmark', () {}),
                        _buildHeroAction(Icons.share_outlined, 'Share', () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ayah copied to clipboard! 📋'),
                                backgroundColor: Color(0xFF0B2E21),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 14,
                            height: 3.5,
                            decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: const BoxDecoration(
                                color: Color(0xFF1B4D3B),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: const BoxDecoration(
                                color: Color(0xFF1B4D3B),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: const BoxDecoration(
                                color: Color(0xFF1B4D3B),
                                shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFB703), size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 3. READING PROGRESS & DAY STREAK
  Widget _buildProgressAndStreakRow(
      BuildContext context, ReadingProgressState progress) {
    return Row(
      children: [
        Expanded(
          flex: 58,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('READING PROGRESS',
                    style: TextStyle(
                        color: Color(0xFFFFB703),
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Juz 1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('3% Completed',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.03,
                    minHeight: 4.5,
                    backgroundColor: Color(0xFF121B16),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('45 / 6236 Ayahs',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
                    Text('7 Surahs • 45 Ayahs',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const MushafReaderScreen(initialPage: 1))),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF072418),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF144D34)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: Color(0xFF00E676), size: 12),
                        SizedBox(width: 4),
                        Text('Continue Reading',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            color: Color(0xFF00E676), size: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 42,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text('DAY STREAK',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 4,
                          backgroundColor: Color(0xFF161F1A),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFFFB703)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('12',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text('Days',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 7.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Keep going!',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                    final isStar = d == 'S';
                    return Column(
                      children: [
                        Text(d,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 7.5)),
                        const SizedBox(height: 1),
                        Icon(isStar ? Icons.star_rounded : Icons.check_circle,
                            color: isStar
                                ? const Color(0xFFFFB703)
                                : const Color(0xFF00E676),
                            size: 9),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 9)),
                    SizedBox(width: 3),
                    Text('Longest Streak: 12 Days',
                        style:
                            TextStyle(color: Color(0xFFFFB703), fontSize: 7.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. LAST READ CARD
  Widget _buildLastReadCard(
    BuildContext context, {
    required String surahName,
    required int page,
    required int juz,
    required int ayah,
    required int surahNum,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✦ LAST READ',
              style: TextStyle(
                  color: Color(0xFFFFB703),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFF261D0D), Color(0xFF0A0C0B)]),
                  border:
                      Border.all(color: const Color(0xFFFFB703), width: 1.5),
                ),
                child: const Center(
                  child: Text('القرآن',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(surahName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const Text('The Cow',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SurahReaderScreen(
                                      surahNumber: surahNum,
                                      initialAyah: ayah))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF072418),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF144D34)),
                                ),
                                child: const Text('Continue',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 3),
                              const Text('Read Now ➔',
                                  style: TextStyle(
                                      color: Color(0xFF00E676), fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBox('Page', '$page'),
                        const SizedBox(width: 6),
                        _buildStatBox('Juz', '$juz'),
                        const SizedBox(width: 6),
                        _buildStatBox('Ayah', '$ayah'),
                        const SizedBox(width: 6),
                        _buildStatBox('Completed', '12%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Color(0xFF64748B), size: 10),
                        SizedBox(width: 4),
                        Text('Last opened: Today, 9:45 AM',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 8.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0C120E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1A241E)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 5. QUICK ACCESS
  Widget _buildQuickAccessSection(BuildContext context) {
    final items = [
      {
        'title': 'Last Read',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00E676),
        'action': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MushafReaderScreen(initialPage: 1)))
      },
      {
        'title': 'Bookmarks',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFB703),
        'action': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const BookmarksScreen()))
      },
      {
        'title': 'Notes',
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFFC084FC),
        'action': () {}
      },
      {
        'title': 'Tafsir',
        'icon': Icons.import_contacts_rounded,
        'color': const Color(0xFF38BDF8),
        'action': () {}
      },
      {
        'title': 'Audio',
        'icon': Icons.headphones_rounded,
        'color': const Color(0xFFFF7043),
        'action': () {}
      },
      {
        'title': 'Search',
        'icon': Icons.search_rounded,
        'color': const Color(0xFFCBD5E1),
        'action': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QuranSearchScreen()))
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('QUICK ACCESS',
                  style: TextStyle(
                      color: Color(0xFFFFB703),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text('View All >',
                  style: TextStyle(
                      color: Color(0xFFFFB703),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              final color = item['color'] as Color;
              return Expanded(
                child: InkWell(
                  onTap: item['action'] as VoidCallback,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(item['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 6. BROWSE BY TABS
  Widget _buildBrowseByTabsAndFilter() {
    final tabs = ['Surah', 'Juz', 'Page', 'Manzil', 'Ruku'];

    return Row(
      children: [
        const Text('BROWSE BY',
            style: TextStyle(
                color: Color(0xFFFFB703),
                fontSize: 9.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = _selectedBrowseTab == tab;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedBrowseTab = tab);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF072418)
                            : const Color(0xFF080C0A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : const Color(0xFF1E2620),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF080C0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2620)),
          ),
          child: const Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  color: Color(0xFFFFB703), size: 12),
              SizedBox(width: 3),
              Text('Filter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // 7. SURAH LIST TILES
  Widget _buildSurahList(BuildContext context, List<SurahInfoModel> surahs) {
    final displayedSurahs = surahs.take(4).toList();

    return Column(
      children: displayedSurahs.map((surah) {
        final isBookmarked = _bookmarkedSurahs.contains(surah.number);
        final progress = surah.number == 1
            ? 1.0
            : (surah.number == 2 ? 0.12 : (surah.number == 3 ? 0.08 : 0.06));
        final progressText = '${(progress * 100).round()}%';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF080C0A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A221C)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        SurahReaderScreen(surahNumber: surah.number)),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1410),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF163E2C)),
                  ),
                  child: Center(
                    child: Text('${surah.number}',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${surah.englishNameTranslation} • ${surah.numberOfAyahs} Ayahs',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 9.5)),
                    ],
                  ),
                ),
                Text(surah.nameArabic,
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 15,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() {
                    if (isBookmarked) {
                      _bookmarkedSurahs.remove(surah.number);
                    } else {
                      _bookmarkedSurahs.add(surah.number);
                    }
                  }),
                  child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked
                          ? const Color(0xFFFFB703)
                          : const Color(0xFF64748B),
                      size: 17),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(progressText,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 8.5)),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 28,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: const Color(0xFF1A241E),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF64748B), size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFallbackSurahList(BuildContext context) {
    final fallback = [
      {
        'num': 1,
        'name': 'Al-Fatihah',
        'trans': 'The Opening',
        'ayahs': 7,
        'arabic': 'سورة الفاتحة',
        'prog': 1.0
      },
      {
        'num': 2,
        'name': 'Al-Baqarah',
        'trans': 'The Cow',
        'ayahs': 286,
        'arabic': 'سورة البقرة',
        'prog': 0.12
      },
      {
        'num': 3,
        'name': 'Aal-i-Imraan',
        'trans': 'The Family of Imraan',
        'ayahs': 200,
        'arabic': 'سورة آل عمران',
        'prog': 0.08
      },
      {
        'num': 4,
        'name': 'An-Nisaa',
        'trans': 'The Women',
        'ayahs': 176,
        'arabic': 'سورة النساء',
        'prog': 0.06
      },
    ];

    return Column(
      children: fallback.map((s) {
        final num = s['num'] as int;
        final prog = s['prog'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF080C0A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A221C)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SurahReaderScreen(surahNumber: num)),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1410),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF163E2C)),
                  ),
                  child: Center(
                    child: Text('$num',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text('${s['trans']} • ${s['ayahs']} Ayahs',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 9.5)),
                    ],
                  ),
                ),
                Text(s['arabic'] as String,
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 15,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.bookmark_rounded,
                    color: Color(0xFFFFB703), size: 17),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text('${(prog * 100).round()}%',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 8.5)),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 28,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: prog,
                          minHeight: 2.5,
                          backgroundColor: const Color(0xFF1A241E),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF64748B), size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildViewAllSurahsButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SurahListScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View All Surahs ',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold)),
            Text('▦', style: TextStyle(color: Color(0xFF00E676), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // 8. YOUR QURAN JOURNEY
  Widget _buildQuranJourneyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 0,
              child: Opacity(
                opacity: 0.35,
                child: SafeImage(
                  assetPath: 'assets/images/hero/mosque_night.png',
                  fit: BoxFit.cover,
                  height: 100,
                  fallback: SafeImageFallback.mosque,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('✦ ',
                          style: TextStyle(
                              color: Color(0xFFFFB703), fontSize: 11)),
                      Text('YOUR QURAN JOURNEY',
                          style: TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildJourneyMetric(Icons.access_time_rounded,
                          'Total Reading Time', '18h 42m', 'This Month'),
                      _buildJourneyMetric(Icons.auto_stories_rounded,
                          'Ayahs Read', '1,248', 'This Month'),
                      _buildJourneyMetric(Icons.check_circle_outline_rounded,
                          'Completed Surahs', '3', 'This Month'),
                      _buildJourneyMetric(Icons.calendar_month_outlined,
                          'Average Daily Reading', '18 min', 'Keep it up!'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyMetric(
      IconData icon, String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFFB703), size: 14),
        const SizedBox(height: 4),
        SizedBox(
          width: 74,
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 7.5, height: 1.1),
              maxLines: 2),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(
                color: sub.contains('Keep')
                    ? const Color(0xFF00E676)
                    : const Color(0xFF94A3B8),
                fontSize: 7.5)),
      ],
    );
  }
}
