// lib/features/hadith/presentation/hadith_screen.dart
// ============================================================
// QIBRA AI — HADITH HOME SCREEN (Pixel-Perfect Flagship Luxury UI)
// Fully interactive: Real Database, Collections, Search, Bookmarks, Detail Sheets
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../providers/hadith_provider.dart';
import 'hadith_book_screen.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _selectedFilterPill = 'All Hadiths';
  String _selectedCollectionSlug = 'bukhari';

  static const List<Map<String, String>> _collectionConfigs = [
    {
      'name': 'Sahih\nBukhari',
      'fullName': 'Sahih al-Bukhari',
      'hadiths': '7,589 Hadiths',
      'icon': '⭐',
      'slug': 'bukhari',
      'author': 'Imam Muhammad al-Bukhari',
    },
    {
      'name': 'Sahih\nMuslim',
      'fullName': 'Sahih Muslim',
      'hadiths': '7,563 Hadiths',
      'icon': '📖',
      'slug': 'muslim',
      'author': 'Imam Muslim ibn al-Hajjaj',
    },
    {
      'name': 'Sunan\nAn-Nasa\'i',
      'fullName': 'Sunan an-Nasa\'i',
      'hadiths': '5,765 Hadiths',
      'icon': '🕋',
      'slug': 'nasai',
      'author': 'Imam Ahmad an-Nasa\'i',
    },
    {
      'name': 'Sunan\nAbu Dawud',
      'fullName': 'Sunan Abi Dawud',
      'hadiths': '5,274 Hadiths',
      'icon': '🕌',
      'slug': 'abudawud',
      'author': 'Imam Abu Dawud al-Sijistani',
    },
    {
      'name': 'Jami\' At\nTirmidhi',
      'fullName': 'Jami` at-Tirmidhi',
      'hadiths': '3,998 Hadiths',
      'icon': '📜',
      'slug': 'tirmidhi',
      'author': 'Imam Muhammad al-Tirmidhi',
    },
    {
      'name': 'Sunan\nIbn Majah',
      'fullName': 'Sunan Ibn Majah',
      'hadiths': '4,343 Hadiths',
      'icon': '📚',
      'slug': 'ibnmajah',
      'author': 'Imam Ibn Majah al-Qazwini',
    },
    {
      'name': 'Muwatta\nMalik',
      'fullName': 'Muwatta Malik',
      'hadiths': '1,858 Hadiths',
      'icon': '✨',
      'slug': 'malik',
      'author': 'Imam Malik ibn Anas',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final dailyHadithAsync = ref.watch(dailyHadithProvider);
    final featuredHadithsAsync = ref.watch(
      featuredHadithsProvider(
        _selectedFilterPill == 'All Hadiths' ? null : _selectedCollectionSlug,
      ),
    );
    final bookmarks = ref.watch(hadithBookmarksProvider);

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
              dailyHadithAsync.when(
                data: (hadith) => _buildTodaysHadithHero(context, hadith),
                loading: () => _buildHeroPlaceholder(),
                error: (_, __) => _buildTodaysHadithHero(context, null),
              ),
              const SizedBox(height: 16),

              // 3. 4 METRIC CARDS ROW
              _buildFourMetricsRow(context, bookmarks.length),
              const SizedBox(height: 18),

              // 4. BROWSE COLLECTIONS (7 KUTUB AL-HADITH CARDS)
              _buildBrowseCollectionsSection(context),
              const SizedBox(height: 18),

              // 5. FILTER PILLS ROW
              _buildFilterPillsRow(),
              const SizedBox(height: 14),

              // 6. RECENT / FEATURED HADITHS LIST
              featuredHadithsAsync.when(
                data: (hadiths) => _buildRecentHadithsSection(context, hadiths),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF00E676)),
                  ),
                ),
                error: (_, __) => _buildFallbackRecentHadiths(context),
              ),
              const SizedBox(height: 18),

              // 7. STUDY HADITH BANNER
              _buildStudyHadithBanner(context),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. TOP APP BAR
  // ============================================================
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
          onTap: () => _showSearchSheet(context),
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.bookmark_border_rounded,
          onTap: () => _showBookmarksSheet(context),
        ),
        const SizedBox(width: 8),
        _buildTopActionBtn(
          icon: Icons.tune_rounded,
          onTap: () => _showCollectionsSheet(context),
        ),
      ],
    );
  }

  Widget _buildTopActionBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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

  // ============================================================
  // 2. HERO TODAY'S HADITH CARD
  // ============================================================
  Widget _buildTodaysHadithHero(BuildContext context, HadithModel? hadith) {
    final arabicText = hadith?.textArabic.isNotEmpty == true
        ? hadith!.textArabic
        : 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى';
    final englishText = hadith?.textEnglish.isNotEmpty == true
        ? hadith!.textEnglish
        : 'Actions are but by intentions and every person shall have only that which he intended.';
    final reference =
        hadith?.displayReference ?? 'Sahih Bukhari 1 • Book of Revelation';
    final numStr = hadith != null ? '${hadith.hadithNumber}' : '1';

    final isBookmarked =
        hadith != null && ref.watch(isHadithBookmarkedProvider(hadith.id));

    return GestureDetector(
      onTap: () {
        if (hadith != null) {
          _showHadithDetailSheet(context, hadith);
        } else {
          _openSpecificHadith(context, 'bukhari', 1);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.50,
                  child: Image.asset(
                    'assets/images/hero/mosque_night.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF040A07).withValues(alpha: 0.40),
                      const Color(0xFF020503).withValues(alpha: 0.88),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2E21),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Sahih / Authentic',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2E21),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00E676)),
                          ),
                          child: Center(
                            child: Text(
                              numStr,
                              style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            arabicText,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Amiri',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$englishText"',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reference,
                      style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C120E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1C2620)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeroActionButton(
                            Icons.menu_book_rounded,
                            'Read Full Hadith',
                            () {
                              if (hadith != null) {
                                _showHadithDetailSheet(context, hadith);
                              } else {
                                _openSpecificHadith(context, 'bukhari', 1);
                              }
                            },
                          ),
                          _buildHeroActionButton(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            isBookmarked ? 'Bookmarked' : 'Bookmark',
                            () {
                              HapticFeedback.lightImpact();
                              if (hadith != null) {
                                ref
                                    .read(hadithBookmarksProvider.notifier)
                                    .toggleBookmark(hadith);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBookmarked
                                        ? 'Hadith removed from bookmarks'
                                        : 'Hadith saved to bookmarks! ⭐'),
                                    backgroundColor: const Color(0xFF0B2E21),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildHeroActionButton(
                            Icons.share_outlined,
                            'Share',
                            () {
                              HapticFeedback.lightImpact();
                              final shareText =
                                  '$arabicText\n\n"$englishText"\n\n— $reference';
                              Clipboard.setData(ClipboardData(text: shareText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Hadith copied to clipboard! 📋'),
                                  backgroundColor: Color(0xFF0B2E21),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
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

  // ============================================================
  // 3. 4 METRIC CARDS ROW
  // ============================================================
  Widget _buildFourMetricsRow(BuildContext context, int bookmarkCount) {
    final metrics = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Collections',
        'value': '7 Books',
        'sub': 'Explore >',
        'color': const Color(0xFF00E676),
        'onTap': () => _showCollectionsSheet(context),
      },
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Hadiths',
        'value': '36,390',
        'sub': 'Browse >',
        'color': const Color(0xFFFFB703),
        'onTap': () => _openBookBySlug(context, 'bukhari'),
      },
      {
        'icon': Icons.bookmark_rounded,
        'title': 'Bookmarked',
        'value': '$bookmarkCount',
        'sub': 'View All >',
        'color': const Color(0xFFC084FC),
        'onTap': () => _showBookmarksSheet(context),
      },
      {
        'icon': Icons.check_circle_outline_rounded,
        'title': 'Authenticity',
        'value': '100% Sahih',
        'sub': 'Verified >',
        'color': const Color(0xFF38BDF8),
        'onTap': () => _showAuthenticityDialog(context),
      },
    ];

    return Row(
      children: metrics.map((m) {
        final color = m['color'] as Color;
        final onTap = m['onTap'] as VoidCallback;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
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
                          fontSize: 11.5,
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
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 4. BROWSE COLLECTIONS (7 KUTUB AL-HADITH CARDS)
  // ============================================================
  Widget _buildBrowseCollectionsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BROWSE COLLECTIONS',
                style: TextStyle(
                    color: Color(0xFFFFB703),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () => _showCollectionsSheet(context),
              child: const Text('View All (7) >',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _collectionConfigs.length,
            itemBuilder: (context, index) {
              final c = _collectionConfigs[index];
              final isSelected = _selectedCollectionSlug == c['slug'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCollectionSlug = c['slug']!;
                    });
                    _openBookBySlug(context, c['slug']!);
                  },
                  child: Container(
                    width: 96,
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

  // ============================================================
  // 5. FILTER PILLS ROW
  // ============================================================
  Widget _buildFilterPillsRow() {
    final pills = [
      {'label': 'All Hadiths', 'icon': Icons.grid_view_rounded, 'slug': ''},
      {'label': 'Bukhari', 'icon': Icons.menu_book_rounded, 'slug': 'bukhari'},
      {'label': 'Muslim', 'icon': Icons.menu_book_rounded, 'slug': 'muslim'},
      {
        'label': 'Tirmidhi',
        'icon': Icons.auto_stories_rounded,
        'slug': 'tirmidhi'
      },
      {
        'label': 'Abu Dawud',
        'icon': Icons.library_books_rounded,
        'slug': 'abudawud'
      },
      {'label': 'Nasai', 'icon': Icons.book_outlined, 'slug': 'nasai'},
      {
        'label': 'Ibn Majah',
        'icon': Icons.import_contacts_rounded,
        'slug': 'ibnmajah'
      },
      {
        'label': 'Malik',
        'icon': Icons.collections_bookmark_rounded,
        'slug': 'malik'
      },
    ];

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
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
                      setState(() {
                        _selectedFilterPill = p['label'] as String;
                        final slug = p['slug'] as String;
                        if (slug.isNotEmpty) {
                          _selectedCollectionSlug = slug;
                        }
                      });
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
        GestureDetector(
          onTap: () => _showCollectionsSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        ),
      ],
    );
  }

  // ============================================================
  // 6. RECENT / FEATURED HADITHS SECTION
  // ============================================================
  Widget _buildRecentHadithsSection(
      BuildContext context, List<HadithModel> hadiths) {
    if (hadiths.isEmpty) {
      return _buildFallbackRecentHadiths(context);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedFilterPill == 'All Hadiths'
                  ? 'FEATURED HADITHS'
                  : 'HADITHS IN ${_selectedFilterPill.toUpperCase()}',
              style: const TextStyle(
                  color: Color(0xFFFFB703),
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () => _openBookBySlug(context, _selectedCollectionSlug),
              child: const Text('View Full Book >',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...hadiths.map((h) => _buildHadithTile(context, h)),
      ],
    );
  }

  Widget _buildHadithTile(BuildContext context, HadithModel h) {
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(h.id));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showHadithDetailSheet(context, h);
      },
      child: Container(
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1410),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF163E2C)),
              ),
              child: Center(
                child: Text(
                  '${h.hadithNumber}',
                  style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${h.bookName} • Hadith #${h.hadithNumber}',
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2E21),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          h.grade.label,
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (h.hasArabic) ...[
                    const SizedBox(height: 6),
                    Text(
                      h.textArabic,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Amiri',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          height: 1.4),
                    ),
                  ],
                  if (h.hasUrdu) ...[
                    const SizedBox(height: 4),
                    Text(
                      h.textUrdu,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 10.5,
                          height: 1.3),
                    ),
                  ],
                  if (h.hasEnglish) ...[
                    const SizedBox(height: 4),
                    Text(
                      h.textEnglish,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(hadithBookmarksProvider.notifier)
                        .toggleBookmark(h);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBookmarked
                            ? 'Removed from bookmarks'
                            : 'Saved to bookmarks! ⭐'),
                        backgroundColor: const Color(0xFF0B2E21),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked
                          ? const Color(0xFFFFB703)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF64748B), size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackRecentHadiths(BuildContext context) {
    final recent = [
      {
        'num': 1,
        'book': 'Sahih al-Bukhari',
        'sub': 'Book of Revelation • Hadith 1',
        'arabic':
            'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
        'trans':
            'Actions are but by intentions and every person shall have only that which he intended.',
        'slug': 'bukhari',
      },
      {
        'num': 8,
        'book': 'Sahih Muslim',
        'sub': 'Book of Faith • Hadith 8',
        'arabic':
            'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
        'trans':
            'Whoever believes in Allah and the Last Day should speak good or remain silent.',
        'slug': 'muslim',
      },
      {
        'num': 73,
        'book': 'Sahih al-Bukhari',
        'sub': 'Book of Knowledge • Hadith 73',
        'arabic': 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ',
        'trans': 'Seeking knowledge is an obligation upon every Muslim.',
        'slug': 'bukhari',
      },
      {
        'num': 2398,
        'book': 'Jami` at-Tirmidhi',
        'sub': 'Book of Patience • Hadith 2398',
        'arabic': 'الصَّبْرُ نُورٌ',
        'trans': 'Patience is light.',
        'slug': 'tirmidhi',
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT HADITHS',
                style: TextStyle(
                    color: Color(0xFFFFB703),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () => _openBookBySlug(context, 'bukhari'),
              child: const Text('View All >',
                  style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recent.map((h) {
          final slug = h['slug'] as String;
          final num = h['num'] as int;

          return GestureDetector(
            onTap: () => _openSpecificHadith(context, slug, num),
            child: Container(
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
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF64748B), size: 12),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // 7. STUDY HADITH BANNER
  // ============================================================
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
            width: 46,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/quran_cover.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                    child: Text('📖', style: TextStyle(fontSize: 22))),
              ),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _openBookBySlug(context, 'bukhari');
            },
            child: Container(
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION & DETAIL SHEETS
  // ============================================================

  void _openBookBySlug(BuildContext context, String slug) {
    final db = HadithDatabaseService();
    final bookInfo = db.getBookInfo(slug);

    final book = HadithBook(
      id: slug,
      slug: slug,
      name: bookInfo?.name ?? _getCollectionFullName(slug),
      nameArabic: '',
      author: _getCollectionAuthor(slug),
      authorArabic: '',
      totalHadiths: bookInfo?.totalHadiths ?? 0,
      totalChapters: bookInfo?.sections.length ?? 0,
      description: 'Authentic prophetic hadiths and narrations.',
      color: const Color(0xFF00A86B),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HadithBookScreen(book: book),
      ),
    );
  }

  void _openSpecificHadith(
      BuildContext context, String slug, int hadithNumber) {
    final db = HadithDatabaseService();
    final local = db.getHadith(slug, hadithNumber);
    if (local != null) {
      _showHadithDetailSheet(context, localToHadithModel(local));
    } else {
      _openBookBySlug(context, slug);
    }
  }

  String _getCollectionFullName(String slug) {
    for (final c in _collectionConfigs) {
      if (c['slug'] == slug) return c['fullName']!;
    }
    return 'Hadith Collection';
  }

  String _getCollectionAuthor(String slug) {
    for (final c in _collectionConfigs) {
      if (c['slug'] == slug) return c['author']!;
    }
    return 'Islamic Scholar';
  }

  // ────────────────────────────────────────────────────────────
  // 1. HADITH DETAIL BOTTOM SHEET
  // ────────────────────────────────────────────────────────────
  void _showHadithDetailSheet(BuildContext context, HadithModel hadith) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final isBookmarked =
                ref.watch(isHadithBookmarkedProvider(hadith.id));

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF060B08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5),
                  left: BorderSide(color: Color(0xFF1E3A2B), width: 1.0),
                  right: BorderSide(color: Color(0xFF1E3A2B), width: 1.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2E21),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00E676)),
                          ),
                          child: Text(
                            '#${hadith.hadithNumber}',
                            style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hadith.grade.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    hadith.grade.color.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(hadith.grade.icon,
                                  color: hadith.grade.color, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                hadith.grade.label,
                                style: TextStyle(
                                    color: hadith.grade.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isBookmarked
                                ? const Color(0xFFFFB703)
                                : Colors.white70,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(hadithBookmarksProvider.notifier)
                                .toggleBookmark(hadith);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded,
                              color: Colors.white70),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final text =
                                '${hadith.textArabic}\n\n${hadith.textUrdu}\n\n"${hadith.textEnglish}"\n\n— ${hadith.displayReference}';
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Hadith copied to clipboard! 📋'),
                                  backgroundColor: Color(0xFF0B2E21),
                                  duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF142018), height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            hadith.displayReference,
                            style: const TextStyle(
                                color: Color(0xFFFFB703),
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          if (hadith.chapterName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Chapter: ${hadith.chapterName}',
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (hadith.hasArabic) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A140F),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFF1E3A2B)),
                              ),
                              child: SelectableText(
                                hadith.textArabic,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Amiri',
                                  fontSize: 20,
                                  height: 1.8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (hadith.hasUrdu) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF081810),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded,
                                            color: Color(0xFF00E676), size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: hadith.textUrdu));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Urdu text copied!'),
                                                backgroundColor:
                                                    Color(0xFF0B2E21),
                                                duration: Duration(seconds: 1)),
                                          );
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('اردو ترجمہ',
                                            style: TextStyle(
                                                color: Color(0xFF00E676),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    hadith.textUrdu,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: Color(0xFFD1FAE5),
                                      fontSize: 16,
                                      height: 1.8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (hadith.hasEnglish) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B121C),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFF1E3A5F)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('ENGLISH TRANSLATION',
                                            style: TextStyle(
                                                color: Color(0xFF38BDF8),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded,
                                            color: Color(0xFF38BDF8), size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: hadith.textEnglish));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'English translation copied!'),
                                                backgroundColor:
                                                    Color(0xFF0B2E21),
                                                duration: Duration(seconds: 1)),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    hadith.textEnglish,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: Text(
                              'Open ${hadith.bookName} Full Book',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openBookBySlug(context, hadith.bookSlug);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // 2. LIVE HADITH SEARCH SHEET
  // ────────────────────────────────────────────────────────────
  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = ref.watch(hadithSearchQueryProvider);
            final searchResults = ref.watch(hadithSearchResultsProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Color(0xFF060B08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0C1410),
                        hintText:
                            'Search 36,390 Hadiths (English, Urdu, Arabic)...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFFFFB703), size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: Colors.white70, size: 18),
                                onPressed: () {
                                  ref
                                      .read(hadithSearchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E3A2B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E3A2B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF00E676), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                      onChanged: (val) {
                        ref.read(hadithSearchQueryProvider.notifier).state =
                            val;
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          query.trim().isEmpty
                              ? 'POPULAR SEARCHES'
                              : 'SEARCH RESULTS',
                          style: const TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        if (query.trim().isNotEmpty)
                          searchResults.when(
                            data: (res) => Text('${res.length} matches',
                                style: const TextStyle(
                                    color: Color(0xFF00E676), fontSize: 10)),
                            loading: () => const Text('Searching...',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 10)),
                            error: (_, __) => const SizedBox(),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: query.trim().isEmpty
                        ? _buildSearchSuggestions(sheetContext)
                        : searchResults.when(
                            data: (results) {
                              if (results.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No hadiths found matching your query.\nTry keywords like "intention", "prayer", "fasting", "patience".',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final item = results[index];
                                  final h = item.hadith;

                                  return GestureDetector(
                                    onTap: () {
                                      _showHadithDetailSheet(context, h);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF080C0A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFF1A221C)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                h.displayReference,
                                                style: const TextStyle(
                                                    color: Color(0xFF00E676),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF0B2E21),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.matchType.label,
                                                  style: const TextStyle(
                                                      color: Color(0xFF00E676),
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (h.hasArabic) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              h.textArabic,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Amiri',
                                                  fontSize: 13),
                                            ),
                                          ],
                                          if (h.hasEnglish) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              h.textEnglish,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 10.5),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00E676)),
                            ),
                            error: (e, _) => Center(
                              child: Text('Search error: $e',
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSuggestions(BuildContext sheetContext) {
    final suggestions = [
      'Intention / Niyyah',
      'Prayer / Salah',
      'Charity / Sadaqah',
      'Patience / Sabr',
      'Knowledge / Ilm',
      'Parents / Walidain',
      'Repentance / Tawbah',
      'Fasting / Sawm',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            final query = s.split('/').first.trim();
            return ActionChip(
              backgroundColor: const Color(0xFF0A1410),
              side: const BorderSide(color: Color(0xFF1E3A2B)),
              label: Text(s,
                  style:
                      const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
              onPressed: () {
                ref.read(hadithSearchQueryProvider.notifier).state = query;
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // 3. SAVED BOOKMARKS SHEET
  // ────────────────────────────────────────────────────────────
  void _showBookmarksSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final bookmarks = ref.watch(hadithBookmarksProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF060B08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BOOKMARKED HADITHS',
                            style: TextStyle(
                                color: Color(0xFFFFB703),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        if (bookmarks.isNotEmpty)
                          Text('${bookmarks.length} saved',
                              style: const TextStyle(
                                  color: Color(0xFF00E676), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF142018), height: 1),
                  Expanded(
                    child: bookmarks.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_border_rounded,
                                      color: Color(0xFF64748B), size: 48),
                                  SizedBox(height: 12),
                                  Text(
                                    'No saved hadiths yet',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap the bookmark icon on any hadith to save it here for quick access.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: bookmarks.length,
                            itemBuilder: (context, index) {
                              final bm = bookmarks[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF080C0A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF1A221C)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${bm.bookName} #${bm.hadithNumber}',
                                            style: const TextStyle(
                                                color: Color(0xFF00E676),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bm.textPreview,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Color(0xFFCBD5E1),
                                                fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 18),
                                      onPressed: () {
                                        ref
                                            .read(hadithBookmarksProvider
                                                .notifier)
                                            .removeBookmark(bm.hadithId);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // 4. ALL COLLECTIONS MODAL SHEET
  // ────────────────────────────────────────────────────────────
  void _showCollectionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF060B08),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KUTUB AL-HADITH (7 COLLECTIONS)',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text('Offline Ready ⚡',
                        style:
                            TextStyle(color: Color(0xFF00E676), fontSize: 11)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF142018), height: 1),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _collectionConfigs.length,
                  itemBuilder: (context, index) {
                    final c = _collectionConfigs[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _openBookBySlug(context, c['slug']!);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080C0A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1A221C)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B2E21),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: const Color(0xFF00E676)),
                              ),
                              child: Center(
                                child: Text(c['icon']!,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['fullName']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c['author']} • ${c['hadiths']}',
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF00E676), size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAuthenticityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF080C0A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF1E3A2B))),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 22),
              SizedBox(width: 8),
              Text('Hadith Authenticity',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Qibra AI contains all 7 major authentic Hadith collections (Kutub al-Sittah + Muwatta Imam Malik) containing 36,390 narrations with Arabic text, Urdu, and English translations. All hadiths are verified for authenticity.',
            style: TextStyle(
                color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close',
                  style: TextStyle(
                      color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
