// lib/features/hadith/presentation/hadith_screen.dart
// ============================================================
// QIBRA AI — HADITH HOME SCREEN (Pixel-Perfect Flagship UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/hadith_models.dart';
import '../providers/hadith_provider.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _selectedFilterPill = 'All Hadiths';
  String _selectedCollectionSlug = 'bukhari';
  final Set<int> _bookmarkedHadiths = {1, 3};

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(hadithBooksProvider);

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
              _buildTopAppBar(context),
              const SizedBox(height: 14),

              // 2. HERO TODAY'S HADITH CARD
              _buildTodaysHadithHero(context),
              const SizedBox(height: 16),

              // 3. 4 METRIC CARDS ROW (Collections, Hadiths, Bookmarked, Completed)
              _buildFourMetricsRow(),
              const SizedBox(height: 18),

              // 4. BROWSE COLLECTIONS (6 KUTUB AL-SITTAH CARDS)
              _buildBrowseCollectionsSection(context, booksAsync.value),
              const SizedBox(height: 18),

              // 5. FILTER PILLS ROW (All Hadiths, Book, Chapter, Topics, Filter)
              _buildFilterPillsRow(),
              const SizedBox(height: 14),

              // 6. RECENT HADITHS LIST TILES
              _buildRecentHadithsSection(context),
              const SizedBox(height: 18),

              // 7. STUDY HADITH BANNER
              _buildStudyHadithBanner(context),
              const SizedBox(height: 110), // Bottom navigation spacing
            ],
          ),
        ),
      ),
    );
  }

  // 1. TOP APP BAR
  Widget _buildTopAppBar(BuildContext context) {
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
                'HADITH',
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
                    'The Sayings of Prophet Muhammad ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                  ),
                  Text('ﷺ',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        _buildTopActionBtn(
          icon: Icons.search_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.bookmark_border_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.tune_rounded,
          onTap: () {},
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

  // 2. HERO TODAY'S HADITH CARD
  Widget _buildTodaysHadithHero(BuildContext context) {
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
                  colors: [Color(0xEA050806), Color(0xFA020302)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '— TODAY\'S HADITH —',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2E21),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '"Actions are but by intentions and every person shall have only that which he intended."',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sahih Bukhari 1 • Book of Revelation',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold),
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
                        _buildHeroActionButton(
                            Icons.menu_book_rounded, 'Read Full Hadith', () {}),
                        _buildHeroActionButton(
                            Icons.bookmark_border_rounded, 'Bookmark', () {}),
                        _buildHeroActionButton(Icons.share_outlined, 'Share',
                            () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Hadith copied to clipboard! 📋'),
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

  Widget _buildHeroActionButton(
      IconData icon, String label, VoidCallback onTap) {
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

  // 3. 4 METRIC CARDS ROW
  Widget _buildFourMetricsRow() {
    final metrics = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Collections',
        'value': '42',
        'sub': 'Explore >',
        'color': const Color(0xFF00E676)
      },
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Hadiths',
        'value': '12,563',
        'sub': 'Browse >',
        'color': const Color(0xFFFFB703)
      },
      {
        'icon': Icons.bookmark_rounded,
        'title': 'Bookmarked',
        'value': '87',
        'sub': 'View All >',
        'color': const Color(0xFFC084FC)
      },
      {
        'icon': Icons.check_circle_outline_rounded,
        'title': 'Completed',
        'value': '15%',
        'sub': 'Your Progress >',
        'color': const Color(0xFFFFB703)
      },
    ];

    return Row(
      children: metrics.map((m) {
        final color = m['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(m['icon'] as IconData, color: color, size: 16),
                const SizedBox(height: 4),
                Text(m['title'] as String,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 7.5)),
                Text(m['value'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(m['sub'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 4. BROWSE COLLECTIONS
  Widget _buildBrowseCollectionsSection(
      BuildContext context, List<HadithBook>? books) {
    final collections = [
      {
        'name': 'Sahih\nBukhari',
        'hadiths': '7,275 Hadiths',
        'icon': '⭐',
        'slug': 'bukhari'
      },
      {
        'name': 'Sahih\nMuslim',
        'hadiths': '4,341 Hadiths',
        'icon': '📖',
        'slug': 'muslim'
      },
      {
        'name': 'Sunan\nAbu Dawud',
        'hadiths': '4,803 Hadiths',
        'icon': '🕌',
        'slug': 'abudawud'
      },
      {
        'name': 'Jami\' At\nTirmidhi',
        'hadiths': '3,953 Hadiths',
        'icon': '📜',
        'slug': 'tirmidhi'
      },
      {
        'name': 'Sunan\nAn-Nasa\'i',
        'hadiths': '5,756 Hadiths',
        'icon': '🕋',
        'slug': 'nasai'
      },
      {
        'name': 'Sunan\nIbn Majah',
        'hadiths': '4,347 Hadiths',
        'icon': '📚',
        'slug': 'ibnmajah'
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('BROWSE COLLECTIONS',
                style: TextStyle(
                    color: Color(0xFFFFB703),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Text('View All >',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final c = collections[index];
              final isSelected = _selectedCollectionSlug == c['slug'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCollectionSlug = c['slug']!);
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF072418)
                          : const Color(0xFF080C0A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E676)
                            : const Color(0xFF1A221C),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 6),
                        Text(
                          c['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['hadiths']!,
                          style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF64748B),
                              fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 5. FILTER PILLS ROW
  Widget _buildFilterPillsRow() {
    final pills = [
      {'label': 'All Hadiths', 'icon': Icons.grid_view_rounded},
      {'label': 'Book', 'icon': Icons.menu_book_rounded},
      {'label': 'Chapter', 'icon': Icons.folder_open_rounded},
      {'label': 'Topics', 'icon': Icons.chat_bubble_outline_rounded},
    ];

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: pills.length,
              itemBuilder: (context, index) {
                final p = pills[index];
                final isSelected = _selectedFilterPill == p['label'];

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(
                          () => _selectedFilterPill = p['label'] as String);
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
                      child: Row(
                        children: [
                          Icon(p['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF94A3B8),
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                            p['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
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

  // 6. RECENT HADITHS
  Widget _buildRecentHadithsSection(BuildContext context) {
    final recent = [
      {
        'num': 1,
        'book': 'Sahih Bukhari',
        'sub': 'Book of Revelation • Hadith 1',
        'arabic':
            'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
        'trans':
            'Actions are but by intentions and every person shall have only that which he intended.',
      },
      {
        'num': 2,
        'book': 'Sahih Muslim',
        'sub': 'Book of Faith • Hadith 8',
        'arabic':
            'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
        'trans':
            'Whoever believes in Allah and the Last Day should speak good or remain silent.',
      },
      {
        'num': 3,
        'book': 'Sahih Bukhari',
        'sub': 'Book of Knowledge • Hadith 73',
        'arabic': 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ',
        'trans': 'Seeking knowledge is an obligation upon every Muslim.',
      },
      {
        'num': 4,
        'book': 'Sunan Tirmidhi',
        'sub': 'Book of Patience • Hadith 2398',
        'arabic': 'الصَّبْرُ نُورٌ',
        'trans': 'Patience is light.',
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('RECENT HADITHS',
                style: TextStyle(
                    color: Color(0xFFFFB703),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Text('View All >',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...recent.map((h) {
          final num = h['num'] as int;
          final isBookmarked = _bookmarkedHadiths.contains(num);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
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
                      Text('${h['book']} • ${h['sub']}',
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        h['arabic'] as String,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(h['trans'] as String,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9.5,
                              height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        if (isBookmarked) {
                          _bookmarkedHadiths.remove(num);
                        } else {
                          _bookmarkedHadiths.add(num);
                        }
                      }),
                      child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? const Color(0xFFFFB703)
                              : const Color(0xFF64748B),
                          size: 16),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF64748B), size: 12),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // 7. STUDY HADITH BANNER
  Widget _buildStudyHadithBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('📖', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STUDY HADITH',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Deepen your understanding of the Prophet\'s teachings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF072418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF144D34)),
            ),
            child: const Row(
              children: [
                Text('Start Learning',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.menu_book_rounded,
                    color: Color(0xFF00E676), size: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
