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
  // Phase 4 — Fara'id safety gate
  bool _understood = false;
  String _school = 'Hanafi'; // Sunni / Hanafi reference calculation

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
    if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  void _calculate() {
    if (!_understood) {
      _showSnackbar(
          'Please confirm: I understand this is an educational estimate and I will consult a qualified scholar.');
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.heavyImpact();
    final estate = double.tryParse(_estateController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;
    final wasiyyah = double.tryParse(_wasiyyahController.text) ?? 0;

    if (estate <= 0) {
      _showSnackbar('Please enter total estate value');
      return;
    }

    // Validate heir selection
    if (!_hasHusband &&
        !_hasWife &&
        !_hasFather &&
        !_hasMother &&
        !_hasGrandfather &&
        !_hasGrandmother &&
        _sons == 0 &&
        _daughters == 0 &&
        _grandsons == 0 &&
        _granddaughters == 0 &&
        _brothers == 0 &&
        _sisters == 0 &&
        _halfBrothersFather == 0 &&
        _halfSistersFather == 0 &&
        _halfBrothersMother == 0 &&
        _halfSistersMother == 0 &&
        !_hasUncle) {
      _showSnackbar('Please select at least one heir');
      return;
    }

    // Invalid spouse combinations (spouse + spouse, or mismatched gender)
    if (_hasHusband && _hasWife) {
      _showSnackbar(
          'Cannot have both husband and wife as heirs — invalid combination');
      return;
    }
    if (_deceasedGender == 'male' && _hasHusband) {
      _showSnackbar('Deceased is male — husband cannot be an heir');
      return;
    }
    if (_deceasedGender == 'female' && _hasWife) {
      _showSnackbar('Deceased is female — wife cannot be an heir');
      return;
    }

    double remaining = estate - debt;
    if (remaining <= 0) {
      _showSnackbar('Debts exceed estate — no inheritance to distribute');
      return;
    }

    final maxWasiyyah = remaining / 3;
    double actualWasiyyah = wasiyyah;
    if (wasiyyah > maxWasiyyah) {
      actualWasiyyah = maxWasiyyah;
      _showSnackbar(
        'Wasiyyah (will) cannot exceed 1/3 of remaining estate per Sharia. Capped to ${_formatAmount(maxWasiyyah)} (requires heirs\' consent to exceed).',
      );
    }
    remaining -= actualWasiyyah;

    _totalEstate = estate;
    _netEstate = remaining;

    _results = _calculateShares(remaining);

    // Validation: total fractions must sum to 1.0 ± 0.005, total amount == _netEstate
    final totalFrac = _results.fold<double>(0, (sum, r) => sum + r.fraction);
    final totalAmt = _results.fold<double>(0, (sum, r) => sum + r.amount);
    if ((totalFrac - 1.0).abs() > 0.005) {
      _showSnackbar(
          'Warning: shares sum to ${(totalFrac * 100).toStringAsFixed(1)}% — please verify heirs selection.');
    }
    if ((totalAmt - _netEstate).abs() > 1) {
      _showSnackbar(
          'Calculation mismatch — please double-check inputs or consult a scholar.');
    }

    setState(() => _showResult = true);
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN CALCULATION — AWL + RADD + HALF SIBLINGS FIXED
  // ═══════════════════════════════════════════════════════════
  List<_ShareResult> _calculateShares(double estate) {
    Map<String, _ShareResult> sharesMap = {};
    Map<String, double> fractions = {};

    bool hasChildren =
        _sons > 0 || _daughters > 0 || _grandsons > 0 || _granddaughters > 0;

    // ─── STEP 1: Fixed Shares (Fard) ──────────────────────

    // Husband
    if (_hasHusband && _deceasedGender == 'female') {
      double f = hasChildren ? 1 / 4 : 1 / 2;
      String rule = hasChildren
          ? '1/4 — because deceased has children'
          : '1/2 — because deceased has no children';
      fractions['Husband'] = f;
      sharesMap['Husband'] = _ShareResult(
        'Husband',
        'زَوْج',
        0,
        f,
        1,
        rule,
        const Color(0xFF2F6B5D),
        Icons.man_rounded,
      );
    }

    // Wife/Wives
    if (_hasWife && _deceasedGender == 'male') {
      double f = hasChildren ? 1 / 8 : 1 / 4;
      String rule = hasChildren
          ? '1/8 — because deceased has children'
          : '1/4 — because deceased has no children';
      double perWife = f / _wifeCount;
      for (int i = 0; i < _wifeCount; i++) {
        String key = 'Wife${_wifeCount > 1 ? "_$i" : ""}';
        String label = 'Wife${_wifeCount > 1 ? " ${i + 1}" : ""}';
        fractions[key] = perWife;
        sharesMap[key] = _ShareResult(
          label,
          'زَوْجَة',
          0,
          perWife,
          1,
          '$rule (shared among $_wifeCount wife${_wifeCount > 1 ? "s" : ""})',
          const Color(0xFFC6A15B),
          Icons.woman_rounded,
        );
      }
    }

    // Father
    if (_hasFather) {
      if (hasChildren) {
        fractions['Father'] = 1 / 6;
        sharesMap['Father'] = const _ShareResult(
          'Father',
          'أَب',
          0,
          1 / 6,
          1,
          '1/6 fixed share + may get residual',
          Color(0xFF123F36),
          Icons.man_rounded,
        );
      }
      // If no children, father gets residual — handled in Step 2
    }

    // Mother
    if (_hasMother) {
      bool hasMultipleSiblings =
          (_brothers + _sisters + _halfBrothersFather + _halfSistersFather) >=
              2;
      double f;
      String rule;
      if (hasChildren) {
        f = 1 / 6;
        rule = '1/6 — because deceased has children';
      } else if (hasMultipleSiblings) {
        f = 1 / 6;
        rule = '1/6 — because deceased has multiple siblings';
      } else {
        f = 1 / 3;
        rule = '1/3 — no children and less than 2 siblings';
      }
      fractions['Mother'] = f;
      sharesMap['Mother'] = _ShareResult(
        'Mother',
        'أُمّ',
        0,
        f,
        1,
        rule,
        const Color(0xFF2F6B5D),
        Icons.woman_rounded,
      );
    }

    // Grandfather (if no father)
    if (_hasGrandfather && !_hasFather) {
      fractions['Grandfather'] = 1 / 6;
      sharesMap['Grandfather'] = const _ShareResult(
        'Grandfather',
        'جَدّ',
        0,
        1 / 6,
        1,
        '1/6 — takes father\'s place',
        Color(0xFF2F6B5D),
        Icons.elderly_rounded,
      );
    }

    // Grandmother (if no mother)
    if (_hasGrandmother && !_hasMother) {
      fractions['Grandmother'] = 1 / 6;
      sharesMap['Grandmother'] = const _ShareResult(
        'Grandmother',
        'جَدَّة',
        0,
        1 / 6,
        1,
        '1/6 — takes mother\'s place',
        Color(0xFFC6A15B),
        Icons.elderly_woman_rounded,
      );
    }

    // Daughters only (no sons)
    if (_daughters > 0 && _sons == 0 && _grandsons == 0) {
      double f = _daughters == 1 ? 1 / 2 : 2 / 3;
      String rule = _daughters == 1
          ? '1/2 — one daughter without sons'
          : '2/3 — multiple daughters without sons';
      fractions['Daughters'] = f;
      sharesMap['Daughters'] = _ShareResult(
        'Daughters',
        'بَنَات',
        0,
        f,
        _daughters,
        rule,
        const Color(0xFFC6A15B),
        Icons.girl_rounded,
      );
    }

    // Granddaughters only (no sons, no daughters, no grandsons)
    if (_granddaughters > 0 &&
        _sons == 0 &&
        _daughters == 0 &&
        _grandsons == 0) {
      double f = _granddaughters == 1 ? 1 / 2 : 2 / 3;
      fractions['Granddaughters'] = f;
      sharesMap['Granddaughters'] = _ShareResult(
        'Granddaughters',
        'حَفِيدَات',
        0,
        f,
        _granddaughters,
        _granddaughters == 1 ? '1/2' : '2/3',
        const Color(0xFFC6A15B),
        Icons.girl_rounded,
      );
    }

    // Sisters only (no brothers, no children, no father)
    if (_sisters > 0 && _brothers == 0 && !hasChildren && !_hasFather) {
      double f = _sisters == 1 ? 1 / 2 : 2 / 3;
      fractions['Sisters'] = f;
      sharesMap['Sisters'] = _ShareResult(
        'Sisters',
        'أَخَوَات',
        0,
        f,
        _sisters,
        _sisters == 1 ? '1/2' : '2/3',
        const Color(0xFFC6A15B),
        Icons.people_rounded,
      );
    }

    // Maternal Half-Siblings (FIXED — separate rules)
    int maternalSiblings = _halfBrothersMother + _halfSistersMother;
    if (maternalSiblings > 0 && !hasChildren && !_hasFather) {
      double f = maternalSiblings == 1 ? 1 / 6 : 1 / 3;
      String rule = maternalSiblings == 1
          ? '1/6 — one maternal sibling'
          : '1/3 — multiple maternal siblings (shared equally)';
      fractions['Maternal Siblings'] = f;
      sharesMap['Maternal Siblings'] = _ShareResult(
        'Maternal Siblings',
        'أَخَوَاتٌ لِأُمّ',
        0,
        f,
        maternalSiblings,
        rule,
        const Color(0xFFC6A15B),
        Icons.people_rounded,
      );
    }

    // ─── STEP 2: Check if Awl needed ──────────────────────
    double totalFixed = fractions.values.fold(0.0, (sum, f) => sum + f);

    // AWL: Shares exceed 100% — reduce proportionally
    if (totalFixed > 1.001) {
      double factor = 1.0 / totalFixed;
      fractions.updateAll((key, value) => value * factor);
      // Update fractions in sharesMap
      sharesMap.forEach((key, result) {
        sharesMap[key] = _ShareResult(
          result.label,
          result.arabic,
          0,
          fractions[key] ?? result.fraction,
          result.count,
          '${result.rule} (Awl applied — proportional reduction)',
          result.color,
          result.icon,
        );
      });
      totalFixed = 1.0;
    }

    // ─── STEP 3: Residual (Asabah) ────────────────────────
    double remainder = 1.0 - totalFixed;

    if (remainder > 0.001) {
      // Sons + Daughters (2:1)
      if (_sons > 0) {
        if (_daughters > 0) {
          int totalParts = (_sons * 2) + _daughters;
          double sonFraction = (2 * remainder) / totalParts;
          double daughterFraction = remainder / totalParts;
          fractions['Sons'] = sonFraction * _sons;
          fractions['Daughters'] = daughterFraction * _daughters;
          sharesMap['Sons'] = _ShareResult(
            'Sons',
            'أَبْنَاء',
            0,
            sonFraction * _sons,
            _sons,
            '2:1 ratio with daughters — each son: ${(sonFraction * 100).toStringAsFixed(1)}%',
            const Color(0xFF2F6B5D),
            Icons.boy_rounded,
          );
          sharesMap['Daughters'] = _ShareResult(
            'Daughters',
            'بَنَات',
            0,
            daughterFraction * _daughters,
            _daughters,
            '2:1 ratio with sons — each daughter: ${(daughterFraction * 100).toStringAsFixed(1)}%',
            const Color(0xFFC6A15B),
            Icons.girl_rounded,
          );
        } else {
          fractions['Sons'] = remainder;
          sharesMap['Sons'] = _ShareResult(
            'Sons',
            'أَبْنَاء',
            0,
            remainder,
            _sons,
            'Equal residual share among $_sons son${_sons > 1 ? "s" : ""} (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.boy_rounded,
          );
        }
        remainder = 0;
      }
      // Father as Asabah (no sons)
      else if (_hasFather && !fractions.containsKey('Father')) {
        fractions['Father'] = remainder;
        sharesMap['Father'] = _ShareResult(
          'Father',
          'أَب',
          0,
          remainder,
          1,
          'Residual — no male children (Asabah)',
          const Color(0xFF123F36),
          Icons.man_rounded,
        );
        remainder = 0;
      }
      // Father fixed share + Asabah
      else if (_hasFather && fractions.containsKey('Father') && remainder > 0) {
        double existingF = fractions['Father'] ?? 0;
        double newF = existingF + remainder;
        fractions['Father'] = newF;
        sharesMap['Father'] = _ShareResult(
          'Father (Fixed + Asabah)',
          'أَب',
          0,
          newF,
          1,
          '1/6 fixed + residual after daughters',
          const Color(0xFF123F36),
          Icons.man_rounded,
        );
        remainder = 0;
      }
      // Grandsons + Granddaughters
      else if (_grandsons > 0 && _sons == 0 && _daughters == 0) {
        if (_granddaughters > 0) {
          int totalParts = (_grandsons * 2) + _granddaughters;
          double gsonF = (2 * remainder) / totalParts;
          double gdaughterF = remainder / totalParts;
          fractions['Grandsons'] = gsonF * _grandsons;
          fractions['Granddaughters'] = gdaughterF * _granddaughters;
          sharesMap['Grandsons'] = _ShareResult(
            'Grandsons',
            'أَحْفَاد',
            0,
            gsonF * _grandsons,
            _grandsons,
            '2:1 ratio (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.boy_rounded,
          );
          sharesMap['Granddaughters'] = _ShareResult(
            'Granddaughters',
            'حَفِيدَات',
            0,
            gdaughterF * _granddaughters,
            _granddaughters,
            '2:1 ratio (Asabah)',
            const Color(0xFFC6A15B),
            Icons.girl_rounded,
          );
        } else {
          fractions['Grandsons'] = remainder;
          sharesMap['Grandsons'] = _ShareResult(
            'Grandsons',
            'أَحْفَاد',
            0,
            remainder,
            _grandsons,
            'Equal residual (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.boy_rounded,
          );
        }
        remainder = 0;
      }
      // Brothers + Sisters (2:1)
      else if (_brothers > 0 && !hasChildren && !_hasFather) {
        if (_sisters > 0) {
          int totalParts = (_brothers * 2) + _sisters;
          double brotherF = (2 * remainder) / totalParts;
          double sisterF = remainder / totalParts;
          fractions['Brothers'] = brotherF * _brothers;
          fractions['Sisters'] = sisterF * _sisters;
          sharesMap['Brothers'] = _ShareResult(
            'Brothers',
            'إِخْوَة',
            0,
            brotherF * _brothers,
            _brothers,
            '2:1 ratio with sisters (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.people_rounded,
          );
          sharesMap['Sisters'] = _ShareResult(
            'Sisters',
            'أَخَوَات',
            0,
            sisterF * _sisters,
            _sisters,
            '2:1 ratio with brothers',
            const Color(0xFFC6A15B),
            Icons.people_rounded,
          );
        } else {
          fractions['Brothers'] = remainder;
          sharesMap['Brothers'] = _ShareResult(
            'Brothers',
            'إِخْوَة',
            0,
            remainder,
            _brothers,
            'Equal residual (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.people_rounded,
          );
        }
        remainder = 0;
      }
      // Paternal Half-Brothers (if no full brothers)
      else if (_halfBrothersFather > 0 &&
          _brothers == 0 &&
          !hasChildren &&
          !_hasFather) {
        if (_halfSistersFather > 0) {
          int totalParts = (_halfBrothersFather * 2) + _halfSistersFather;
          double hbF = (2 * remainder) / totalParts;
          double hsF = remainder / totalParts;
          fractions['Half Brothers (Paternal)'] = hbF * _halfBrothersFather;
          fractions['Half Sisters (Paternal)'] = hsF * _halfSistersFather;
          sharesMap['Half Brothers (Paternal)'] = _ShareResult(
            'Half Brothers (Paternal)',
            'إِخْوَةٌ لِأَب',
            0,
            hbF * _halfBrothersFather,
            _halfBrothersFather,
            '2:1 ratio (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.people_rounded,
          );
          sharesMap['Half Sisters (Paternal)'] = _ShareResult(
            'Half Sisters (Paternal)',
            'أَخَوَاتٌ لِأَب',
            0,
            hsF * _halfSistersFather,
            _halfSistersFather,
            '2:1 ratio',
            const Color(0xFFC6A15B),
            Icons.people_rounded,
          );
        } else {
          fractions['Half Brothers (Paternal)'] = remainder;
          sharesMap['Half Brothers (Paternal)'] = _ShareResult(
            'Half Brothers (Paternal)',
            'إِخْوَةٌ لِأَب',
            0,
            remainder,
            _halfBrothersFather,
            'Equal residual (Asabah)',
            const Color(0xFF2F6B5D),
            Icons.people_rounded,
          );
        }
        remainder = 0;
      }
      // Uncle
      else if (_hasUncle && remainder > 0) {
        fractions['Uncle'] = remainder;
        sharesMap['Uncle'] = _ShareResult(
          'Uncle',
          'عَمّ',
          0,
          remainder,
          1,
          'Residual (Asabah)',
          const Color(0xFF2F6B5D),
          Icons.man_rounded,
        );
        remainder = 0;
      }
    }

    // ─── STEP 4: RADD ─────────────────────────────────────
    // If remainder still exists and no Asabah — return to
    // fixed share heirs (except Husband/Wife)
    double finalTotal = fractions.values.fold(0.0, (sum, f) => sum + f);
    double surplus = 1.0 - finalTotal;

    if (surplus > 0.001) {
      // Radd heirs — exclude spouse
      Map<String, double> raddHeirs = Map.from(fractions);
      raddHeirs.remove('Husband');
      for (int i = 0; i < _wifeCount; i++) {
        raddHeirs.remove('Wife${_wifeCount > 1 ? "_$i" : ""}');
      }

      if (raddHeirs.isNotEmpty) {
        double raddTotal = raddHeirs.values.fold(0.0, (sum, f) => sum + f);
        raddHeirs.forEach((key, f) {
          double extra = surplus * (f / raddTotal);
          fractions[key] = (fractions[key] ?? 0) + extra;
          if (sharesMap.containsKey(key)) {
            _ShareResult old = sharesMap[key]!;
            sharesMap[key] = _ShareResult(
              old.label,
              old.arabic,
              0,
              fractions[key]!,
              old.count,
              '${old.rule} (Radd applied)',
              old.color,
              old.icon,
            );
          }
        });
      }
    }

    // ─── STEP 5: Convert fractions to amounts ─────────────
    List<_ShareResult> results = [];
    sharesMap.forEach((key, result) {
      double f = fractions[key] ?? result.fraction;
      double amount = estate * f;
      results.add(_ShareResult(
        result.label,
        result.arabic,
        amount,
        f,
        result.count,
        result.rule,
        result.color,
        result.icon,
      ));
    });

    return results;
  }

  void _resetAll() {
    HapticFeedback.lightImpact();
    _estateController.clear();
    _debtController.clear();
    _wasiyyahController.clear();
    setState(() {
      _showResult = false;
      _results = [];
      _understood = false;
      _school = 'Hanafi';
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
      content: Text(msg, style: const TextStyle(color: const Color(0xFF19312C))),
      backgroundColor: const Color(0xFF123F36),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // DISCLAIMER — Sabse Pehle
                _buildDisclaimer(),
                const SizedBox(height: 16),
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
                _buildHalfSiblingsSection(),
                const SizedBox(height: 12),
                _buildOtherSection(),
                const SizedBox(height: 16),
                _buildSafetyGate(),
                const SizedBox(height: 16),
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

  // ─── Disclaimer ─────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Important Notice',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These calculations are for educational reference only. '
                  'Islamic inheritance (Fara\'id) has school-of-thought '
                  'variations. Please consult a qualified Islamic scholar '
                  'before making any actual distribution decisions.',
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Safety Gate — Phase 4: Mandatory confirmation ─────────────
  Widget _buildSafetyGate() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6B5D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _understood
                ? const Color(0xFF123F36).withValues(alpha: 0.4)
                : Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Calculation Method',
                    style: TextStyle(
                        color: const Color(0xFF19312C).withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF19312C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _school,
                    isDense: true,
                    style: const TextStyle(
                        color: const Color(0xFF19312C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    dropdownColor: const Color(0xFFFEFDF9),
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: Colors.white54, size: 18),
                    items: const [
                      DropdownMenuItem(
                          value: 'Hanafi',
                          child: Text('Sunni / Hanafi (reference)')),
                      DropdownMenuItem(
                          value: 'Shafi', child: Text('Sunni / Shafi\'i')),
                      DropdownMenuItem(
                          value: 'Maliki', child: Text('Sunni / Maliki')),
                      DropdownMenuItem(
                          value: 'Hanbali', child: Text('Sunni / Hanbali')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _school = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_school != 'Hanafi') ...[
            const SizedBox(height: 8),
            Text(
              'Note: This calculator implements Sunni/Hanafi reference logic. Other schools may differ for some cases (e.g., Radd, grandfather). Result is for educational reference.',
              style: TextStyle(
                  color: Colors.orange.withValues(alpha: 0.7),
                  fontSize: 10,
                  height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _understood = !_understood),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _understood,
                  onChanged: (v) => setState(() => _understood = v ?? false),
                  activeColor: const Color(0xFF123F36),
                  checkColor: Colors.white,
                  side: BorderSide(
                      color: _understood
                          ? const Color(0xFF123F36)
                          : Colors.orange.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'I understand this is an educational estimate and I will consult a qualified Islamic scholar before distributing inheritance.',
                      style: TextStyle(
                          color: _understood
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ),
              ],
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
      backgroundColor: const Color(0xFFF5F3EC),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFF19312C).withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded,
              color: const Color(0xFF19312C), size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFEEF1EA), Color(0xFFF5F3EC)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('فَرَائِض',
                      style: TextStyle(
                          color: Color(0xFF2F6B5D),
                          fontSize: 24,
                          fontFamily: 'Amiri')),
                  const Text('Inheritance Calculator',
                      style: TextStyle(
                          color: const Color(0xFF19312C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Islamic Law of Succession',
                      style: TextStyle(
                          color: const Color(0xFF19312C).withValues(alpha: 0.4),
                          fontSize: 12)),
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
        color: const Color(0xFF2F6B5D).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2F6B5D).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2F6B5D).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF2F6B5D), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How It Works',
                    style: TextStyle(
                        color: Color(0xFF2F6B5D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '1. Enter estate value & debts\n'
                  '2. Select family members\n'
                  '3. Calculate automatic Islamic shares',
                  style: TextStyle(
                      color: const Color(0xFF19312C).withValues(alpha: 0.5),
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
                color: const Color(0xFF19312C).withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        _genderChip('male', '👨', 'Male', const Color(0xFF2F6B5D)),
        const SizedBox(width: 8),
        _genderChip('female', '👩', 'Female', const Color(0xFFC6A15B)),
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
            color: selected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFFFEFDF9),
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
                      color: selected
                          ? color
                          : Colors.white.withValues(alpha: 0.4),
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
                color: sel ? const Color(0xFF2F6B5D) : const Color(0xFFFEFDF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(c,
                  style: TextStyle(
                      color: sel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
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
            const Color(0xFF123F36),
            Icons.account_balance_rounded),
        const SizedBox(height: 10),
        _inputField('Debts & Loans', 'Outstanding debts (deducted first)',
            _debtController, const Color(0xFFEF4444), Icons.money_off_rounded),
        const SizedBox(height: 10),
        _inputField(
            'Wasiyyah (Will)',
            'Max 1/3 of estate (optional)',
            _wasiyyahController,
            const Color(0xFFC6A15B),
            Icons.description_rounded),
      ],
    );
  }

  Widget _inputField(String label, String hint,
      TextEditingController controller, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
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
                        color: const Color(0xFF19312C),
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
                        color: const Color(0xFF19312C).withValues(alpha: 0.15),
                        fontSize: 11),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle: TextStyle(
                        color: color.withValues(alpha: 0.5), fontSize: 13),
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
                color: const Color(0xFF19312C).withValues(alpha: 0.5),
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
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spouse',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_deceasedGender == 'female')
            _toggleRow(
                'Husband',
                '👨',
                _hasHusband,
                (v) => setState(() => _hasHusband = v),
                const Color(0xFF2F6B5D)),
          if (_deceasedGender == 'male') ...[
            _toggleRow('Wife', '👩', _hasWife,
                (v) => setState(() => _hasWife = v), const Color(0xFFC6A15B)),
            if (_hasWife)
              _counterRow(
                  'Number of Wives',
                  _wifeCount,
                  1,
                  4,
                  (v) => setState(() => _wifeCount = v),
                  const Color(0xFFC6A15B)),
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
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parents & Grandparents',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Father', '👨', _hasFather,
              (v) => setState(() => _hasFather = v), const Color(0xFF123F36)),
          _toggleRow('Mother', '👩', _hasMother,
              (v) => setState(() => _hasMother = v), const Color(0xFF2F6B5D)),
          if (!_hasFather)
            _toggleRow(
                'Grandfather',
                '👴',
                _hasGrandfather,
                (v) => setState(() => _hasGrandfather = v),
                const Color(0xFF2F6B5D)),
          if (!_hasMother)
            _toggleRow(
                'Grandmother',
                '👵',
                _hasGrandmother,
                (v) => setState(() => _hasGrandmother = v),
                const Color(0xFFC6A15B)),
        ],
      ),
    );
  }

  // ─── Children Section ───────────────────────────────────────
  Widget _buildChildrenSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Children & Grandchildren',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Sons', _sons, 0, 20, (v) => setState(() => _sons = v),
              const Color(0xFF2F6B5D)),
          _counterRow('Daughters', _daughters, 0, 20,
              (v) => setState(() => _daughters = v), const Color(0xFFC6A15B)),
          if (_sons == 0 && _daughters == 0) ...[
            _counterRow('Grandsons', _grandsons, 0, 20,
                (v) => setState(() => _grandsons = v), const Color(0xFF2F6B5D)),
            _counterRow(
                'Granddaughters',
                _granddaughters,
                0,
                20,
                (v) => setState(() => _granddaughters = v),
                const Color(0xFFC6A15B)),
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
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Siblings',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Brothers', _brothers, 0, 20,
              (v) => setState(() => _brothers = v), const Color(0xFF2F6B5D)),
          _counterRow('Sisters', _sisters, 0, 20,
              (v) => setState(() => _sisters = v), const Color(0xFFC6A15B)),
        ],
      ),
    );
  }

  // ─── Half Siblings Section (NEW — FIXED) ────────────────────
  Widget _buildHalfSiblingsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Half Siblings',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Paternal (same father)',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.3), fontSize: 10)),
          const SizedBox(height: 8),
          _counterRow(
              'Paternal Half Brothers',
              _halfBrothersFather,
              0,
              20,
              (v) => setState(() => _halfBrothersFather = v),
              const Color(0xFF2F6B5D)),
          _counterRow(
              'Paternal Half Sisters',
              _halfSistersFather,
              0,
              20,
              (v) => setState(() => _halfSistersFather = v),
              const Color(0xFFC6A15B)),
          const SizedBox(height: 8),
          Text('Maternal (same mother)',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.3), fontSize: 10)),
          const SizedBox(height: 8),
          _counterRow(
              'Maternal Half Brothers',
              _halfBrothersMother,
              0,
              20,
              (v) => setState(() => _halfBrothersMother = v),
              const Color(0xFFC6A15B)),
          _counterRow(
              'Maternal Half Sisters',
              _halfSistersMother,
              0,
              20,
              (v) => setState(() => _halfSistersMother = v),
              const Color(0xFFC6A15B)),
        ],
      ),
    );
  }

  // ─── Other Section ──────────────────────────────────────────
  Widget _buildOtherSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Other Relatives',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Paternal Uncle', '👨', _hasUncle,
              (v) => setState(() => _hasUncle = v), const Color(0xFF2F6B5D)),
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
                      color: value
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
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
                      color: const Color(0xFF19312C), shape: BoxShape.circle),
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
                  color: const Color(0xFF19312C).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.remove_rounded,
                  color: const Color(0xFF19312C).withValues(alpha: 0.3), size: 16),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text('$value',
                style: TextStyle(
                    color:
                        value > 0 ? color : Colors.white.withValues(alpha: 0.3),
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
    final enabled = _understood;
    return GestureDetector(
      onTap: enabled
          ? _calculate
          : () {
              HapticFeedback.heavyImpact();
              _showSnackbar(
                  'Please confirm the disclaimer above before calculating.');
            },
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: enabled
                    ? [const Color(0xFF2F6B5D), const Color(0xFFC6A15B)]
                    : [
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2)
                      ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: const Color(0xFF2F6B5D).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate_rounded,
                  color: enabled ? Colors.white : Colors.white54, size: 22),
              const SizedBox(width: 10),
              Text('Calculate Shares',
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              if (!enabled) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock_rounded, color: Colors.white30, size: 16),
              ],
            ],
          ),
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
            colors: [Color(0xFFEEF1EA), Color(0xFF2D1B69)]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF2F6B5D).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('DISTRIBUTION SUMMARY',
              style: TextStyle(
                  color: Color(0xFF2F6B5D),
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
                const Color(0xFFC6A15B)),
          const Divider(color: Color(0xFF4A3F6B), height: 20),
          _summaryRow('Net Distributable', _formatAmount(_netEstate),
              const Color(0xFF123F36)),
          _summaryRow('Heirs', '${_results.length}', const Color(0xFF2F6B5D)),
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
                  color: const Color(0xFF19312C).withValues(alpha: 0.5), fontSize: 12)),
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
                                    color: const Color(0xFF19312C),
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
                              color: const Color(0xFF19312C).withValues(alpha: 0.4),
                              fontSize: 10)),
                      if (r.count > 1)
                        Text('${_formatAmount(r.amount / r.count)} each',
                            style: TextStyle(
                                color: const Color(0xFF19312C).withValues(alpha: 0.3),
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
                                color: const Color(0xFF19312C).withValues(alpha: 0.4),
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
        color: const Color(0xFFFEFDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text('VISUAL BREAKDOWN',
              style: TextStyle(
                  color: const Color(0xFF19312C).withValues(alpha: 0.4),
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
                          color: const Color(0xFF19312C).withValues(alpha: 0.5),
                          fontSize: 10)),
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
          color: const Color(0xFF19312C).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded,
                color: const Color(0xFF19312C).withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 8),
            Text('Reset All',
                style: TextStyle(
                    color: const Color(0xFF19312C).withValues(alpha: 0.5),
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
        border:
            Border.all(color: const Color(0xFF2F6B5D).withValues(alpha: 0.15)),
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
                      color: Color(0xFF2F6B5D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"These are the limits set by Allah. Whoever obeys Allah '
            'and His Messenger, He will admit him into Gardens beneath '
            'which rivers flow." — Quran 4:13',
            style: TextStyle(
                color: const Color(0xFF19312C).withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'This calculator uses Sunni Hanafi fiqh principles. '
            'Awl and Radd rules are applied automatically. '
            'For complex cases, always consult a qualified Islamic scholar.',
            style: TextStyle(
                color: const Color(0xFF19312C).withValues(alpha: 0.35),
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
    if (total <= 0 || results.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    if (radius <= 0) return;
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

      final borderPaint = Paint()
        ..color = const Color(0xFFF5F3EC)
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

    final holePaint = Paint()
      ..color = const Color(0xFFF5F3EC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════
// MODEL
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

  const _ShareResult(
    this.label,
    this.arabic,
    this.amount,
    this.fraction,
    this.count,
    this.rule,
    this.color,
    this.icon,
  );
}
