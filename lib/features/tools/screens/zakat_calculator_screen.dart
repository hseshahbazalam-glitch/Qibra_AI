// lib/features/tools/screens/zakat_calculator_screen.dart

// ============================================================
// QIBRA AI — ZAKAT CALCULATOR SCREEN
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/a11y/app_a11y.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../logic/zakat_calculator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _cashController = TextEditingController();
  final _investmentController = TextEditingController();
  final _propertyController = TextEditingController();
  final _debtController = TextEditingController();

  String _currency = 'PKR';
  double _totalWealth = 0;
  double _zakatAmount = 0;
  bool _showResult = false;

  bool _zakatDue = false;
  String _nisabMessage = '';

  // Delegates to ZakatCalculator (pure, unit-tested) — aliases kept for
  // the nisab info rows' display strings.
  static const double _goldNisabGrams = ZakatCalculator.goldNisabGrams;
  static const double _silverNisabGrams = ZakatCalculator.silverNisabGrams;

  // P0.3 FIX: Explicit source & editable pricing
  // Default silver price — MUST be shown with source/lastUpdated
  // Source: Average Pakistan silver market ~280 PKR/g (Aug 2026 estimate)
  // If live pricing unavailable, user can override via SharedPreferences
  static const String _silverPriceSource = 'Pakistan silver market estimate';
  static const String _silverPriceLastUpdated = '2026-08-10';
  // Keep original stale map for migration, but override PKR with realistic
  final Map<String, double> _silverPricePerGram = {
    'PKR': 280.0, // P0.3: was 110 (understates nisab by 2.5x) — now realistic
    'USD': 0.95, // updated to ~2026 avg
    'GBP': 0.75,
    'EUR': 0.87,
    'SAR': 3.55,
    'AED': 3.48,
    'INR': 78.0,
  };

  // User-overridable custom price key (SharedPrefs)
  static const String _customPriceKeyPrefix = 'zakat_silver_price_';

  final Map<String, String> _currencySymbols = {
    'PKR': '₨',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'INR': '₹',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomPrices();
  }

  Future<void> _loadCustomPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool updated = false;
      for (final c in _silverPricePerGram.keys.toList()) {
        final custom = prefs.getDouble('$_customPriceKeyPrefix$c');
        if (custom != null && custom > 0) {
          _silverPricePerGram[c] = custom;
          updated = true;
        }
      }
      if (updated && mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveCustomPrice(String currency, double price) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('$_customPriceKeyPrefix$currency', price);
    } catch (_) {}
  }

  @override
  void dispose() {
    _goldController.dispose();
    _silverController.dispose();
    _cashController.dispose();
    _investmentController.dispose();
    _propertyController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    HapticFeedback.mediumImpact();
    final gold = double.tryParse(_goldController.text) ?? 0;
    final silver = double.tryParse(_silverController.text) ?? 0;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final investment = double.tryParse(_investmentController.text) ?? 0;
    final property = double.tryParse(_propertyController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;

    final double silverPrice = _silverPricePerGram[_currency] ?? 280.0;
    final outcome = ZakatCalculator.evaluate(
      gold: gold,
      silver: silver,
      cash: cash,
      investments: investment,
      property: property,
      debts: debt,
      silverPricePerGram: silverPrice,
    );

    setState(() {
      _totalWealth = outcome.totalWealth;
      _zakatAmount = outcome.zakatAmount;
      _zakatDue = outcome.isDue;
      _nisabMessage = switch (outcome.kind) {
        ZakatOutcomeKind.emptyInput => 'Please enter your wealth details.',
        ZakatOutcomeKind.belowNisab => 'Your wealth is below Nisab threshold '
            '(${_formatAmount(outcome.nisabThreshold)}). '
            'Zakat is not obligatory.',
        ZakatOutcomeKind.due => 'Your wealth exceeds Nisab '
            '(${_formatAmount(outcome.nisabThreshold)}). '
            'Zakat is obligatory.',
      };
      _showResult = true;
    });
  }

  void _resetAll() {
    HapticFeedback.lightImpact();
    _goldController.clear();
    _silverController.clear();
    _cashController.clear();
    _investmentController.clear();
    _propertyController.clear();
    _debtController.clear();
    setState(() {
      _totalWealth = 0;
      _zakatAmount = 0;
      _zakatDue = false;
      _nisabMessage = '';
      _showResult = false;
    });
  }

  String _formatAmount(double amount) {
    final symbol = _currencySymbols[_currency] ?? _currency;
    if (amount >= 10000000) {
      return '$symbol ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '$symbol ${(amount / 100000).toStringAsFixed(2)} Lac';
    } else {
      return '$symbol ${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildNisabInfoCard(),
                const SizedBox(height: 20),
                _buildCurrencySelector(),
                const SizedBox(height: 20),
                _buildSectionLabel(Icons.savings_rounded, 'ASSETS'),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.diamond_rounded,
                  label: 'Gold Value',
                  hint: 'Value of gold you own',
                  controller: _goldController,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.blur_circular_rounded,
                  label: 'Silver Value',
                  hint: 'Value of silver you own',
                  controller: _silverController,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Cash & Bank Balance',
                  hint: 'Cash in hand + bank accounts',
                  controller: _cashController,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Investments & Stocks',
                  hint: 'Stocks, mutual funds, crypto',
                  controller: _investmentController,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.home_rounded,
                  label: 'Business / Rental Property',
                  hint: 'Business goods, rental income',
                  controller: _propertyController,
                  color: colors.primary,
                ),
                const SizedBox(height: 20),
                _buildSectionLabel(Icons.receipt_long_rounded, 'LIABILITIES'),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.money_off_rounded,
                  label: 'Debts & Loans',
                  hint: 'Outstanding debts to deduct',
                  controller: _debtController,
                  color: colors.error,
                ),
                const SizedBox(height: 28),
                _buildCalculateButton(),
                const SizedBox(height: 16),
                if (_showResult) _buildNisabStatusCard(),
                if (_showResult) const SizedBox(height: 16),
                if (_showResult && _zakatDue) _buildResultCard(),
                if (_showResult && _zakatDue) const SizedBox(height: 16),
                if (_showResult && _zakatDue) _buildBreakdownCard(),
                if (_showResult) const SizedBox(height: 16),
                if (_showResult) _buildResetButton(),
                const SizedBox(height: 20),
                _buildIslamicNote(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        constraints: const BoxConstraints(
          minWidth: AppA11y.minTapTarget,
          minHeight: AppA11y.minTapTarget,
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.textTertiary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 14, color: colors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Zakat Calculator',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'زَكَاة',
                    style: AppArabicStyles.quranMedium.copyWith(
                      color: colors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'Calculate Your Zakat',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
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

  // ─── Nisab Info (P0.3: explicit source, editable price) ──────

  Widget _buildNisabInfoCard() {
    final colors = QibraColors.of(context);
    final double silverPrice = _silverPricePerGram[_currency] ?? 280.0;
    final double nisab = ZakatCalculator.nisabForSilverPrice(silverPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Nisab Threshold',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showEditSilverPriceDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: colors.primary, size: 12),
                      SizedBox(width: 4),
                      Text('Edit price',
                          style: TextStyle(
                              color: colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _nisabRow('Gold Nisab', '${_goldNisabGrams}g (~7.5 Tola)'),
          const SizedBox(height: 6),
          _nisabRow('Silver Nisab', '${_silverNisabGrams}g (~52.5 Tola)'),
          const SizedBox(height: 6),
          _nisabRow('Nisab in $_currency', _formatAmount(nisab)),
          const SizedBox(height: 6),
          _nisabRow('Zakat Rate', '2.5% of total wealth'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.textTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.price_change_rounded,
                        color: colors.accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Silver: ${_silverPricePerGram[_currency]?.toStringAsFixed(2)} $_currency/g',
                        style: TextStyle(
                            color: colors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: $_silverPriceSource • Updated: $_silverPriceLastUpdated',
                  style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap Edit price to use live market rate. Reproducible: Nisab = 612.36g × silver price. Rounding to 2 decimals.',
                  style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSilverPriceDialog() {
    final colors = QibraColors.of(context);
    final controller = TextEditingController(
        text: _silverPricePerGram[_currency]?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Silver Price ($_currency/g)',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Current source: $_silverPriceSource ($_silverPriceLastUpdated)',
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 280 for PKR',
                hintStyle:
                    TextStyle(color: colors.textTertiary),
                prefixText: '${_currencySymbols[_currency]} ',
                filled: true,
                fillColor: colors.cardMuted,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Text(
                'This price is saved locally and used for Nisab. Consult your local jeweller for exact rate.',
                style: TextStyle(
                    color: colors.textTertiary, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary),
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter valid price')));
                return;
              }
              setState(() => _silverPricePerGram[_currency] = v);
              _saveCustomPrice(_currency, v);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Silver price updated to ${_formatAmount(v)}/g')));
            },
            child: Text('Save',
                style: TextStyle(
                    color: colors.textPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _nisabRow(String label, String value) {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Nisab Status Card ───────────────────────────────────────

  Widget _buildNisabStatusCard() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _zakatDue
            ? colors.primary.withValues(alpha: 0.15)
            : colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _zakatDue
              ? colors.primary.withValues(alpha: 0.16)
              : colors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _zakatDue ? Icons.check_circle_outline : Icons.info_outline,
            color: _zakatDue ? colors.primary : colors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _nisabMessage,
              style: TextStyle(
                color: _zakatDue ? colors.primary : colors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Currency Selector ───────────────────────────────────────

  Widget _buildCurrencySelector() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _currencySymbols.keys.map((c) {
            final selected = c == _currency;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currency = c);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color:
                      selected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: selected
                        ? colors.onPrimary
                        : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Section Label ───────────────────────────────────────────

  Widget _buildSectionLabel(IconData icon, String label) {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  // ─── Input Card ──────────────────────────────────────────────

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color color,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                    ),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Calculate Button ────────────────────────────────────────

  Widget _buildCalculateButton() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _calculateZakat,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_rounded, color: colors.onPrimary, size: 22),
            SizedBox(width: 10),
            Text(
              'Calculate Zakat',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ─────────────────────────────────────────────

  Widget _buildResultCard() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Your Zakat Amount',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'زَكَاتُكَ',
            style: AppArabicStyles.quranSmall.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.9),
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(_zakatAmount),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '2.5% of ${_formatAmount(_totalWealth)}',
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Breakdown Card ──────────────────────────────────────────

  Widget _buildBreakdownCard() {
    final colors = QibraColors.of(context);
    final gold = double.tryParse(_goldController.text) ?? 0;
    final silver = double.tryParse(_silverController.text) ?? 0;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final investment = double.tryParse(_investmentController.text) ?? 0;
    final property = double.tryParse(_propertyController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'BREAKDOWN',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (gold > 0) _breakdownRow('Gold', gold, colors.primary),
          if (silver > 0)
            _breakdownRow('Silver', silver, colors.primary),
          if (cash > 0)
            _breakdownRow('Cash & Bank', cash, colors.primary),
          if (investment > 0)
            _breakdownRow('Investments', investment, colors.primary),
          if (property > 0)
            _breakdownRow('Property', property, colors.primary),
          if (debt > 0)
            _breakdownRow('Debts (−)', debt, colors.error),
          Divider(color: colors.border, height: 24),
          _breakdownRow('Total Wealth', _totalWealth, colors.primary),
          _breakdownRow('Zakat (2.5%)', _zakatAmount, colors.primary),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double amount, Color color) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reset Button ────────────────────────────────────────────

  Widget _buildResetButton() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _resetAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: colors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Reset All',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Islamic Note ────────────────────────────────────────────

  Widget _buildIslamicNote() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 14),
              SizedBox(width: 8),
              Text(
                'Islamic Reminder',
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
            '"Take from their wealth a charity to purify them '
            'and increase them thereby." — Quran 9:103',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Silver standard Nisab used (majority opinion). '
            'Consult a scholar for specific rulings.',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
