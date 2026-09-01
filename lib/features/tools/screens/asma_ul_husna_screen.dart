import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

part 'asma_ul_husna_screen.learn.dart';

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
      content: Text('Copied to clipboard',
          style: TextStyle(color: colors.textPrimary)),
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
        color: colors.surface,
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
                  style: AppArabicStyles.quranSmall.copyWith(
                    fontSize: 18,
                    color: colors.primary,
                  ),
                  textDirection: TextDirection.rtl,
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
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
            ),
            child: Text(
              '99',
              style: TextStyle(
                color: colors.primary,
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
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.textTertiary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or meaning...',
                  hintStyle:
                      TextStyle(color: colors.textTertiary, fontSize: 13),
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
                    color: colors.textTertiary, size: 18),
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
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textTertiary,
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
              color:
                  isSelected ? name.color.withValues(alpha: 0.08) : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? name.color.withValues(alpha: 0.16)
                    : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
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
                            color: name.color.withValues(alpha: 0.16)),
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
                            style: AppArabicStyles.quranBold.copyWith(
                              fontSize: 20,
                              color: name.color,
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
                              color: isFav ? colors.error : colors.textTertiary,
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
                          color: colors.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name.reference,
                            style: TextStyle(
                              color: colors.textSecondary,
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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
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
            const Icon(Icons.favorite_rounded, size: 48),
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
              'Tap the heart on any name to save it',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
            border: Border.all(color: name.color.withValues(alpha: 0.16)),
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
                    style: AppArabicStyles.quranSmall.copyWith(
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
                        color: colors.textSecondary,
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
}
