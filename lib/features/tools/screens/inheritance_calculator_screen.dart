import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class InheritanceCalculatorScreen extends StatefulWidget {
  const InheritanceCalculatorScreen({super.key});

  @override
  State<InheritanceCalculatorScreen> createState() =>
      _InheritanceCalculatorScreenState();
}

class _InheritanceCalculatorScreenState
    extends State<InheritanceCalculatorScreen> {
  final _estateController = TextEditingController();
  final _debtController = TextEditingController();
  final _wasiyyahController = TextEditingController();
  String _currency = 'PKR';
  String _deceasedGender = 'male';
  bool _showResult = false;

  // Family members
  bool _hasHusband = false;
  bool _hasWife = false;
  int _wifeCount = 1;
  bool _hasFather = false;
  bool _hasMother = false;
  bool _hasGrandfather = false;
  bool _hasGrandmother = false;
  int _sons = 0;
  int _daughters = 0;
  int _grandsons = 0;
  int _granddaughters = 0;
  int _brothers = 0;
  int _sisters = 0;
  int _halfBrothersFather = 0;
  int _halfSistersFather = 0;
  int _halfBrothersMother = 0;
  int _halfSistersMother = 0;
  bool _hasUncle = false;

  List<_ShareResult> _results = [];
  double _totalEstate = 0;
  double _netEstate = 0;

  final Map<String, String> _currencySymbols = {
    'PKR': '₨',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'SAR': 'ر.س',
    'INR': '₹',
  };

  @override
  void dispose() {
    _estateController.dispose();
    _debtController.dispose();
    _wasiyyahController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final symbol = _currencySymbols[_currency] ?? _currency;
    if (amount >= 10000000) {
      return '$symbol ${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) {
      return '$symbol ${(amount / 100000).toStringAsFixed(2)} Lac';
    }
    if (amount >= 1000) return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  void _calculate() {
    HapticFeedback.heavyImpact();
    final estate = double.tryParse(_estateController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;
    final wasiyyah = double.tryParse(_wasiyyahController.text) ?? 0;

    if (estate <= 0) {
      _showSnackbar('Please enter total estate value');
      return;
    }

    // Step 1: Deduct debts
    double remaining = estate - debt;
    if (remaining <= 0) {
      _showSnackbar('Debts exceed estate — no inheritance to distribute');
      return;
    }

    // Step 2: Deduct Wasiyyah (max 1/3)
    final maxWasiyyah = remaining / 3;
    final actualWasiyyah = wasiyyah > maxWasiyyah ? maxWasiyyah : wasiyyah;
    remaining -= actualWasiyyah;

    _totalEstate = estate;
    _netEstate = remaining;

    // Step 3: Calculate shares
    _results = _calculateShares(remaining);

    setState(() => _showResult = true);
  }

  List<_ShareResult> _calculateShares(double estate) {
    List<_ShareResult> shares = [];
    double distributed = 0;

    // ═══════════════════════════════════════════════════════
    // SPOUSE SHARE
    // ═══════════════════════════════════════════════════════

    // Husband
    if (_hasHusband && _deceasedGender == 'female') {
      double fraction;
      String rule;
      if (_sons > 0 ||
          _daughters > 0 ||
          _grandsons > 0 ||
          _granddaughters > 0) {
        fraction = 1 / 4;
        rule = '1/4 — because deceased has children';
      } else {
        fraction = 1 / 2;
        rule = '1/2 — because deceased has no children';
      }
      final amount = estate * fraction;
      shares.add(_ShareResult('Husband', 'زَوْج', amount, fraction, 1, rule,
          const Color(0xFF74C0FC), Icons.man_rounded));
      distributed += amount;
    }

    // Wife/Wives
    if (_hasWife && _deceasedGender == 'male') {
      double fraction;
      String rule;
      if (_sons > 0 ||
          _daughters > 0 ||
          _grandsons > 0 ||
          _granddaughters > 0) {
        fraction = 1 / 8;
        rule = '1/8 — because deceased has children';
      } else {
        fraction = 1 / 4;
        rule = '1/4 — because deceased has no children';
      }
      final totalAmount = estate * fraction;
      final perWife = totalAmount / _wifeCount;
      for (int i = 0; i < _wifeCount; i++) {
        shares.add(_ShareResult(
            'Wife ${_wifeCount > 1 ? "${i + 1}" : ""}',
            'زَوْجَة',
            perWife,
            fraction / _wifeCount,
            1,
            '$rule (shared among $_wifeCount wife${_wifeCount > 1 ? "s" : ""})',
            const Color(0xFFFF9EBC),
            Icons.woman_rounded));
      }
      distributed += totalAmount;
    }

    // ═══════════════════════════════════════════════════════
    // PARENTS SHARE
    // ═══════════════════════════════════════════════════════

    // Father
    if (_hasFather) {
      double fraction;
      String rule;
      if (_sons > 0 || _grandsons > 0) {
        fraction = 1 / 6;
        rule = '1/6 — because deceased has male offspring';
      } else if (_daughters > 0 || _granddaughters > 0) {
        fraction = 1 / 6; // Gets 1/6 + residual
        rule = '1/6 fixed share + residual (Asabah)';
      } else {
        fraction = 0; // Gets residual as Asabah
        rule = 'Residual share (Asabah)';
      }
      if (fraction > 0) {
        final amount = estate * fraction;
        shares.add(_ShareResult('Father', 'أَب', amount, fraction, 1, rule,
            const Color(0xFF52B788), Icons.man_rounded));
        distributed += amount;
      }
    }

    // Mother
    if (_hasMother) {
      double fraction;
      String rule;
      if (_sons > 0 ||
          _daughters > 0 ||
          _grandsons > 0 ||
          _granddaughters > 0) {
        fraction = 1 / 6;
        rule = '1/6 — because deceased has children';
      } else if (_brothers > 0 || _sisters > 0) {
        fraction = 1 / 6;
        rule = '1/6 — because deceased has siblings';
      } else {
        fraction = 1 / 3;
        rule = '1/3 — no children and no siblings';
      }
      final amount = estate * fraction;
      shares.add(_ShareResult('Mother', 'أُمّ', amount, fraction, 1, rule,
          const Color(0xFFA78BFA), Icons.woman_rounded));
      distributed += amount;
    }

    // Grandfather (if no father)
    if (_hasGrandfather && !_hasFather) {
      const fraction = 1 / 6;
      final amount = estate * fraction;
      shares.add(_ShareResult(
          'Grandfather',
          'جَدّ',
          amount,
          fraction,
          1,
          '1/6 — takes father\'s share',
          const Color(0xFF4ECDC4),
          Icons.elderly_rounded));
      distributed += amount;
    }

    // Grandmother (if no mother)
    if (_hasGrandmother && !_hasMother) {
      const fraction = 1 / 6;
      final amount = estate * fraction;
      shares.add(_ShareResult(
          'Grandmother',
          'جَدَّة',
          amount,
          fraction,
          1,
          '1/6 — takes mother\'s share',
          const Color(0xFFFF8C42),
          Icons.elderly_woman_rounded));
      distributed += amount;
    }

    // ═══════════════════════════════════════════════════════
    // CHILDREN SHARE (Residual / Asabah)
    // ═══════════════════════════════════════════════════════

    double residual = estate - distributed;

    if (_sons > 0 || _daughters > 0) {
      if (_sons > 0 && _daughters == 0) {
        // Only sons — equal distribution
        final perSon = residual / _sons;
        shares.add(_ShareResult(
            'Sons',
            'أَبْنَاء',
            residual,
            residual / estate,
            _sons,
            'Equal share among $_sons son${_sons > 1 ? "s" : ""} (Asabah)',
            const Color(0xFF74C0FC),
            Icons.boy_rounded));
      } else if (_sons == 0 && _daughters > 0) {
        // Only daughters
        double daughterTotal;
        String rule;
        if (_daughters == 1) {
          daughterTotal = min(residual, estate * 0.5);
          rule = '1/2 — one daughter without sons';
        } else {
          daughterTotal = min(residual, estate * (2 / 3));
          rule = '2/3 — multiple daughters without sons';
        }
        shares.add(_ShareResult(
            'Daughters',
            'بَنَات',
            daughterTotal,
            daughterTotal / estate,
            _daughters,
            rule,
            const Color(0xFFFF9EBC),
            Icons.girl_rounded));

        // Remaining residual goes to father (if alive) as Asabah
        final leftover = residual - daughterTotal;
        if (leftover > 0 && _hasFather) {
          shares.add(_ShareResult(
              'Father (Asabah)',
              'أَب',
              leftover,
              leftover / estate,
              1,
              'Residual after daughters\' share',
              const Color(0xFF52B788),
              Icons.man_rounded));
        } else if (leftover > 0 && !_hasFather) {
          // Goes to brothers or other Asabah
          if (_brothers > 0) {
            shares.add(_ShareResult(
                'Brothers (Asabah)',
                'إِخْوَة',
                leftover,
                leftover / estate,
                _brothers,
                'Residual share',
                const Color(0xFF4ECDC4),
                Icons.people_rounded));
          }
        }
      } else {
        // Sons AND Daughters — 2:1 ratio
        final totalParts = (_sons * 2) + _daughters;
        final perPart = residual / totalParts;
        final sonShare = perPart * 2;
        final daughterShare = perPart;

        shares.add(_ShareResult(
            'Sons',
            'أَبْنَاء',
            sonShare * _sons,
            (sonShare * _sons) / estate,
            _sons,
            '2:1 ratio — each son gets ${_formatAmount(sonShare)}',
            const Color(0xFF74C0FC),
            Icons.boy_rounded));
        shares.add(_ShareResult(
            'Daughters',
            'بَنَات',
            daughterShare * _daughters,
            (daughterShare * _daughters) / estate,
            _daughters,
            '2:1 ratio — each daughter gets ${_formatAmount(daughterShare)}',
            const Color(0xFFFF9EBC),
            Icons.girl_rounded));
      }
    } else if (_grandsons > 0 || _granddaughters > 0) {
      // Grandsons/Granddaughters (if no children)
      if (_grandsons > 0 && _granddaughters == 0) {
        shares.add(_ShareResult(
            'Grandsons',
            'أَحْفَاد',
            residual,
            residual / estate,
            _grandsons,
            'Equal share (Asabah)',
            const Color(0xFF74C0FC),
            Icons.boy_rounded));
      } else if (_grandsons == 0 && _granddaughters > 0) {
        double gdTotal = _granddaughters == 1 ? estate * 0.5 : estate * (2 / 3);
        gdTotal = min(residual, gdTotal);
        shares.add(_ShareResult(
            'Granddaughters',
            'حَفِيدَات',
            gdTotal,
            gdTotal / estate,
            _granddaughters,
            _granddaughters == 1 ? '1/2' : '2/3',
            const Color(0xFFFF9EBC),
            Icons.girl_rounded));
      } else {
        final totalParts = (_grandsons * 2) + _granddaughters;
        final perPart = residual / totalParts;
        shares.add(_ShareResult(
            'Grandsons',
            'أَحْفَاد',
            perPart * 2 * _grandsons,
            (perPart * 2 * _grandsons) / estate,
            _grandsons,
            '2:1 ratio',
            const Color(0xFF74C0FC),
            Icons.boy_rounded));
        shares.add(_ShareResult(
            'Granddaughters',
            'حَفِيدَات',
            perPart * _granddaughters,
            (perPart * _granddaughters) / estate,
            _granddaughters,
            '2:1 ratio',
            const Color(0xFFFF9EBC),
            Icons.girl_rounded));
      }
    } else {
      // No children, no grandchildren
      // Father gets residual (already handled above partially)
      if (_hasFather && residual > 0) {
        shares.add(_ShareResult(
            'Father (Asabah)',
            'أَب',
            residual,
            residual / estate,
            1,
            'Residual — no children',
            const Color(0xFF52B788),
            Icons.man_rounded));
      } else if (!_hasFather && residual > 0) {
        // Brothers/Sisters
        if (_brothers > 0 && _sisters == 0) {
          shares.add(_ShareResult(
              'Brothers',
              'إِخْوَة',
              residual,
              residual / estate,
              _brothers,
              'Equal share (Asabah)',
              const Color(0xFF4ECDC4),
              Icons.people_rounded));
        } else if (_brothers == 0 && _sisters > 0) {
          double sisterTotal = _sisters == 1 ? estate * 0.5 : estate * (2 / 3);
          sisterTotal = min(residual, sisterTotal);
          shares.add(_ShareResult(
              'Sisters',
              'أَخَوَات',
              sisterTotal,
              sisterTotal / estate,
              _sisters,
              _sisters == 1 ? '1/2' : '2/3',
              const Color(0xFFFF9EBC),
              Icons.people_rounded));
        } else if (_brothers > 0 && _sisters > 0) {
          final totalParts = (_brothers * 2) + _sisters;
          final perPart = residual / totalParts;
          shares.add(_ShareResult(
              'Brothers',
              'إِخْوَة',
              perPart * 2 * _brothers,
              (perPart * 2 * _brothers) / estate,
              _brothers,
              '2:1 ratio',
              const Color(0xFF4ECDC4),
              Icons.people_rounded));
          shares.add(_ShareResult(
              'Sisters',
              'أَخَوَات',
              perPart * _sisters,
              (perPart * _sisters) / estate,
              _sisters,
              '2:1 ratio',
              const Color(0xFFFF9EBC),
              Icons.people_rounded));
        } else if (_hasUncle && residual > 0) {
          shares.add(_ShareResult(
              'Uncle',
              'عَمّ',
              residual,
              residual / estate,
              1,
              'Residual (Asabah)',
              const Color(0xFF4ECDC4),
              Icons.man_rounded));
        }
      }
    }

    return shares;
  }

  void _resetAll() {
    HapticFeedback.lightImpact();
    _estateController.clear();
    _debtController.clear();
    _wasiyyahController.clear();
    setState(() {
      _showResult = false;
      _results = [];
      _hasHusband = false;
      _hasWife = false;
      _wifeCount = 1;
      _hasFather = false;
      _hasMother = false;
      _hasGrandfather = false;
      _hasGrandmother = false;
      _sons = 0;
      _daughters = 0;
      _grandsons = 0;
      _granddaughters = 0;
      _brothers = 0;
      _sisters = 0;
      _halfBrothersFather = 0;
      _halfSistersFather = 0;
      _halfBrothersMother = 0;
      _halfSistersMother = 0;
      _hasUncle = false;
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildDeceasedGender(),
                const SizedBox(height: 16),
                _buildCurrencySelector(),
                const SizedBox(height: 16),
                _buildEstateInput(),
                const SizedBox(height: 20),
                _buildSectionLabel('👨‍👩‍👧‍👦', 'FAMILY MEMBERS'),
                const SizedBox(height: 12),
                _buildSpouseSection(),
                const SizedBox(height: 12),
                _buildParentsSection(),
                const SizedBox(height: 12),
                _buildChildrenSection(),
                const SizedBox(height: 12),
                _buildSiblingsSection(),
                const SizedBox(height: 12),
                _buildOtherSection(),
                const SizedBox(height: 24),
                _buildCalculateButton(),
                const SizedBox(height: 16),
                if (_showResult) ...[
                  _buildResultSummary(),
                  const SizedBox(height: 14),
                  _buildSharesList(),
                  const SizedBox(height: 14),
                  _buildPieChart(),
                  const SizedBox(height: 14),
                  _buildResetButton(),
                ],
                const SizedBox(height: 16),
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
      expandedHeight: 130,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E1A),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF1A0D35), Color(0xFF0A0E1A)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('فَرَائِض',
                      style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 24,
                          fontFamily: 'Amiri')),
                  const Text('Inheritance Calculator',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Islamic Law of Succession',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Info Card ──────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA78BFA).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFFA78BFA), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How It Works',
                    style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '1. Enter estate value & debts\n2. Select family members\n3. Calculate automatic Islamic shares',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Deceased Gender ────────────────────────────────────────
  Widget _buildDeceasedGender() {
    return Row(
      children: [
        Text('Deceased:',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        _genderChip('male', '👨', 'Male', const Color(0xFF74C0FC)),
        const SizedBox(width: 8),
        _genderChip('female', '👩', 'Female', const Color(0xFFFF9EBC)),
      ],
    );
  }

  Widget _genderChip(String value, String emoji, String label, Color color) {
    final selected = _deceasedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _deceasedGender = value;
            if (value == 'male') {
              _hasHusband = false;
            } else {
              _hasWife = false;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : const Color(0xFF141926),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? color : Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Currency ───────────────────────────────────────────────
  Widget _buildCurrencySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _currencySymbols.keys.map((c) {
          final sel = c == _currency;
          return GestureDetector(
            onTap: () => setState(() => _currency = c),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFA78BFA) : const Color(0xFF141926),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(c,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Estate Input ───────────────────────────────────────────
  Widget _buildEstateInput() {
    return Column(
      children: [
        _inputField(
            'Total Estate Value',
            'Total wealth of deceased',
            _estateController,
            const Color(0xFF52B788),
            Icons.account_balance_rounded),
        const SizedBox(height: 10),
        _inputField('Debts & Loans', 'Outstanding debts (deducted first)',
            _debtController, const Color(0xFFEF4444), Icons.money_off_rounded),
        const SizedBox(height: 10),
        _inputField(
            'Wasiyyah (Will)',
            'Max 1/3 of estate (optional)',
            _wasiyyahController,
            const Color(0xFFFFD166),
            Icons.description_rounded),
      ],
    );
  }

  Widget _inputField(String label, String hint,
      TextEditingController controller, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15), fontSize: 11),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle:
                        TextStyle(color: color.withValues(alpha: 0.5), fontSize: 13),
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

  // ─── Section Label ──────────────────────────────────────────
  Widget _buildSectionLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
      ],
    );
  }

  // ─── Spouse Section ─────────────────────────────────────────
  Widget _buildSpouseSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spouse',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_deceasedGender == 'female')
            _toggleRow(
                'Husband',
                '👨',
                _hasHusband,
                (v) => setState(() => _hasHusband = v),
                const Color(0xFF74C0FC)),
          if (_deceasedGender == 'male') ...[
            _toggleRow('Wife', '👩', _hasWife,
                (v) => setState(() => _hasWife = v), const Color(0xFFFF9EBC)),
            if (_hasWife)
              _counterRow(
                  'Number of Wives',
                  _wifeCount,
                  1,
                  4,
                  (v) => setState(() => _wifeCount = v),
                  const Color(0xFFFF9EBC)),
          ],
        ],
      ),
    );
  }

  // ─── Parents Section ────────────────────────────────────────
  Widget _buildParentsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parents & Grandparents',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Father', '👨', _hasFather,
              (v) => setState(() => _hasFather = v), const Color(0xFF52B788)),
          _toggleRow('Mother', '👩', _hasMother,
              (v) => setState(() => _hasMother = v), const Color(0xFFA78BFA)),
          if (!_hasFather)
            _toggleRow(
                'Grandfather',
                '👴',
                _hasGrandfather,
                (v) => setState(() => _hasGrandfather = v),
                const Color(0xFF4ECDC4)),
          if (!_hasMother)
            _toggleRow(
                'Grandmother',
                '👵',
                _hasGrandmother,
                (v) => setState(() => _hasGrandmother = v),
                const Color(0xFFFF8C42)),
        ],
      ),
    );
  }

  // ─── Children Section ───────────────────────────────────────
  Widget _buildChildrenSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Children & Grandchildren',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Sons', _sons, 0, 20, (v) => setState(() => _sons = v),
              const Color(0xFF74C0FC)),
          _counterRow('Daughters', _daughters, 0, 20,
              (v) => setState(() => _daughters = v), const Color(0xFFFF9EBC)),
          if (_sons == 0 && _daughters == 0) ...[
            _counterRow('Grandsons', _grandsons, 0, 20,
                (v) => setState(() => _grandsons = v), const Color(0xFF74C0FC)),
            _counterRow(
                'Granddaughters',
                _granddaughters,
                0,
                20,
                (v) => setState(() => _granddaughters = v),
                const Color(0xFFFF9EBC)),
          ],
        ],
      ),
    );
  }

  // ─── Siblings Section ───────────────────────────────────────
  Widget _buildSiblingsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Siblings',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Brothers', _brothers, 0, 20,
              (v) => setState(() => _brothers = v), const Color(0xFF4ECDC4)),
          _counterRow('Sisters', _sisters, 0, 20,
              (v) => setState(() => _sisters = v), const Color(0xFFFF9EBC)),
        ],
      ),
    );
  }

  // ─── Other Section ──────────────────────────────────────────
  Widget _buildOtherSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Other Relatives',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Paternal Uncle', '👨', _hasUncle,
              (v) => setState(() => _hasUncle = v), const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  // ─── Toggle Row ─────────────────────────────────────────────
  Widget _toggleRow(String label, String emoji, bool value,
      ValueChanged<bool> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color:
                          value ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: value ? color : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Counter Row ────────────────────────────────────────────
  Widget _counterRow(String label, int value, int minVal, int maxVal,
      ValueChanged<int> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: value > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: value > minVal
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value - 1);
                  }
                : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.remove_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 16),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text('$value',
                style: TextStyle(
                    color: value > 0 ? color : Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          GestureDetector(
            onTap: value < maxVal
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + 1);
                  }
                : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.add_rounded, color: color, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Calculate Button ───────────────────────────────────────
  Widget _buildCalculateButton() {
    return GestureDetector(
      onTap: _calculate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Calculate Shares',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ─── Result Summary ─────────────────────────────────────────
  Widget _buildResultSummary() {
    final debt = double.tryParse(_debtController.text) ?? 0;
    final wasiyyah = double.tryParse(_wasiyyahController.text) ?? 0;
    final maxW = (_totalEstate - debt) / 3;
    final actualW = wasiyyah > maxW ? maxW : wasiyyah;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A0D35), Color(0xFF2D1B69)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('📊 DISTRIBUTION SUMMARY',
              style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0)),
          const SizedBox(height: 14),
          _summaryRow(
              'Total Estate', _formatAmount(_totalEstate), Colors.white),
          if (debt > 0)
            _summaryRow('Debts Deducted', '- ${_formatAmount(debt)}',
                const Color(0xFFEF4444)),
          if (actualW > 0)
            _summaryRow('Wasiyyah (Will)', '- ${_formatAmount(actualW)}',
                const Color(0xFFFFD166)),
          const Divider(color: Color(0xFF4A3F6B), height: 20),
          _summaryRow('Net Distributable', _formatAmount(_netEstate),
              const Color(0xFF52B788)),
          _summaryRow('Heirs', '${_results.length}', const Color(0xFFA78BFA)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─── Shares List ────────────────────────────────────────────
  Widget _buildSharesList() {
    return Column(
      children: _results.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: r.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: r.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(r.icon, color: r.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            if (r.count > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                    color: r.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('×${r.count}',
                                    style: TextStyle(
                                        color: r.color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        Text(r.arabic,
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 13,
                                color: r.color),
                            textDirection: TextDirection.rtl),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatAmount(r.amount),
                          style: TextStyle(
                              color: r.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      Text('${(r.fraction * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10)),
                      if (r.count > 1)
                        Text('${_formatAmount(r.amount / r.count)} each',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: r.color.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: r.color.withValues(alpha: 0.5), size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(r.rule,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                height: 1.3))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Pie Chart ──────────────────────────────────────────────
  Widget _buildPieChart() {
    if (_results.isEmpty) return const SizedBox.shrink();
    final total = _results.fold<double>(0, (s, r) => s + r.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text('VISUAL BREAKDOWN',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _PieChartPainter(_results, total),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _results.map((r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: r.color,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('${r.label} ${(r.fraction * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                ],
              );
            }).toList(),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 8),
            Text('Reset All',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
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
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('Quran Reference',
                  style: TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"These are the limits set by Allah. Whoever obeys Allah and His Messenger, He will admit him into Gardens beneath which rivers flow, to dwell therein forever. That is the great triumph." — Quran 4:13',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '⚠️ This calculator provides general guidance based on Sunni Hanafi fiqh. For specific cases, consult a qualified Islamic scholar.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PIE CHART PAINTER
// ═══════════════════════════════════════════════════════════
class _PieChartPainter extends CustomPainter {
  final List<_ShareResult> results;
  final double total;

  _PieChartPainter(this.results, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    double startAngle = -pi / 2;

    for (final r in results) {
      final sweepAngle = (r.amount / total) * 2 * pi;
      final paint = Paint()
        ..color = r.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Border
      final borderPaint = Paint()
        ..color = const Color(0xFF0A0E1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Center hole
    final holePaint = Paint()
      ..color = const Color(0xFF0A0E1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════
class _ShareResult {
  final String label;
  final String arabic;
  final double amount;
  final double fraction;
  final int count;
  final String rule;
  final Color color;
  final IconData icon;

  const _ShareResult(this.label, this.arabic, this.amount, this.fraction,
      this.count, this.rule, this.color, this.icon);
}
