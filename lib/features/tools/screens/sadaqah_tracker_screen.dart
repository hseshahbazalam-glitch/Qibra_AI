import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SadaqahTrackerScreen extends StatefulWidget {
  const SadaqahTrackerScreen({super.key});

  @override
  State<SadaqahTrackerScreen> createState() => _SadaqahTrackerScreenState();
}

class _SadaqahTrackerScreenState extends State<SadaqahTrackerScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _currency = 'PKR';
  String _selectedCategory = 'General';
  List<_SadaqahEntry> _entries = [];
  double _totalAmount = 0;

  static const String _storageKey = 'sadaqah_entries';

  final Map<String, String> _currencySymbols = {
    'PKR': '₨',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'SAR': 'ر.س',
    'INR': '₹',
  };

  final List<_SadaqahCategory> _categories = [
    _SadaqahCategory(
        'General', Icons.volunteer_activism_rounded, QibraColors.light.primary),
    _SadaqahCategory('Food', Icons.restaurant_rounded, QibraColors.light.accent),
    _SadaqahCategory('Education', Icons.school_rounded, QibraColors.light.primarySoft),
    _SadaqahCategory(
        'Medical', Icons.medical_services_rounded, QibraColors.light.error),
    _SadaqahCategory('Orphan', Icons.child_care_rounded, QibraColors.light.primarySoft),
    _SadaqahCategory('Masjid', Icons.mosque_rounded, QibraColors.light.primarySoft),
    _SadaqahCategory('Water', Icons.water_drop_rounded, QibraColors.light.primarySoft),
    _SadaqahCategory('Clothes', Icons.checkroom_rounded, QibraColors.light.accent),
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      setState(() {
        _entries = list
            .map((e) => _SadaqahEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalAmount = _entries.fold(0, (sum, e) => sum + e.amount);
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  void _addEntry() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackbar('Please enter a valid amount');
      return;
    }

    HapticFeedback.mediumImpact();
    final entry = _SadaqahEntry(
      amount: amount,
      category: _selectedCategory,
      note: _noteController.text.trim(),
      currency: _currency,
      date: DateTime.now(),
    );

    setState(() {
      _entries.insert(0, entry);
      _totalAmount += amount;
    });
    _saveEntries();

    _amountController.clear();
    _noteController.clear();
    Navigator.pop(context);
    _showSnackbar('Sadaqah logged! May Allah accept it 🤲');
  }

  void _deleteEntry(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _totalAmount -= _entries[index].amount;
      _entries.removeAt(index);
    });
    _saveEntries();
  }

  void _showSnackbar(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatAmount(double amount) {
    final symbol = _currencySymbols[_currency] ?? _currency;
    if (amount >= 10000000) {
      return '$symbol ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '$symbol ${(amount / 100000).toStringAsFixed(2)} Lac';
    }
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  _SadaqahCategory _getCategoryData(String name) {
    return _categories.firstWhere(
      (c) => c.name == name,
      orElse: () => _categories.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(),
        backgroundColor: colors.primarySoft,
        icon: Icon(Icons.add_rounded, color: colors.textPrimary),
        label: Text('Log Sadaqah',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTotalCard(),
                const SizedBox(height: 20),
                _buildCategoryStats(),
                const SizedBox(height: 24),
                _buildHistoryHeader(),
                const SizedBox(height: 12),
                if (_entries.isEmpty) _buildEmptyState(),
                ..._entries.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildEntryCard(e.value, e.key),
                      ),
                    ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded,
              color: colors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.backgroundSecondary, colors.background],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صَدَقَة',
                    style: TextStyle(
                      color: colors.primarySoft,
                      fontSize: 22,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    'Sadaqah Tracker',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Total Card ─────────────────────────────────────────────
  Widget _buildTotalCard() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.backgroundSecondary, colors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: colors.primarySoft.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.primarySoft.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Sadaqah Given',
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جَزَاكَ اللَّهُ خَيْرًا',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: colors.primarySoft,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(_totalAmount),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primarySoft.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_entries.length} donations recorded',
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Stats ─────────────────────────────────────────
  Widget _buildCategoryStats() {
    final colors = QibraColors.of(context);
    final Map<String, double> catTotals = {};
    for (final e in _entries) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    if (catTotals.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: catTotals.entries.map((entry) {
          final cat = _getCategoryData(entry.key);
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cat.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, color: cat.color, size: 18),
                const SizedBox(height: 6),
                Text(
                  _formatAmount(entry.value),
                  style: TextStyle(
                    color: cat.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  cat.name,
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── History Header ─────────────────────────────────────────
  Widget _buildHistoryHeader() {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        const Text('📋', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          'HISTORY',
          style: TextStyle(
            color: colors.textPrimary.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        if (_entries.isNotEmpty)
          Text(
            '${_entries.length} entries',
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────
  Widget _buildEmptyState() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Text('💰', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No Sadaqah Yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the button below to log\nyour first charity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Entry Card ─────────────────────────────────────────────
  Widget _buildEntryCard(_SadaqahEntry entry, int index) {
    final colors = QibraColors.of(context);
    final cat = _getCategoryData(entry.category);
    return Dismissible(
      key: Key('${entry.date.millisecondsSinceEpoch}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteEntry(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_rounded,
            color: colors.error, size: 22),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cat.color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.category,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.note.isNotEmpty)
                    Text(
                      entry.note,
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _timeAgo(entry.date),
                    style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.25),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatAmount(entry.amount),
              style: TextStyle(
                color: cat.color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Bottom Sheet ───────────────────────────────────────
  void _showAddSheet() {
    final colors = QibraColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Log Sadaqah',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"Charity does not decrease wealth" — Prophet ﷺ',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),

                // Currency
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _currencySymbols.keys.map((c) {
                      final sel = c == _currency;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => _currency = c);
                          setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? colors.primarySoft
                                : colors.textPrimary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: sel
                                  ? colors.textPrimary
                                  : colors.textPrimary.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: colors.primarySoft,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.15),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle: TextStyle(
                      color: colors.primarySoft.withValues(alpha: 0.5),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),

                // Categories
                Text(
                  'CATEGORY',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final sel = cat.name == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => _selectedCategory = cat.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? cat.color.withValues(alpha: 0.2)
                              : colors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? cat.color
                                : colors.textPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                color: sel
                                    ? cat.color
                                    : colors.textPrimary.withValues(alpha: 0.4),
                                size: 14),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: sel
                                    ? cat.color
                                    : colors.textPrimary.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Note
                TextField(
                  controller: _noteController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.2),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: colors.textPrimary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                GestureDetector(
                  onTap: _addEntry,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primarySoft, QibraColors.light.primarySoft],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primarySoft.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: colors.textPrimary, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Log Sadaqah',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────
class _SadaqahEntry {
  final double amount;
  final String category;
  final String note;
  final String currency;
  final DateTime date;

  _SadaqahEntry({
    required this.amount,
    required this.category,
    required this.note,
    required this.currency,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'category': category,
        'note': note,
        'currency': currency,
        'date': date.toIso8601String(),
      };

  factory _SadaqahEntry.fromJson(Map<String, dynamic> json) => _SadaqahEntry(
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String,
        currency: json['currency'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class _SadaqahCategory {
  final String name;
  final IconData icon;
  final Color color;
  const _SadaqahCategory(this.name, this.icon, this.color);
}
