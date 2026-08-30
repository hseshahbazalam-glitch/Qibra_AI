import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<_AsmaName> _filteredNames = [];
  Set<int> _favorites = {};
  int? _selectedIndex;
  String _searchQuery = '';

  static const String _favKey = 'asma_favorites';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredNames = _allNames;
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_favKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() => _favorites = list.map((e) => e as int).toSet());
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(_favorites.toList()));
  }

  void _toggleFavorite(int number) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favorites.contains(number)) {
        _favorites.remove(number);
      } else {
        _favorites.add(number);
      }
    });
    _saveFavorites();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNames = _allNames;
      } else {
        _filteredNames = _allNames
            .where(
              (n) =>
                  n.arabic.contains(query) ||
                  n.transliteration
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  n.meaning.toLowerCase().contains(query.toLowerCase()) ||
                  n.urdu.contains(query),
            )
            .toList();
      }
    });
  }

  void _copyName(_AsmaName name) {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(
      text: '${name.arabic}\n${name.transliteration}\n${name.meaning}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied! 📋', style: TextStyle(color: colors.textPrimary)),
      backgroundColor: colors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    final colors = QibraColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.backgroundSecondary, colors.background],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: colors.textPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أَسْمَاءُ اللَّهِ الْحُسْنَى',
                  style: TextStyle(
                    color: colors.primarySoft,
                    fontSize: 18,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  '99 Names of Allah',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primarySoft.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colors.primarySoft.withValues(alpha: 0.3)),
            ),
            child: Text(
              '99',
              style: TextStyle(
                color: colors.primarySoft,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: colors.textPrimary.withValues(alpha: 0.3), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or meaning...',
                  hintStyle: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.2), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearch('');
                },
                child: Icon(Icons.close_rounded,
                    color: colors.textPrimary.withValues(alpha: 0.3), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colors.primarySoft.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: colors.primarySoft.withValues(alpha: 0.4)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colors.primarySoft,
          unselectedLabelColor: colors.textPrimary.withValues(alpha: 0.35),
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'All 99'),
            Tab(text: 'Favorites'),
            Tab(text: 'Learn'),
          ],
        ),
      ),
    );
  }

  // ─── Tab Content ────────────────────────────────────────────
  Widget _buildTabContent() {
    final colors = QibraColors.of(context);
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllNamesTab(),
        _buildFavoritesTab(),
        _buildLearnTab(),
      ],
    );
  }

  // ─── All Names Tab ──────────────────────────────────────────
  Widget _buildAllNamesTab() {
    final colors = QibraColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredNames.length,
      itemBuilder: (ctx, i) {
        final name = _filteredNames[i];
        final isSelected = _selectedIndex == i;
        final isFav = _favorites.contains(name.number);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedIndex = isSelected ? null : i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? name.color.withValues(alpha: 0.08)
                  : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? name.color.withValues(alpha: 0.4)
                    : colors.textPrimary.withValues(alpha: 0.05),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: name.color.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Number Badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: name.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: name.color.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          '${name.number}',
                          style: TextStyle(
                            color: name.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Arabic + Transliteration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.arabic,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 20,
                              color: name.color,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            name.transliteration,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleFavorite(name.number),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav
                                  ? colors.error
                                  : colors.textTertiary,
                              size: 20,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyName(name),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.copy_rounded,
                              color: colors.textTertiary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Expanded details
                if (isSelected) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: name.color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: name.color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Meaning', name.meaning, name.color),
                        const SizedBox(height: 6),
                        _detailRow('Urdu', name.urdu, name.color),
                        const SizedBox(height: 6),
                        _detailRow('Benefits', name.benefit, name.color),
                        const SizedBox(height: 6),
                        _detailRow(
                            'Recite', '${name.reciteCount}x daily', name.color),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quran Reference
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              colors.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name.reference,
                            style: TextStyle(
                              color: colors.textPrimary.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    final colors = QibraColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.7),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Favorites Tab ──────────────────────────────────────────
  Widget _buildFavoritesTab() {
    final colors = QibraColors.of(context);
    final favNames =
        _allNames.where((n) => _favorites.contains(n.number)).toList();

    if (favNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💜', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap ❤️ on any name to save it',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: favNames.length,
      itemBuilder: (ctx, i) {
        final name = favNames[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: name.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: name.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: name.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.arabic.split(' ').first,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: name.color,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.transliteration,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      name.meaning,
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFavorite(name.number),
                child: Icon(
                  Icons.favorite_rounded,
                  color: colors.error,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Learn Tab ──────────────────────────────────────────────
  Widget _buildLearnTab() {
    final colors = QibraColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.backgroundSecondary, colors.card],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: colors.primarySoft.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('📿', '99', 'Total Names'),
                _divider(),
                _statItem('💜', '${_favorites.length}', 'Favorites'),
                _divider(),
                _statItem('✅', '${_favorites.length}', 'Learned'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hadith Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('📖', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text(
                      'Hadith',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"Allah has ninety-nine Names, one hundred minus one. Whoever memorizes them all (by heart) will enter Paradise." — Bukhari',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Groups
          _buildGroupCard(
              'Names of Mercy',
              '💚',
              colors.primary,
              _allNames
                  .where((n) =>
                      [1, 2, 3, 7, 12, 32, 36, 79, 80].contains(n.number))
                  .toList()),
          const SizedBox(height: 12),
          _buildGroupCard(
              'Names of Power',
              '⚡',
              colors.accent,
              _allNames
                  .where((n) =>
                      [6, 8, 9, 10, 14, 37, 38, 41, 48, 61].contains(n.number))
                  .toList()),
          const SizedBox(height: 12),
          _buildGroupCard(
              'Names of Knowledge',
              '📚',
              colors.primarySoft,
              _allNames
                  .where((n) =>
                      [19, 27, 29, 30, 31, 39, 40, 50].contains(n.number))
                  .toList()),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    final colors = QibraColors.of(context);
    return Container(
        width: 1, height: 40, color: colors.textPrimary.withValues(alpha: 0.1));
  }

  Widget _buildGroupCard(
      String title, String emoji, Color color, List<_AsmaName> names) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names.map((n) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(
                  n.transliteration,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════
class _AsmaName {
  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String urdu;
  final String benefit;
  final String reference;
  final int reciteCount;
  final Color color;

  const _AsmaName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.urdu,
    required this.benefit,
    required this.reference,
    required this.reciteCount,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════
// 99 NAMES DATABASE
// ═══════════════════════════════════════════════════════════
final List<_AsmaName> _allNames = [
  _AsmaName(
      number: 1,
      arabic: 'اللَّهُ',
      transliteration: 'Allah',
      meaning: 'The Greatest Name',
      urdu: 'اللہ',
      benefit: 'The supreme name of God encompassing all attributes',
      reference: 'Quran 1:1 — The foundational name of God',
      reciteCount: 1000,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 2,
      arabic: 'الرَّحْمَنُ',
      transliteration: 'Ar-Rahman',
      meaning: 'The Most Gracious',
      urdu: 'بڑا مہربان',
      benefit: 'Recite for mercy and blessings in this world',
      reference: 'Quran 1:3 — "Bismillah ir-Rahman ir-Raheem"',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 3,
      arabic: 'الرَّحِيمُ',
      transliteration: 'Ar-Raheem',
      meaning: 'The Most Merciful',
      urdu: 'نہایت رحم والا',
      benefit: 'Recite for mercy in the Hereafter',
      reference: 'Quran 1:3 — Most repeated name in Quran',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 4,
      arabic: 'الْمَلِكُ',
      transliteration: 'Al-Malik',
      meaning: 'The King',
      urdu: 'بادشاہ',
      benefit: 'Recite for dignity and authority',
      reference: 'Quran 20:114 — "So high above all is Allah, the Sovereign"',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 5,
      arabic: 'الْقُدُّوسُ',
      transliteration: 'Al-Quddus',
      meaning: 'The Most Holy',
      urdu: 'پاک',
      benefit: 'Recite to purify heart from sins',
      reference: 'Quran 62:1 — "Al-Malik Al-Quddus"',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 6,
      arabic: 'السَّلَامُ',
      transliteration: 'As-Salam',
      meaning: 'The Source of Peace',
      urdu: 'سلامتی دینے والا',
      benefit: 'Recite 160x on sick person for healing',
      reference: 'Quran 59:23',
      reciteCount: 160,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 7,
      arabic: 'الْمُؤْمِنُ',
      transliteration: 'Al-Mumin',
      meaning: 'The Guardian of Faith',
      urdu: 'امن دینے والا',
      benefit: 'Recite for safety from fears',
      reference: 'Quran 59:23',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 8,
      arabic: 'الْمُهَيْمِنُ',
      transliteration: 'Al-Muhaymin',
      meaning: 'The Protector',
      urdu: 'نگہبان',
      benefit: 'Recite to purify soul',
      reference: 'Quran 59:23',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 9,
      arabic: 'الْعَزِيزُ',
      transliteration: 'Al-Aziz',
      meaning: 'The Mighty',
      urdu: 'غالب',
      benefit: 'Recite for strength and dignity',
      reference: 'Quran 59:23',
      reciteCount: 40,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 10,
      arabic: 'الْجَبَّارُ',
      transliteration: 'Al-Jabbar',
      meaning: 'The Compeller',
      urdu: 'زبردست',
      benefit: 'Recite for protection from tyrants',
      reference: 'Quran 59:23',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 11,
      arabic: 'الْمُتَكَبِّرُ',
      transliteration: 'Al-Mutakabbir',
      meaning: 'The Supremely Great',
      urdu: 'بڑائی والا',
      benefit: 'Recite for respect and honor',
      reference: 'Quran 59:23',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 12,
      arabic: 'الْخَالِقُ',
      transliteration: 'Al-Khaliq',
      meaning: 'The Creator',
      urdu: 'پیدا کرنے والا',
      benefit: 'Recite for creativity and new beginnings',
      reference: 'Quran 59:24',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 13,
      arabic: 'الْبَارِئُ',
      transliteration: 'Al-Bari',
      meaning: 'The Originator',
      urdu: 'بنانے والا',
      benefit: 'Recite for good health',
      reference: 'Quran 59:24',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 14,
      arabic: 'الْمُصَوِّرُ',
      transliteration: 'Al-Musawwir',
      meaning: 'The Fashioner of Forms',
      urdu: 'صورت بنانے والا',
      benefit: 'Recite for beautiful children',
      reference: 'Quran 59:24',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 15,
      arabic: 'الْغَفَّارُ',
      transliteration: 'Al-Ghaffar',
      meaning: 'The Repeatedly Forgiving',
      urdu: 'بخشنے والا',
      benefit: 'Recite for forgiveness of sins',
      reference: 'Quran 20:82',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 16,
      arabic: 'الْقَهَّارُ',
      transliteration: 'Al-Qahhar',
      meaning: 'The Subduer',
      urdu: 'غالب آنے والا',
      benefit: 'Recite to overcome enemies',
      reference: 'Quran 13:16',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 17,
      arabic: 'الْوَهَّابُ',
      transliteration: 'Al-Wahhab',
      meaning: 'The Bestower',
      urdu: 'بہت عطا کرنے والا',
      benefit: 'Recite 40x after Fajr for blessings',
      reference: 'Quran 3:8',
      reciteCount: 40,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 18,
      arabic: 'الرَّزَّاقُ',
      transliteration: 'Ar-Razzaq',
      meaning: 'The Provider',
      urdu: 'رزق دینے والا',
      benefit: 'Recite for abundance in sustenance',
      reference: 'Quran 51:58',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 19,
      arabic: 'الْفَتَّاحُ',
      transliteration: 'Al-Fattah',
      meaning: 'The Opener',
      urdu: 'کھولنے والا',
      benefit: 'Recite for opening of doors',
      reference: 'Quran 34:26',
      reciteCount: 71,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 20,
      arabic: 'الْعَلِيمُ',
      transliteration: 'Al-Alim',
      meaning: 'The All-Knowing',
      urdu: 'سب جاننے والا',
      benefit: 'Recite for knowledge and wisdom',
      reference: 'Quran 2:158',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 21,
      arabic: 'الْقَابِضُ',
      transliteration: 'Al-Qabid',
      meaning: 'The Constrictor',
      urdu: 'روکنے والا',
      benefit: 'Recite for protection',
      reference: 'Quran 2:245',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 22,
      arabic: 'الْبَاسِطُ',
      transliteration: 'Al-Basit',
      meaning: 'The Expander',
      urdu: 'کشادگی دینے والا',
      benefit: 'Recite for expansion of wealth',
      reference: 'Quran 2:245',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 23,
      arabic: 'الْخَافِضُ',
      transliteration: 'Al-Khafid',
      meaning: 'The Reducer',
      urdu: 'پست کرنے والا',
      benefit: 'Recite for protection from enemies',
      reference: 'Not in Quran directly — Hadith',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 24,
      arabic: 'الرَّافِعُ',
      transliteration: 'Ar-Rafi',
      meaning: 'The Exalter',
      urdu: 'اونچا کرنے والا',
      benefit: 'Recite for elevation in status',
      reference: 'Quran 58:11',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 25,
      arabic: 'الْمُعِزُّ',
      transliteration: 'Al-Muizz',
      meaning: 'The Honourer',
      urdu: 'عزت دینے والا',
      benefit: 'Recite for honor and dignity',
      reference: 'Quran 3:26',
      reciteCount: 140,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 26,
      arabic: 'الْمُذِلُّ',
      transliteration: 'Al-Muzill',
      meaning: 'The Humiliator',
      urdu: 'ذلیل کرنے والا',
      benefit: 'Recite for protection from humiliation',
      reference: 'Quran 3:26',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 27,
      arabic: 'السَّمِيعُ',
      transliteration: 'As-Sami',
      meaning: 'The All-Hearing',
      urdu: 'سننے والا',
      benefit: 'Recite for answered duas',
      reference: 'Quran 2:127',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 28,
      arabic: 'الْبَصِيرُ',
      transliteration: 'Al-Basir',
      meaning: 'The All-Seeing',
      urdu: 'دیکھنے والا',
      benefit: 'Recite for good eyesight and insight',
      reference: 'Quran 17:1',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 29,
      arabic: 'الْحَكَمُ',
      transliteration: 'Al-Hakam',
      meaning: 'The Judge',
      urdu: 'فیصلہ کرنے والا',
      benefit: 'Recite for justice and guidance',
      reference: 'Quran 22:69',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 30,
      arabic: 'الْعَدْلُ',
      transliteration: 'Al-Adl',
      meaning: 'The Utterly Just',
      urdu: 'انصاف والا',
      benefit: 'Recite for justice in disputes',
      reference: 'Quran 6:115',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 31,
      arabic: 'اللَّطِيفُ',
      transliteration: 'Al-Latif',
      meaning: 'The Subtle One',
      urdu: 'مہربان',
      benefit: 'Recite 133x for relief from difficulties',
      reference: 'Quran 6:103',
      reciteCount: 133,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 32,
      arabic: 'الْخَبِيرُ',
      transliteration: 'Al-Khabir',
      meaning: 'The All-Aware',
      urdu: 'باخبر',
      benefit: 'Recite for awareness and knowledge',
      reference: 'Quran 6:18',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 33,
      arabic: 'الْحَلِيمُ',
      transliteration: 'Al-Halim',
      meaning: 'The Forbearing',
      urdu: 'بردبار',
      benefit: 'Recite for patience and tolerance',
      reference: 'Quran 2:225',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 34,
      arabic: 'الْعَظِيمُ',
      transliteration: 'Al-Azim',
      meaning: 'The Magnificent',
      urdu: 'بہت بڑا',
      benefit: 'Recite for greatness and honor',
      reference: 'Quran 2:255 — Ayat al-Kursi',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 35,
      arabic: 'الْغَفُورُ',
      transliteration: 'Al-Ghafur',
      meaning: 'The Forgiving',
      urdu: 'معاف کرنے والا',
      benefit: 'Recite for forgiveness of sins',
      reference: 'Quran 2:173',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 36,
      arabic: 'الشَّكُورُ',
      transliteration: 'Ash-Shakur',
      meaning: 'The Appreciative',
      urdu: 'قدر دان',
      benefit: 'Recite for gratitude and blessings',
      reference: 'Quran 35:30',
      reciteCount: 41,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 37,
      arabic: 'الْعَلِيُّ',
      transliteration: 'Al-Ali',
      meaning: 'The Most High',
      urdu: 'بلند',
      benefit: 'Recite for elevation and success',
      reference: 'Quran 2:255',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 38,
      arabic: 'الْكَبِيرُ',
      transliteration: 'Al-Kabir',
      meaning: 'The Great',
      urdu: 'بڑا',
      benefit: 'Recite for greatness',
      reference: 'Quran 13:9',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 39,
      arabic: 'الْحَفِيظُ',
      transliteration: 'Al-Hafiz',
      meaning: 'The Preserver',
      urdu: 'حفاظت کرنے والا',
      benefit: 'Recite for protection of self and family',
      reference: 'Quran 11:57',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 40,
      arabic: 'الْمُقِيتُ',
      transliteration: 'Al-Muqit',
      meaning: 'The Sustainer',
      urdu: 'قوت دینے والا',
      benefit: 'Recite for strength and nourishment',
      reference: 'Quran 4:85',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 41,
      arabic: 'الْحَسِيبُ',
      transliteration: 'Al-Hasib',
      meaning: 'The Reckoner',
      urdu: 'حساب لینے والا',
      benefit: 'Recite 70x morning/evening for protection',
      reference: 'Quran 4:6',
      reciteCount: 70,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 42,
      arabic: 'الْجَلِيلُ',
      transliteration: 'Al-Jalil',
      meaning: 'The Majestic',
      urdu: 'جلال والا',
      benefit: 'Recite for majesty and respect',
      reference: 'Quran 55:27',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 43,
      arabic: 'الْكَرِيمُ',
      transliteration: 'Al-Karim',
      meaning: 'The Generous',
      urdu: 'کریم',
      benefit: 'Recite for generosity and honor',
      reference: 'Quran 27:40',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 44,
      arabic: 'الرَّقِيبُ',
      transliteration: 'Ar-Raqib',
      meaning: 'The Watchful',
      urdu: 'نگران',
      benefit: 'Recite for protection',
      reference: 'Quran 4:1',
      reciteCount: 7,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 45,
      arabic: 'الْمُجِيبُ',
      transliteration: 'Al-Mujib',
      meaning: 'The Responsive',
      urdu: 'قبول کرنے والا',
      benefit: 'Recite for answered prayers',
      reference: 'Quran 11:61',
      reciteCount: 55,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 46,
      arabic: 'الْوَاسِعُ',
      transliteration: 'Al-Wasi',
      meaning: 'The All-Encompassing',
      urdu: 'وسعت والا',
      benefit: 'Recite for abundance and expansion',
      reference: 'Quran 2:115',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 47,
      arabic: 'الْحَكِيمُ',
      transliteration: 'Al-Hakim',
      meaning: 'The Wise',
      urdu: 'حکمت والا',
      benefit: 'Recite for wisdom in decisions',
      reference: 'Quran 2:32',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 48,
      arabic: 'الْوَدُودُ',
      transliteration: 'Al-Wadud',
      meaning: 'The Loving',
      urdu: 'محبت کرنے والا',
      benefit: 'Recite for love and harmony',
      reference: 'Quran 11:90',
      reciteCount: 1000,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 49,
      arabic: 'الْمَجِيدُ',
      transliteration: 'Al-Majid',
      meaning: 'The Glorious',
      urdu: 'بزرگ',
      benefit: 'Recite for glory',
      reference: 'Quran 11:73',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 50,
      arabic: 'الْبَاعِثُ',
      transliteration: 'Al-Baith',
      meaning: 'The Resurrector',
      urdu: 'اٹھانے والا',
      benefit: 'Recite for awakening of heart',
      reference: 'Quran 22:7',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 51,
      arabic: 'الشَّهِيدُ',
      transliteration: 'Ash-Shahid',
      meaning: 'The Witness',
      urdu: 'گواہ',
      benefit: 'Recite for truthfulness',
      reference: 'Quran 4:166',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 52,
      arabic: 'الْحَقُّ',
      transliteration: 'Al-Haqq',
      meaning: 'The Truth',
      urdu: 'سچا',
      benefit: 'Recite for truth and justice',
      reference: 'Quran 22:6',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 53,
      arabic: 'الْوَكِيلُ',
      transliteration: 'Al-Wakil',
      meaning: 'The Trustee',
      urdu: 'کارساز',
      benefit: 'Recite to put trust in Allah',
      reference: 'Quran 3:173',
      reciteCount: 66,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 54,
      arabic: 'الْقَوِيُّ',
      transliteration: 'Al-Qawiyy',
      meaning: 'The All-Strong',
      urdu: 'قوت والا',
      benefit: 'Recite for strength against enemies',
      reference: 'Quran 22:40',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 55,
      arabic: 'الْمَتِينُ',
      transliteration: 'Al-Matin',
      meaning: 'The Firm',
      urdu: 'مضبوط',
      benefit: 'Recite for firmness in faith',
      reference: 'Quran 51:58',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 56,
      arabic: 'الْوَلِيُّ',
      transliteration: 'Al-Waliyy',
      meaning: 'The Protecting Friend',
      urdu: 'دوست',
      benefit: 'Recite for divine friendship and support',
      reference: 'Quran 42:28',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 57,
      arabic: 'الْحَمِيدُ',
      transliteration: 'Al-Hamid',
      meaning: 'The Praiseworthy',
      urdu: 'تعریف کے لائق',
      benefit: 'Recite for gratitude',
      reference: 'Quran 2:267',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 58,
      arabic: 'الْمُحْصِي',
      transliteration: 'Al-Muhsi',
      meaning: 'The Reckoner',
      urdu: 'گننے والا',
      benefit: 'Recite to remember accountability',
      reference: 'Quran 78:29',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 59,
      arabic: 'الْمُبْدِئُ',
      transliteration: 'Al-Mubdi',
      meaning: 'The Originator',
      urdu: 'ابتدا کرنے والا',
      benefit: 'Recite for new beginnings',
      reference: 'Quran 85:13',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 60,
      arabic: 'الْمُعِيدُ',
      transliteration: 'Al-Mueed',
      meaning: 'The Restorer',
      urdu: 'لوٹانے والا',
      benefit: 'Recite to restore lost things',
      reference: 'Quran 85:13',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 61,
      arabic: 'الْمُحْيِي',
      transliteration: 'Al-Muhyi',
      meaning: 'The Giver of Life',
      urdu: 'زندگی دینے والا',
      benefit: 'Recite for spiritual life',
      reference: 'Quran 30:50',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 62,
      arabic: 'الْمُمِيتُ',
      transliteration: 'Al-Mumit',
      meaning: 'The Taker of Life',
      urdu: 'موت دینے والا',
      benefit: 'Recite to remember death and prepare',
      reference: 'Quran 3:156',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 63,
      arabic: 'الْحَيُّ',
      transliteration: 'Al-Hayy',
      meaning: 'The Ever-Living',
      urdu: 'ہمیشہ زندہ',
      benefit: 'Recite during illness for healing',
      reference: 'Quran 2:255 — Ayat al-Kursi',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 64,
      arabic: 'الْقَيُّومُ',
      transliteration: 'Al-Qayyum',
      meaning: 'The Self-Subsisting',
      urdu: 'قائم رہنے والا',
      benefit: 'Recite to not forget anything',
      reference: 'Quran 2:255 — Ayat al-Kursi',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 65,
      arabic: 'الْوَاجِدُ',
      transliteration: 'Al-Wajid',
      meaning: 'The Finder',
      urdu: 'پانے والا',
      benefit: 'Recite to find what is lost',
      reference: 'Hadith — Al-Tirmidhi',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 66,
      arabic: 'الْمَاجِدُ',
      transliteration: 'Al-Majid',
      meaning: 'The Noble',
      urdu: 'شریف',
      benefit: 'Recite for honor',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 67,
      arabic: 'الْوَاحِدُ',
      transliteration: 'Al-Wahid',
      meaning: 'The One',
      urdu: 'اکیلا',
      benefit: 'Recite to strengthen Tawheed',
      reference: 'Quran 13:16',
      reciteCount: 1000,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 68,
      arabic: 'الْأَحَدُ',
      transliteration: 'Al-Ahad',
      meaning: 'The Unique',
      urdu: 'یکتا',
      benefit: 'Recite Surah Ikhlas — equals 1/3 Quran',
      reference: 'Quran 112:1',
      reciteCount: 1000,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 69,
      arabic: 'الصَّمَدُ',
      transliteration: 'As-Samad',
      meaning: 'The Eternal',
      urdu: 'بے نیاز',
      benefit: 'Recite to become self-sufficient',
      reference: 'Quran 112:2',
      reciteCount: 125,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 70,
      arabic: 'الْقَادِرُ',
      transliteration: 'Al-Qadir',
      meaning: 'The All-Powerful',
      urdu: 'قدرت والا',
      benefit: 'Recite for achieving goals',
      reference: 'Quran 6:65',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 71,
      arabic: 'الْمُقْتَدِرُ',
      transliteration: 'Al-Muqtadir',
      meaning: 'The All-Determining',
      urdu: 'بالا دست',
      benefit: 'Recite for power to achieve',
      reference: 'Quran 18:45',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 72,
      arabic: 'الْمُقَدِّمُ',
      transliteration: 'Al-Muqaddim',
      meaning: 'The Expediter',
      urdu: 'آگے کرنے والا',
      benefit: 'Recite for advancement',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 73,
      arabic: 'الْمُؤَخِّرُ',
      transliteration: 'Al-Muakhkhir',
      meaning: 'The Delayer',
      urdu: 'پیچھے کرنے والا',
      benefit: 'Recite for patience',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 74,
      arabic: 'الْأَوَّلُ',
      transliteration: 'Al-Awwal',
      meaning: 'The First',
      urdu: 'پہلا',
      benefit: 'Recite for children (40 days after Fajr)',
      reference: 'Quran 57:3',
      reciteCount: 40,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 75,
      arabic: 'الْآخِرُ',
      transliteration: 'Al-Akhir',
      meaning: 'The Last',
      urdu: 'آخری',
      benefit: 'Recite to remember eternity of Allah',
      reference: 'Quran 57:3',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 76,
      arabic: 'الظَّاهِرُ',
      transliteration: 'Az-Zahir',
      meaning: 'The Manifest',
      urdu: 'ظاہر',
      benefit: 'Recite for divine vision',
      reference: 'Quran 57:3',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 77,
      arabic: 'الْبَاطِنُ',
      transliteration: 'Al-Batin',
      meaning: 'The Hidden',
      urdu: 'پوشیدہ',
      benefit: 'Recite for inner knowledge',
      reference: 'Quran 57:3',
      reciteCount: 33,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 78,
      arabic: 'الْوَالِي',
      transliteration: 'Al-Wali',
      meaning: 'The Governor',
      urdu: 'والی',
      benefit: 'Recite for leadership and governance',
      reference: 'Quran 13:11',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 79,
      arabic: 'الْمُتَعَالِي',
      transliteration: 'Al-Mutaali',
      meaning: 'The Self Exalted',
      urdu: 'بلند تر',
      benefit: 'Recite for exaltation',
      reference: 'Quran 13:9',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 80,
      arabic: 'الْبَرُّ',
      transliteration: 'Al-Barr',
      meaning: 'The Source of Goodness',
      urdu: 'نیکی کرنے والا',
      benefit: 'Recite for protection of children',
      reference: 'Quran 52:28',
      reciteCount: 7,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 81,
      arabic: 'التَّوَّابُ',
      transliteration: 'At-Tawwab',
      meaning: 'The Ever-Returning',
      urdu: 'توبہ قبول کرنے والا',
      benefit: 'Recite for acceptance of repentance',
      reference: 'Quran 2:37',
      reciteCount: 360,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 82,
      arabic: 'الْمُنْتَقِمُ',
      transliteration: 'Al-Muntaqim',
      meaning: 'The Avenger',
      urdu: 'انتقام لینے والا',
      benefit: 'Recite for justice against oppressors',
      reference: 'Quran 32:22',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 83,
      arabic: 'الْعَفُوُّ',
      transliteration: 'Al-Afuww',
      meaning: 'The Pardoner',
      urdu: 'معاف کرنے والا',
      benefit: 'Recite in Laylat al-Qadr for full pardon',
      reference: 'Quran 4:99',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 84,
      arabic: 'الرَّؤُوفُ',
      transliteration: 'Ar-Rauf',
      meaning: 'The Compassionate',
      urdu: 'شفقت کرنے والا',
      benefit: 'Recite for compassion and kindness',
      reference: 'Quran 2:143',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 85,
      arabic: 'مَالِكُ الْمُلْكِ',
      transliteration: 'Malik-ul-Mulk',
      meaning: 'Owner of Sovereignty',
      urdu: 'ملک کا مالک',
      benefit: 'Recite for stability and permanence',
      reference: 'Quran 3:26',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 86,
      arabic: 'ذُو الْجَلَالِ وَالإكرام',
      transliteration: 'Dhul-Jalali-wal-Ikram',
      meaning: 'Lord of Majesty and Bounty',
      urdu: 'جلال و اکرام والا',
      benefit: 'Recite for greatness and bounty',
      reference: 'Quran 55:27',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 87,
      arabic: 'الْمُقْسِطُ',
      transliteration: 'Al-Muqsit',
      meaning: 'The Just',
      urdu: 'انصاف کرنے والا',
      benefit: 'Recite to eliminate anger',
      reference: 'Quran 7:29',
      reciteCount: 209,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 88,
      arabic: 'الْجَامِعُ',
      transliteration: 'Al-Jami',
      meaning: 'The Gatherer',
      urdu: 'جمع کرنے والا',
      benefit: 'Recite for unity and gathering',
      reference: 'Quran 3:9',
      reciteCount: 114,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 89,
      arabic: 'الْغَنِيُّ',
      transliteration: 'Al-Ghani',
      meaning: 'The Self-Sufficient',
      urdu: 'بے نیاز',
      benefit: 'Recite for wealth and contentment',
      reference: 'Quran 3:97',
      reciteCount: 1000,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 90,
      arabic: 'الْمُغْنِي',
      transliteration: 'Al-Mughni',
      meaning: 'The Enricher',
      urdu: 'غنی کرنے والا',
      benefit: 'Recite for financial ease',
      reference: 'Quran 9:28',
      reciteCount: 10,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 91,
      arabic: 'الْمَانِعُ',
      transliteration: 'Al-Mani',
      meaning: 'The Withholder',
      urdu: 'روکنے والا',
      benefit: 'Recite for protection from harm',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 92,
      arabic: 'الضَّارُّ',
      transliteration: 'Ad-Darr',
      meaning: 'The Distresser',
      urdu: 'نقصان دینے والا',
      benefit: 'Recite to avoid harm',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.error),
  _AsmaName(
      number: 93,
      arabic: 'النَّافِعُ',
      transliteration: 'An-Nafi',
      meaning: 'The Benefactor',
      urdu: 'نفع دینے والا',
      benefit: 'Recite for benefit in all matters',
      reference: 'Hadith',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 94,
      arabic: 'النُّورُ',
      transliteration: 'An-Nur',
      meaning: 'The Light',
      urdu: 'نور',
      benefit: 'Recite for enlightenment of heart',
      reference: 'Quran 24:35 — Ayat an-Nur',
      reciteCount: 100,
      color: QibraColors.light.accent),
  _AsmaName(
      number: 95,
      arabic: 'الْهَادِي',
      transliteration: 'Al-Hadi',
      meaning: 'The Guide',
      urdu: 'ہدایت دینے والا',
      benefit: 'Recite for guidance in confusion',
      reference: 'Quran 22:54',
      reciteCount: 1100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 96,
      arabic: 'الْبَدِيعُ',
      transliteration: 'Al-Badi',
      meaning: 'The Incomparable',
      urdu: 'بے مثال',
      benefit: 'Recite for creativity',
      reference: 'Quran 2:117',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 97,
      arabic: 'الْبَاقِي',
      transliteration: 'Al-Baqi',
      meaning: 'The Everlasting',
      urdu: 'باقی رہنے والا',
      benefit: 'Recite for permanence in faith',
      reference: 'Quran 55:27',
      reciteCount: 100,
      color: QibraColors.light.primarySoft),
  _AsmaName(
      number: 98,
      arabic: 'الْوَارِثُ',
      transliteration: 'Al-Warith',
      meaning: 'The Inheritor',
      urdu: 'وارث',
      benefit: 'Recite for children and family protection',
      reference: 'Quran 15:23',
      reciteCount: 100,
      color: QibraColors.light.primary),
  _AsmaName(
      number: 99,
      arabic: 'الرَّشِيدُ',
      transliteration: 'Ar-Rashid',
      meaning: 'The Guide to Right Path',
      urdu: 'سیدھی راہ پر لانے والا',
      benefit: 'Recite for right guidance in all affairs',
      reference: 'Hadith',
      reciteCount: 1000,
      color: QibraColors.light.primarySoft),
];
