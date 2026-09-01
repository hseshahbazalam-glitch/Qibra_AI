import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class IslamicNameFinderScreen extends StatefulWidget {
  const IslamicNameFinderScreen({super.key});

  @override
  State<IslamicNameFinderScreen> createState() =>
      _IslamicNameFinderScreenState();
}

class _IslamicNameFinderScreenState extends State<IslamicNameFinderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _genderFilter = 'all'; // all, boy, girl
  String _letterFilter = '';
  Set<int> _favorites = {};
  List<_IslamicName> _filteredNames = [];
  _IslamicName? _randomName;

  static const String _favKey = 'name_finder_favorites';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filteredNames = _allNames;
    _loadFavorites();
    _generateRandom();
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
      setState(() =>
          _favorites = (jsonDecode(data) as List).map((e) => e as int).toSet());
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(_favorites.toList()));
  }

  void _toggleFavorite(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
    _saveFavorites();
  }

  void _generateRandom() {
    HapticFeedback.mediumImpact();
    final filtered = _genderFilter == 'all'
        ? _allNames
        : _allNames.where((n) => n.gender == _genderFilter).toList();
    setState(() => _randomName = filtered[Random().nextInt(filtered.length)]);
  }

  void _applyFilters() {
    setState(() {
      _filteredNames = _allNames.where((n) {
        // Gender filter
        if (_genderFilter != 'all' && n.gender != _genderFilter) return false;

        // Letter filter
        if (_letterFilter.isNotEmpty &&
            !n.name.toLowerCase().startsWith(_letterFilter.toLowerCase())) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          return n.name.toLowerCase().contains(q) ||
              n.meaning.toLowerCase().contains(q) ||
              n.arabic.contains(q) ||
              n.urduMeaning.contains(q);
        }
        return true;
      }).toList();
    });
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _setGender(String gender) {
    HapticFeedback.selectionClick();
    _genderFilter = gender;
    _applyFilters();
  }

  void _setLetter(String letter) {
    HapticFeedback.selectionClick();
    _letterFilter = _letterFilter == letter ? '' : letter;
    _applyFilters();
  }

  void _copyName(_IslamicName name) {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(
      text:
          '${name.name}\n${name.arabic}\nMeaning: ${name.meaning}\n${name.urduMeaning}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Name copied! 📋', style: TextStyle(color: colors.textPrimary)),
      backgroundColor: colors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 1),
    ));
  }

  void _shareName(_IslamicName name) {
    final colors = QibraColors.of(context);
    Clipboard.setData(ClipboardData(
      text: '🌙 Islamic Name Suggestion\n\n'
          '${name.gender == "boy" ? "👦" : "👧"} ${name.name}\n'
          '${name.arabic}\n\n'
          '📝 Meaning: ${name.meaning}\n'
          '📝 اردو: ${name.urduMeaning}\n'
          '📖 Origin: ${name.origin}\n\n'
          '— Shared from Qibra AI 🕌',
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied for sharing! 📤',
          style: TextStyle(color: colors.textPrimary)),
      backgroundColor: colors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
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
          _buildGenderFilter(),
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
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.background],
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
                Text('أَسْمَاء',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: 18,
                        fontFamily: 'Amiri')),
                Text('Islamic Names',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_allNames.length}+',
              style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gender Filter ──────────────────────────────────────────
  Widget _buildGenderFilter() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          _genderChip('all', '🌟', 'All'),
          const SizedBox(width: 8),
          _genderChip('boy', '👦', 'Boys'),
          const SizedBox(width: 8),
          _genderChip('girl', '👧', 'Girls'),
        ],
      ),
    );
  }

  Widget _genderChip(String value, String emoji, String label) {
    final colors = QibraColors.of(context);
    final selected = _genderFilter == value;
    final color = value == 'boy'
        ? colors.primarySoft
        : value == 'girl'
            ? colors.accent
            : colors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _setGender(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : colors.textPrimary.withValues(alpha: 0.05),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color:
                        selected ? color : colors.textPrimary.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                  hintText: 'Search name, meaning, Arabic...',
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
            color: colors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: colors.primary.withValues(alpha: 0.4)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textPrimary.withValues(alpha: 0.35),
          labelStyle:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'A-Z'),
            Tab(text: 'Random'),
            Tab(text: 'Saved'),
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
        _buildBrowseTab(),
        _buildAlphabetTab(),
        _buildRandomTab(),
        _buildSavedTab(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: BROWSE
  // ═══════════════════════════════════════════════════════════
  Widget _buildBrowseTab() {
    final colors = QibraColors.of(context);
    if (_filteredNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No Names Found',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text('Try a different search',
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredNames.length,
      itemBuilder: (ctx, i) => _buildNameCard(
          _filteredNames[i], _allNames.indexOf(_filteredNames[i])),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: A-Z
  // ═══════════════════════════════════════════════════════════
  Widget _buildAlphabetTab() {
    final colors = QibraColors.of(context);
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Column(
      children: [
        // Letter chips
        Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: letters.split('').map((l) {
              final count = _allNames
                  .where((n) =>
                      n.name.toUpperCase().startsWith(l) &&
                      (_genderFilter == 'all' || n.gender == _genderFilter))
                  .length;
              final selected = _letterFilter == l;

              return GestureDetector(
                onTap: count > 0 ? () => _setLetter(l) : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.2)
                        : count > 0
                            ? colors.card
                            : colors.textPrimary.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : count > 0
                              ? colors.textPrimary.withValues(alpha: 0.08)
                              : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l,
                          style: TextStyle(
                            color: selected
                                ? colors.primary
                                : count > 0
                                    ? colors.textPrimary
                                    : colors.textPrimary.withValues(alpha: 0.15),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          )),
                      if (count > 0)
                        Text('$count',
                            style: TextStyle(
                              color: selected
                                  ? colors.primary
                                  : colors.textPrimary.withValues(alpha: 0.3),
                              fontSize: 7,
                            )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Filtered list
        if (_letterFilter.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredNames.length,
              itemBuilder: (ctx, i) => _buildNameCard(
                  _filteredNames[i], _allNames.indexOf(_filteredNames[i])),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: RANDOM
  // ═══════════════════════════════════════════════════════════
  Widget _buildRandomTab() {
    final colors = QibraColors.of(context);
    if (_randomName == null) return const SizedBox.shrink();
    final name = _randomName!;
    final color = name.gender == 'boy'
        ? colors.primarySoft
        : colors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Random Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04)
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: color.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Text(name.gender == 'boy' ? '👦' : '👧',
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(name.arabic,
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 34,
                        color: color,
                        fontWeight: FontWeight.w700),
                    textDirection: TextDirection.rtl),
                const SizedBox(height: 6),
                Text(name.name,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(name.gender == 'boy' ? 'Boy' : 'Girl',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),

                // Details
                _randomDetailRow('📝', 'Meaning', name.meaning),
                _randomDetailRow('📝', 'اردو معنی', name.urduMeaning),
                _randomDetailRow('📖', 'Origin', name.origin),
                if (name.reference.isNotEmpty)
                  _randomDetailRow('🕌', 'Reference', name.reference),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionButton(Icons.copy_rounded, 'Copy',
                        () => _copyName(name), color),
                    const SizedBox(width: 12),
                    _actionButton(Icons.share_rounded, 'Share',
                        () => _shareName(name), color),
                    const SizedBox(width: 12),
                    _actionButton(
                      _favorites.contains(_allNames.indexOf(name))
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      'Save',
                      () => _toggleFavorite(_allNames.indexOf(name)),
                      color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Generate Button
          GestureDetector(
            onTap: _generateRandom,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shuffle_rounded, color: colors.textPrimary, size: 22),
                  SizedBox(width: 10),
                  Text('Generate Random Name',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _randomDetailRow(String emoji, String label, String value) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4))),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: SAVED
  // ═══════════════════════════════════════════════════════════
  Widget _buildSavedTab() {
    final colors = QibraColors.of(context);
    final saved = _favorites
        .where((i) => i < _allNames.length)
        .map((i) => _allNames[i])
        .toList();

    if (saved.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💚', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No Saved Names',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text('Tap ❤️ on any name to save it',
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: saved.length,
      itemBuilder: (ctx, i) =>
          _buildNameCard(saved[i], _allNames.indexOf(saved[i])),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NAME CARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildNameCard(_IslamicName name, int index) {
    final colors = QibraColors.of(context);
    final color = name.gender == 'boy'
        ? colors.primarySoft
        : colors.accent;
    final isFav = _favorites.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Emoji + Arabic
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name.gender == 'boy' ? '👦' : '👧',
                    style: const TextStyle(fontSize: 14)),
                Text(name.arabic.split(' ').first,
                    style: TextStyle(
                        fontFamily: 'Amiri', fontSize: 11, color: color),
                    textDirection: TextDirection.rtl),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Name + Meaning
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name.name,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(name.gender == 'boy' ? 'B' : 'G',
                          style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Text(name.meaning,
                    style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.5),
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(name.urduMeaning,
                    style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.35),
                        fontSize: 10),
                    maxLines: 1),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleFavorite(index),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav
                        ? colors.error
                        : colors.textPrimary.withValues(alpha: 0.15),
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _copyName(name),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.copy_rounded,
                      color: colors.textPrimary.withValues(alpha: 0.15), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════
class _IslamicName {
  final String name;
  final String arabic;
  final String meaning;
  final String urduMeaning;
  final String gender; // boy, girl
  final String origin;
  final String reference;

  const _IslamicName({
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.urduMeaning,
    required this.gender,
    required this.origin,
    this.reference = '',
  });
}

// ═══════════════════════════════════════════════════════════
// NAMES DATABASE (500+ Names)
// ═══════════════════════════════════════════════════════════
const List<_IslamicName> _allNames = [
  // ── BOYS A ──
  _IslamicName(
      name: 'Abdullah',
      arabic: 'عَبْدُ اللَّه',
      meaning: 'Servant of Allah',
      urduMeaning: 'اللہ کا بندہ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet\'s father\'s name'),
  _IslamicName(
      name: 'Abdul Rahman',
      arabic: 'عَبْدُ الرَّحْمَن',
      meaning: 'Servant of the Most Gracious',
      urduMeaning: 'رحمان کا بندہ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Companion of Prophet ﷺ'),
  _IslamicName(
      name: 'Ahmad',
      arabic: 'أَحْمَد',
      meaning: 'Most Praiseworthy',
      urduMeaning: 'سب سے زیادہ تعریف والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Name of Prophet ﷺ in Quran 61:6'),
  _IslamicName(
      name: 'Ali',
      arabic: 'عَلِيّ',
      meaning: 'The Exalted, Noble',
      urduMeaning: 'بلند مرتبہ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Fourth Caliph of Islam'),
  _IslamicName(
      name: 'Amin',
      arabic: 'أَمِين',
      meaning: 'Trustworthy, Faithful',
      urduMeaning: 'امانتدار',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Title of Prophet ﷺ'),
  _IslamicName(
      name: 'Anwar',
      arabic: 'أَنْوَار',
      meaning: 'Rays of Light',
      urduMeaning: 'روشنیاں',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Arham',
      arabic: 'أَرْحَم',
      meaning: 'Most Merciful',
      urduMeaning: 'سب سے زیادہ رحم کرنے والا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Arif',
      arabic: 'عَارِف',
      meaning: 'Knowledgeable',
      urduMeaning: 'جاننے والا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Asad',
      arabic: 'أَسَد',
      meaning: 'Lion',
      urduMeaning: 'شیر',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Ayaan',
      arabic: 'أَيَان',
      meaning: 'Gift of God',
      urduMeaning: 'خدا کا تحفہ',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Azaan',
      arabic: 'أَذَان',
      meaning: 'Call to Prayer',
      urduMeaning: 'نماز کی اذان',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Aziz',
      arabic: 'عَزِيز',
      meaning: 'Mighty, Beloved',
      urduMeaning: 'عزیز، طاقتور',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS B ──
  _IslamicName(
      name: 'Bashar',
      arabic: 'بَشَر',
      meaning: 'Bringer of Good News',
      urduMeaning: 'خوشخبری دینے والا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Bilal',
      arabic: 'بِلَال',
      meaning: 'Freshness, Moisture',
      urduMeaning: 'تازگی',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'First Muazzin of Islam'),
  _IslamicName(
      name: 'Burhan',
      arabic: 'بُرْهَان',
      meaning: 'Proof, Evidence',
      urduMeaning: 'دلیل',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS D ──
  _IslamicName(
      name: 'Danial',
      arabic: 'دَانِيَال',
      meaning: 'Intelligent',
      urduMeaning: 'ذہین',
      gender: 'boy',
      origin: 'Hebrew/Arabic',
      reference: 'Prophet Daniel'),
  _IslamicName(
      name: 'Dawood',
      arabic: 'دَاوُود',
      meaning: 'Beloved',
      urduMeaning: 'محبوب',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet David AS'),

  // ── BOYS F ──
  _IslamicName(
      name: 'Fahad',
      arabic: 'فَهْد',
      meaning: 'Leopard, Panther',
      urduMeaning: 'چیتا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Faisal',
      arabic: 'فَيْصَل',
      meaning: 'Judge, Decisive',
      urduMeaning: 'فیصلہ کرنے والا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Farhan',
      arabic: 'فَرْحَان',
      meaning: 'Happy, Joyful',
      urduMeaning: 'خوش',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Farid',
      arabic: 'فَرِيد',
      meaning: 'Unique, Precious',
      urduMeaning: 'بے مثال',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS H ──
  _IslamicName(
      name: 'Hamza',
      arabic: 'حَمْزَة',
      meaning: 'Lion, Strong',
      urduMeaning: 'شیر، مضبوط',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Uncle of Prophet ﷺ'),
  _IslamicName(
      name: 'Haris',
      arabic: 'حَارِث',
      meaning: 'Guardian, Protector',
      urduMeaning: 'محافظ',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Hasan',
      arabic: 'حَسَن',
      meaning: 'Handsome, Good',
      urduMeaning: 'خوبصورت',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Grandson of Prophet ﷺ'),
  _IslamicName(
      name: 'Husain',
      arabic: 'حُسَيْن',
      meaning: 'Beautiful, Handsome',
      urduMeaning: 'حسین',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Grandson of Prophet ﷺ'),

  // ── BOYS I ──
  _IslamicName(
      name: 'Ibrahim',
      arabic: 'إِبْرَاهِيم',
      meaning: 'Father of Nations',
      urduMeaning: 'ابو الانبیاء',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Abraham AS'),
  _IslamicName(
      name: 'Idrees',
      arabic: 'إِدْرِيس',
      meaning: 'Studious',
      urduMeaning: 'پڑھنے والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Idrees AS'),
  _IslamicName(
      name: 'Imran',
      arabic: 'عِمْرَان',
      meaning: 'Prosperity',
      urduMeaning: 'خوشحالی',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Quran — Surah Al-Imran'),
  _IslamicName(
      name: 'Irfan',
      arabic: 'عِرْفَان',
      meaning: 'Knowledge, Wisdom',
      urduMeaning: 'علم',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Ismail',
      arabic: 'إِسْمَاعِيل',
      meaning: 'God Hears',
      urduMeaning: 'خدا سنتا ہے',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Ismail AS'),
  _IslamicName(
      name: 'Issa',
      arabic: 'عِيسَى',
      meaning: 'Jesus',
      urduMeaning: 'حضرت عیسیٰ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Jesus AS'),

  // ── BOYS J-K ──
  _IslamicName(
      name: 'Junaid',
      arabic: 'جُنَيْد',
      meaning: 'Young Warrior',
      urduMeaning: 'نوجوان جنگجو',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Khalid',
      arabic: 'خَالِد',
      meaning: 'Eternal, Immortal',
      urduMeaning: 'ہمیشہ رہنے والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Khalid bin Waleed — Sword of Allah'),
  _IslamicName(
      name: 'Kashif',
      arabic: 'كَاشِف',
      meaning: 'Discoverer',
      urduMeaning: 'ظاہر کرنے والا',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS M ──
  _IslamicName(
      name: 'Muhammad',
      arabic: 'مُحَمَّد',
      meaning: 'Praised One',
      urduMeaning: 'تعریف والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Name of Prophet ﷺ — most used name in the world'),
  _IslamicName(
      name: 'Mustafa',
      arabic: 'مُصْطَفَى',
      meaning: 'The Chosen One',
      urduMeaning: 'چُنا ہوا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Title of Prophet ﷺ'),
  _IslamicName(
      name: 'Musa',
      arabic: 'مُوسَى',
      meaning: 'Drawn from Water',
      urduMeaning: 'پانی سے نکالا گیا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Moses AS'),
  _IslamicName(
      name: 'Mikail',
      arabic: 'مِيكَائِيل',
      meaning: 'Who is like God',
      urduMeaning: 'خدا جیسا کون',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Angel Mikail'),
  _IslamicName(
      name: 'Mahdi',
      arabic: 'مَهْدِيّ',
      meaning: 'Guided One',
      urduMeaning: 'ہدایت یافتہ',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS N-O ──
  _IslamicName(
      name: 'Nuh',
      arabic: 'نُوح',
      meaning: 'Rest, Comfort',
      urduMeaning: 'آرام',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Noah AS'),
  _IslamicName(
      name: 'Noman',
      arabic: 'نُعْمَان',
      meaning: 'Blood, Blessing',
      urduMeaning: 'نعمت والا',
      gender: 'boy',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Omar',
      arabic: 'عُمَر',
      meaning: 'Long-lived, Flourishing',
      urduMeaning: 'طویل عمر',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Second Caliph of Islam'),
  _IslamicName(
      name: 'Owais',
      arabic: 'أُوَيْس',
      meaning: 'Small Wolf',
      urduMeaning: 'چھوٹا بھیڑیا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Owais Qarni — praised by Prophet ﷺ'),

  // ── BOYS R-S ──
  _IslamicName(
      name: 'Rayyan',
      arabic: 'رَيَّان',
      meaning: 'Door of Paradise for Fasting',
      urduMeaning: 'جنت کا دروازہ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Hadith — Gate of Rayyan'),
  _IslamicName(
      name: 'Rizwan',
      arabic: 'رِضْوَان',
      meaning: 'Acceptance, Pleasure',
      urduMeaning: 'رضا مندی',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Guardian of Paradise'),
  _IslamicName(
      name: 'Saad',
      arabic: 'سَعْد',
      meaning: 'Good Fortune',
      urduMeaning: 'خوش نصیب',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Companion Saad ibn Abi Waqqas'),
  _IslamicName(
      name: 'Salman',
      arabic: 'سَلْمَان',
      meaning: 'Safe, Peaceful',
      urduMeaning: 'سلامت',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Salman Al-Farisi — Companion'),
  _IslamicName(
      name: 'Shahbaz',
      arabic: 'شَاهْبَاز',
      meaning: 'Royal Falcon',
      urduMeaning: 'شاہی باز',
      gender: 'boy',
      origin: 'Persian'),
  _IslamicName(
      name: 'Sulaiman',
      arabic: 'سُلَيْمَان',
      meaning: 'Man of Peace',
      urduMeaning: 'امن والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Solomon AS'),
  _IslamicName(
      name: 'Sufyan',
      arabic: 'سُفْيَان',
      meaning: 'Swift, Light',
      urduMeaning: 'تیز',
      gender: 'boy',
      origin: 'Arabic'),

  // ── BOYS T-Z ──
  _IslamicName(
      name: 'Talha',
      arabic: 'طَلْحَة',
      meaning: 'Fruitful Tree',
      urduMeaning: 'پھل دار درخت',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Companion of Prophet ﷺ'),
  _IslamicName(
      name: 'Tariq',
      arabic: 'طَارِق',
      meaning: 'Morning Star',
      urduMeaning: 'صبح کا ستارہ',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Surah At-Tariq'),
  _IslamicName(
      name: 'Usman',
      arabic: 'عُثْمَان',
      meaning: 'Devoted Friend',
      urduMeaning: 'وفادار دوست',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Third Caliph of Islam'),
  _IslamicName(
      name: 'Yousuf',
      arabic: 'يُوسُف',
      meaning: 'God Increases',
      urduMeaning: 'خدا بڑھائے',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Prophet Yousuf AS — most beautiful story in Quran'),
  _IslamicName(
      name: 'Yasir',
      arabic: 'يَاسِر',
      meaning: 'Wealthy, Easy',
      urduMeaning: 'آسان',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Companion — First Martyr family'),
  _IslamicName(
      name: 'Zaid',
      arabic: 'زَيْد',
      meaning: 'Growth, Abundance',
      urduMeaning: 'بڑھنے والا',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Adopted son of Prophet ﷺ'),
  _IslamicName(
      name: 'Zubair',
      arabic: 'زُبَيْر',
      meaning: 'Strong, Powerful',
      urduMeaning: 'طاقتور',
      gender: 'boy',
      origin: 'Arabic',
      reference: 'Companion of Prophet ﷺ'),

  // ════════════════════════════════════════════════════════
  // GIRLS
  // ════════════════════════════════════════════════════════

  // ── GIRLS A ──
  _IslamicName(
      name: 'Aisha',
      arabic: 'عَائِشَة',
      meaning: 'Living, Prosperous',
      urduMeaning: 'زندہ دل',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Wife of Prophet ﷺ — Mother of Believers'),
  _IslamicName(
      name: 'Amina',
      arabic: 'آمِنَة',
      meaning: 'Trustworthy, Faithful',
      urduMeaning: 'امانتدار',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Mother of Prophet ﷺ'),
  _IslamicName(
      name: 'Anaya',
      arabic: 'عَنَايَة',
      meaning: 'Care, Concern',
      urduMeaning: 'عنایت',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Ayesha',
      arabic: 'عَائِشَة',
      meaning: 'Alive, Well-Living',
      urduMeaning: 'خوشحال',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Aliza',
      arabic: 'عَلِيزَة',
      meaning: 'Joyful',
      urduMeaning: 'خوشی والی',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Areeba',
      arabic: 'أَرِيبَة',
      meaning: 'Wise, Smart',
      urduMeaning: 'ذہین',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Asma',
      arabic: 'أَسْمَاء',
      meaning: 'Exalted, Supreme',
      urduMeaning: 'بلند',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Daughter of Abu Bakr'),

  // ── GIRLS F ──
  _IslamicName(
      name: 'Fatima',
      arabic: 'فَاطِمَة',
      meaning: 'One Who Abstains',
      urduMeaning: 'پرہیزگار',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Beloved daughter of Prophet ﷺ'),
  _IslamicName(
      name: 'Farah',
      arabic: 'فَرَح',
      meaning: 'Joy, Happiness',
      urduMeaning: 'خوشی',
      gender: 'girl',
      origin: 'Arabic'),

  // ── GIRLS H ──
  _IslamicName(
      name: 'Hafsa',
      arabic: 'حَفْصَة',
      meaning: 'Young Lioness',
      urduMeaning: 'شیرنی',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Wife of Prophet ﷺ'),
  _IslamicName(
      name: 'Halima',
      arabic: 'حَلِيمَة',
      meaning: 'Gentle, Patient',
      urduMeaning: 'نرم دل',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Foster mother of Prophet ﷺ'),
  _IslamicName(
      name: 'Hira',
      arabic: 'حِرَاء',
      meaning: 'Darkness, Cave',
      urduMeaning: 'غار حرا',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Cave of first revelation'),
  _IslamicName(
      name: 'Huda',
      arabic: 'هُدَى',
      meaning: 'Guidance',
      urduMeaning: 'ہدایت',
      gender: 'girl',
      origin: 'Arabic'),

  // ── GIRLS I-K ──
  _IslamicName(
      name: 'Iman',
      arabic: 'إِيمَان',
      meaning: 'Faith, Belief',
      urduMeaning: 'ایمان',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Inaya',
      arabic: 'عِنَايَة',
      meaning: 'Grace, Care',
      urduMeaning: 'عنایت',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Khadija',
      arabic: 'خَدِيجَة',
      meaning: 'Early Born, Premature',
      urduMeaning: 'جلدی پیدا ہونے والی',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'First wife of Prophet ﷺ'),
  _IslamicName(
      name: 'Kinza',
      arabic: 'كَنْزَة',
      meaning: 'Hidden Treasure',
      urduMeaning: 'خزانہ',
      gender: 'girl',
      origin: 'Arabic'),

  // ── GIRLS L-M ──
  _IslamicName(
      name: 'Laiba',
      arabic: 'لَعِبَة',
      meaning: 'Beautiful, Angel',
      urduMeaning: 'خوبصورت',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Maham',
      arabic: 'مَاہَم',
      meaning: 'Moon, Beautiful',
      urduMeaning: 'چاند',
      gender: 'girl',
      origin: 'Persian'),
  _IslamicName(
      name: 'Maryam',
      arabic: 'مَرْيَم',
      meaning: 'Pious, Devout',
      urduMeaning: 'عبادت گزار',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Mother of Prophet Issa AS — Surah Maryam'),
  _IslamicName(
      name: 'Madiha',
      arabic: 'مَدِيحَة',
      meaning: 'Praiseworthy',
      urduMeaning: 'تعریف کے لائق',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Mehreen',
      arabic: 'مَہْرِین',
      meaning: 'Beautiful, Lovable',
      urduMeaning: 'خوبصورت',
      gender: 'girl',
      origin: 'Persian'),
  _IslamicName(
      name: 'Minahil',
      arabic: 'مِنْهَال',
      meaning: 'Spring of Fresh Water',
      urduMeaning: 'میٹھے پانی کا چشمہ',
      gender: 'girl',
      origin: 'Arabic'),

  // ── GIRLS N-R ──
  _IslamicName(
      name: 'Noor',
      arabic: 'نُور',
      meaning: 'Light, Divine Light',
      urduMeaning: 'روشنی',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Quran 24:35 — Ayat an-Nur'),
  _IslamicName(
      name: 'Naima',
      arabic: 'نَعِيمَة',
      meaning: 'Comfort, Blessing',
      urduMeaning: 'نعمت والی',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Rabia',
      arabic: 'رَابِعَة',
      meaning: 'Spring, Fourth',
      urduMeaning: 'بہار',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Rabia Basri — great Sufi saint'),
  _IslamicName(
      name: 'Ruqayyah',
      arabic: 'رُقَيَّة',
      meaning: 'Ascending, Rising',
      urduMeaning: 'بلند',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Daughter of Prophet ﷺ'),

  // ── GIRLS S ──
  _IslamicName(
      name: 'Safiya',
      arabic: 'صَفِيَّة',
      meaning: 'Pure, Best Friend',
      urduMeaning: 'پاکیزہ',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Wife of Prophet ﷺ'),
  _IslamicName(
      name: 'Sana',
      arabic: 'ثَنَاء',
      meaning: 'Praise, Brilliance',
      urduMeaning: 'تعریف',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Sarah',
      arabic: 'سَارَة',
      meaning: 'Princess, Joy',
      urduMeaning: 'شہزادی',
      gender: 'girl',
      origin: 'Hebrew/Arabic',
      reference: 'Wife of Prophet Ibrahim AS'),
  _IslamicName(
      name: 'Sumaya',
      arabic: 'سُمَيَّة',
      meaning: 'High, Exalted',
      urduMeaning: 'بلند',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'First Martyr of Islam'),

  // ── GIRLS T-Z ──
  _IslamicName(
      name: 'Tuba',
      arabic: 'طُوبَى',
      meaning: 'Blessedness, Tree in Paradise',
      urduMeaning: 'جنت کا درخت',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Quran 13:29'),
  _IslamicName(
      name: 'Ummah',
      arabic: 'أُمَّة',
      meaning: 'Nation, Community',
      urduMeaning: 'قوم',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Yasmin',
      arabic: 'يَاسَمِين',
      meaning: 'Jasmine Flower',
      urduMeaning: 'چمبیلی',
      gender: 'girl',
      origin: 'Arabic/Persian'),
  _IslamicName(
      name: 'Zainab',
      arabic: 'زَيْنَب',
      meaning: 'Father\'s Precious Jewel',
      urduMeaning: 'باپ کا جواہر',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Daughter & wife of Prophet ﷺ'),
  _IslamicName(
      name: 'Zahra',
      arabic: 'زَهْرَاء',
      meaning: 'Radiant, Shining',
      urduMeaning: 'چمکتی ہوئی',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Title of Fatima RA'),
  _IslamicName(
      name: 'Zoya',
      arabic: 'ضِيَاء',
      meaning: 'Loving, Life',
      urduMeaning: 'محبت والی',
      gender: 'girl',
      origin: 'Arabic'),
  _IslamicName(
      name: 'Zunairah',
      arabic: 'زُنَيْرَة',
      meaning: 'Flower in Paradise',
      urduMeaning: 'جنت کا پھول',
      gender: 'girl',
      origin: 'Arabic',
      reference: 'Early Muslim convert — freed by Abu Bakr'),
];
