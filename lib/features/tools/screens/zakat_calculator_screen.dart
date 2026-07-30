import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // NEW — Nisab variables
  bool _zakatDue = false;
  String _nisabMessage = '';
  double _nisabThreshold = 0;

  static const double _zakatRate = 0.025;
  static const double _goldNisabGrams = 87.48;
  static const double _silverNisabGrams = 612.36;

  final Map<String, String> _currencySymbols = {
    'PKR': '₨',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'INR': '₹',
  };

  final Map<String, double> _silverPricePerGram = {
    'PKR': 110.0,
    'USD': 0.40,
    'GBP': 0.32,
    'EUR': 0.37,
    'SAR': 1.50,
    'AED': 1.47,
    'INR': 33.0,
  };

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

    final total = gold + silver + cash + investment + property - debt;

    // Nisab — Silver standard (majority opinion)
    final double silverPrice = _silverPricePerGram[_currency] ?? 110.0;
    final double nisabThreshold = _silverNisabGrams * silverPrice;

    setState(() {
      _totalWealth = total;
      _nisabThreshold = nisabThreshold;

      if (_totalWealth <= 0) {
        _zakatAmount = 0;
        _zakatDue = false;
        _nisabMessage = 'Please enter your wealth details.';
      } else if (_totalWealth < nisabThreshold) {
        _zakatAmount = 0;
        _zakatDue = false;
        _nisabMessage = 'Your wealth is below Nisab threshold '
            '(${_formatAmount(nisabThreshold)}). '
            'Zakat is not obligatory.';
      } else {
        _zakatAmount = _totalWealth * _zakatRate;
        _zakatDue = true;
        _nisabMessage = 'Your wealth exceeds Nisab '
            '(${_formatAmount(nisabThreshold)}). '
            'Zakat is obligatory.';
      }

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
      _nisabThreshold = 0;
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
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
                _buildSectionLabel('💰', 'ASSETS'),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.diamond_rounded,
                  label: 'Gold Value',
                  hint: 'Value of gold you own',
                  controller: _goldController,
                  color: const Color(0xFFFFD700),
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.blur_circular_rounded,
                  label: 'Silver Value',
                  hint: 'Value of silver you own',
                  controller: _silverController,
                  color: const Color(0xFFC0C0C0),
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Cash & Bank Balance',
                  hint: 'Cash in hand + bank accounts',
                  controller: _cashController,
                  color: const Color(0xFF52B788),
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Investments & Stocks',
                  hint: 'Stocks, mutual funds, crypto',
                  controller: _investmentController,
                  color: const Color(0xFF74C0FC),
                ),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.home_rounded,
                  label: 'Business / Rental Property',
                  hint: 'Business goods, rental income',
                  controller: _propertyController,
                  color: const Color(0xFFA78BFA),
                ),
                const SizedBox(height: 20),
                _buildSectionLabel('📋', 'LIABILITIES'),
                const SizedBox(height: 12),
                _buildInputCard(
                  icon: Icons.money_off_rounded,
                  label: 'Debts & Loans',
                  hint: 'Outstanding debts to deduct',
                  controller: _debtController,
                  color: const Color(0xFFEF4444),
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

  // ─── App Bar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E1A),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4332), Color(0xFF0A0E1A)],
            ),
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
                      color: const Color(0xFF52B788).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF52B788).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💚', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Zakat Calculator',
                          style: TextStyle(
                            color: Color(0xFF52B788),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'زَكَاة',
                    style: TextStyle(
                      color: Color(0xFF52B788),
                      fontSize: 24,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const Text(
                    'Calculate Your Zakat',
                    style: TextStyle(
                      color: Colors.white,
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

  // ─── Nisab Info ─────────────────────────────────────────────
  Widget _buildNisabInfoCard() {
    final double silverPrice = _silverPricePerGram[_currency] ?? 110.0;
    final double nisab = _silverNisabGrams * silverPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF52B788).withValues(alpha: 0.3),
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
                  color: const Color(0xFF52B788).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF52B788),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Nisab Threshold',
                style: TextStyle(
                  color: Color(0xFF52B788),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _nisabRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Nisab Status Card ──────────────────────────────────────
  Widget _buildNisabStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _zakatDue
            ? const Color(0xFF52B788).withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _zakatDue
              ? const Color(0xFF52B788).withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _zakatDue ? Icons.check_circle_outline : Icons.info_outline,
            color: _zakatDue ? const Color(0xFF52B788) : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _nisabMessage,
              style: TextStyle(
                color: _zakatDue ? const Color(0xFF52B788) : Colors.orange,
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

  // ─── Currency Selector ──────────────────────────────────────
  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      selected ? const Color(0xFF52B788) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
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

  // ─── Section Label ──────────────────────────────────────────
  Widget _buildSectionLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  // ─── Input Card ─────────────────────────────────────────────
  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 12,
                    ),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle: TextStyle(
                      color: color.withValues(alpha: 0.6),
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

  // ─── Calculate Button ───────────────────────────────────────
  Widget _buildCalculateButton() {
    return GestureDetector(
      onTap: _calculateZakat,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF52B788).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Calculate Zakat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ────────────────────────────────────────────
  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF52B788).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52B788).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Zakat Amount',
            style: TextStyle(
              color: Color(0xFF52B788),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'زَكَاتُكَ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: Color(0xFF52B788),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(_zakatAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '2.5% of ${_formatAmount(_totalWealth)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Breakdown Card ─────────────────────────────────────────
  Widget _buildBreakdownCard() {
    final gold = double.tryParse(_goldController.text) ?? 0;
    final silver = double.tryParse(_silverController.text) ?? 0;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final investment = double.tryParse(_investmentController.text) ?? 0;
    final property = double.tryParse(_propertyController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF52B788), size: 18),
              const SizedBox(width: 8),
              Text(
                'BREAKDOWN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (gold > 0) _breakdownRow('Gold', gold, const Color(0xFFFFD700)),
          if (silver > 0)
            _breakdownRow('Silver', silver, const Color(0xFFC0C0C0)),
          if (cash > 0)
            _breakdownRow('Cash & Bank', cash, const Color(0xFF52B788)),
          if (investment > 0)
            _breakdownRow('Investments', investment, const Color(0xFF74C0FC)),
          if (property > 0)
            _breakdownRow('Property', property, const Color(0xFFA78BFA)),
          if (debt > 0)
            _breakdownRow('Debts (−)', debt, const Color(0xFFEF4444)),
          const Divider(color: Color(0xFF2A2F3E), height: 24),
          _breakdownRow('Total Wealth', _totalWealth, const Color(0xFF52B788)),
          _breakdownRow('Zakat (2.5%)', _zakatAmount, Colors.white),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double amount, Color color) {
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
                  color: Colors.white.withValues(alpha: 0.7),
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

  // ─── Reset Button ───────────────────────────────────────────
  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _resetAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Reset All',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Islamic Note ───────────────────────────────────────────
  Widget _buildIslamicNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text(
                'Islamic Reminder',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"Take from their wealth a charity to purify them and increase them thereby." — Quran 9:103',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
