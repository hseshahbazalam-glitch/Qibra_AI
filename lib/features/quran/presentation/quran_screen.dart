// lib/features/quran/presentation/quran_screen.dart
// ============================================================
// QIBRA AI — QURAN HOME SCREEN (Pixel-Perfect Flagship UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isPlayingAudio = false;

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(allSurahsProvider);
    final readingProgress = ref.watch(readingProgressProvider);
    final isInitialized = ref.watch(quranInitProvider).value ?? true;

    final lastSurahName =
        readingProgress.currentPage?.surahName ?? 'Al-Fatihah';
    final lastPage = readingProgress.currentPage?.pageNumber ?? 1;
    final lastJuz = readingProgress.currentPage?.juzNumber ?? 1;
    final lastAyah = readingProgress.currentPage?.ayahNumber ?? 1;
    final lastSurahNum = readingProgress.currentPage?.surahNumber ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF020A08),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TOP BAR
                    _buildTopBar(context),
                    const SizedBox(height: 14),

                    // 2. HERO TODAY'S VERSE CARD
                    _buildTodaysVerseHero(context),
                    const SizedBox(height: 16),

                    // 3. READING PROGRESS & DAY STREAK (TWO-COLUMN)
                    _buildReadingProgressAndStreakRow(context),
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

                    // 5. QUICK ACCESS (6 ITEMS)
                    _buildQuickAccessSection(context),
                    const SizedBox(height: 18),

                    // 6. BROWSE BY TABS
                    _buildBrowseByTabs(),
                    const SizedBox(height: 12),

                    // 7. SURAH LIST TILES
                    if (!isInitialized)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: Color(0xFF00E676)),
                        ),
                      )
                    else
                      surahsAsync.when(
                        data: (surahs) => _buildSurahList(context, surahs),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                                color: Color(0xFF00E676)),
                          ),
                        ),
                        error: (_, __) => _buildFallbackSurahList(context),
                      ),
                    const SizedBox(height: 10),

                    // 8. VIEW ALL SURAHS BUTTON
                    _buildViewAllSurahsButton(context),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            // 9. BOTTOM AUDIO MINI PLAYER
            _buildAudioMiniPlayer(),
          ],
        ),
      ),
    );
  }

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
              color: const Color(0xFF071E16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF143B2C)),
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
                'Quran',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              Row(
                children: [
                  Text('Allah\'s Guidance for Mankind ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  Text('💚', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        _buildTopIconBtn(
          icon: Icons.search_rounded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuranSearchScreen())),
        ),
        const SizedBox(width: 8),
        _buildTopIconBtn(
          icon: Icons.bookmark_border_rounded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen())),
        ),
        const SizedBox(width: 8),
        _buildTopIconBtn(
          icon: Icons.settings_outlined,
          onTap: () => context.go(AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildTopIconBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF071E16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF143B2C)),
        ),
        child: Icon(icon, color: const Color(0xFF00E676), size: 19),
      ),
    );
  }

  Widget _buildTodaysVerseHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071B14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 10,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/hero/mosque_night.png',
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xD9051812), Color(0xF2020B08)],
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
                          Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF00E676), size: 14),
                          SizedBox(width: 5),
                          Text("Today's Verse",
                              style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Verse copied to clipboard! 📋'),
                                    backgroundColor: Color(0xFF0B2E21),
                                    duration: Duration(seconds: 2)),
                              );
                            },
                            child: const Icon(Icons.share_outlined,
                                color: Colors.white70, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'وَاللَّهُ جَعَلَ لَكُمُ الْأَرْضَ بِسَاطًا',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '"And God has made the earth a wide expanse for you."',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Text('📗 ', style: TextStyle(fontSize: 11)),
                      Text('Surah Nuh (71:19)',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 14,
                            height: 4,
                            decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: Color(0xFF1B4D3B),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(
                            width: 4,
                            height: 4,
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

  Widget _buildReadingProgressAndStreakRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 60,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reading Progress',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Juz 1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text('3% Completed',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.03,
                    minHeight: 5,
                    backgroundColor: Color(0xFF0D2A20),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('7 Surahs • 45 Ayahs',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 40,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 0.85,
                        strokeWidth: 4,
                        backgroundColor: Color(0xFF0D2A20),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFFB703)),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('12',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Text('🔥', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Day Streak',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold)),
                const Text('Keep going!',
                    style: TextStyle(color: Color(0xFF00E676), fontSize: 8.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last Read',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 4),
                Text(surahName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Page $page • Juz $juz • Ayah $ayah',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D3E2A), Color(0xFF062016)]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            ),
            child:
                const Center(child: Text('📖', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SurahReaderScreen(
                        surahNumber: surahNum, initialAyah: ayah))),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2E21),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16543D)),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                const Text('Read Now ➔',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        'icon': Icons.bookmark_rounded,
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
        'icon': Icons.chat_bubble_outline_rounded,
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
        'color': const Color(0xFF94A3B8),
        'action': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QuranSearchScreen()))
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Quick Access',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text('View All',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
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

  Widget _buildBrowseByTabs() {
    final tabs = ['Surah', 'Juz', 'Page', 'Manzil', 'Ruku'];

    return Row(
      children: [
        const Text('Browse by',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 32,
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E676)
                            : const Color(0xFF071E16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : const Color(0xFF143B2C),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF020A08)
                                : const Color(0xFFCBD5E1),
                            fontSize: 11,
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
      ],
    );
  }

  Widget _buildSurahList(BuildContext context, List<SurahInfoModel> surahs) {
    final displayedSurahs = surahs.take(4).toList();

    return Column(
      children: displayedSurahs.map((surah) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF061A13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF143B2C)),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2E21),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF16543D)),
                  ),
                  child: Center(
                    child: Text('${surah.number}',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${surah.englishNameTranslation} • ${surah.numberOfAyahs} Ayahs',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
                Text(surah.nameArabic,
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.bookmark_border_rounded,
                    color: Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF64748B), size: 18),
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
        'arabic': 'سُورَةُ الْفَاتِحَةِ'
      },
      {
        'num': 2,
        'name': 'Al-Baqarah',
        'trans': 'The Cow',
        'ayahs': 286,
        'arabic': 'سُورَةُ الْبَقَرَةِ'
      },
      {
        'num': 3,
        'name': 'Aal-i-Imraan',
        'trans': 'The Family of Imraan',
        'ayahs': 200,
        'arabic': 'سُورَةُ آلِ عِمْرَانَ'
      },
      {
        'num': 4,
        'name': 'An-Nisaa',
        'trans': 'The Women',
        'ayahs': 176,
        'arabic': 'سُورَةُ النِّسَاءِ'
      },
    ];

    return Column(
      children: fallback.map((s) {
        final num = s['num'] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF061A13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF143B2C)),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2E21),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF16543D)),
                  ),
                  child: Center(
                    child: Text('$num',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold)),
                      Text('${s['trans']} • ${s['ayahs']} Ayahs',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
                Text(s['arabic'] as String,
                    style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.bookmark_border_rounded,
                    color: Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.more_vert_rounded,
                    color: Color(0xFF64748B), size: 18),
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF071E16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF143B2C)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('View All Surahs',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.grid_view_rounded, color: Color(0xFF00E676), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMiniPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF041710),
        border: const Border(top: BorderSide(color: Color(0xFF143B2C))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            ),
            child: const ClipOval(
              child: Center(child: Text('🎙️', style: TextStyle(fontSize: 18))),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Al-Fatihah • Ayah 1',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text('Mishary Rashid Alafasy',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.skip_previous_rounded,
                  color: Colors.white, size: 22),
              onPressed: () {}),
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isPlayingAudio = !_isPlayingAudio);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFF00E676), shape: BoxShape.circle),
              child: Icon(
                  _isPlayingAudio
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: const Color(0xFF020A08),
                  size: 22),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: Colors.white, size: 22),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.queue_music_rounded,
                  color: Color(0xFF94A3B8), size: 20),
              onPressed: () {}),
        ],
      ),
    );
  }
}
