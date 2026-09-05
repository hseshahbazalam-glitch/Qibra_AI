import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/a11y/app_a11y.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../logic/inheritance_estimator.dart';
import 'package:flutter/services.dart';
import 'dart:math';

part 'inheritance_calculator_screen.results.dart';

class InheritanceCalculatorScreen extends StatefulWidget {
  const InheritanceCalculatorScreen({super.key});

  @override
  State<InheritanceCalculatorScreen> createState() =>
      _InheritanceCalculatorScreenState();
}

class _InheritanceCalculatorScreenState
    extends State<InheritanceCalculatorScreen> {
  // (Rev) Part-file widget builders live in extensions, and the
  // analyzer treats setState as protected — this thin in-class wrapper
  // keeps their updates legal with zero runtime difference.
  void _patchUi(VoidCallback fn) => setState(fn);

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

    // Stage 3: validation + net-estate + 1/3 wasiyyah cap live in the pure
    // InheritanceEstimator (unit-tested); the share engine stays here.
    final pre = InheritanceEstimator.evaluate(
      estate: estate,
      debts: debt,
      wasiyyah: wasiyyah,
      deceasedGender: _deceasedGender,
      hasHusband: _hasHusband,
      hasWife: _hasWife,
      hasFather: _hasFather,
      hasMother: _hasMother,
      hasGrandfather: _hasGrandfather,
      hasGrandmother: _hasGrandmother,
      sons: _sons,
      daughters: _daughters,
      grandsons: _grandsons,
      granddaughters: _granddaughters,
      brothers: _brothers,
      sisters: _sisters,
      halfBrothersFather: _halfBrothersFather,
      halfSistersFather: _halfSistersFather,
      halfBrothersMother: _halfBrothersMother,
      halfSistersMother: _halfSistersMother,
      hasUncle: _hasUncle,
    );
    if (pre is InheritancePrecheckFailure) {
      _showSnackbar(pre.message);
      return;
    }
    final result = pre as InheritancePrecheckResult;
    if (result.wasiyyahCapped) {
      _showSnackbar(
        'Wasiyyah (will) cannot exceed 1/3 of remaining estate per Sharia. Capped to ${_formatAmount(result.wasiyyahCap)} (requires heirs\' consent to exceed).',
      );
    }

    _totalEstate = estate;
    _netEstate = result.netEstate;

    _results = _calculateShares(result.netEstate);

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
    final colors = QibraColors.of(context);
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
        colors.primary,
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
          colors.accent,
          Icons.woman_rounded,
        );
      }
    }

    // Father
    if (_hasFather) {
      if (hasChildren) {
        fractions['Father'] = 1 / 6;
        sharesMap['Father'] = _ShareResult(
          'Father',
          'أَب',
          0,
          1 / 6,
          1,
          '1/6 fixed share + may get residual',
          colors.primary,
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
        colors.primary,
        Icons.woman_rounded,
      );
    }

    // Grandfather (if no father)
    if (_hasGrandfather && !_hasFather) {
      fractions['Grandfather'] = 1 / 6;
      sharesMap['Grandfather'] = _ShareResult(
        'Grandfather',
        'جَدّ',
        0,
        1 / 6,
        1,
        '1/6 — takes father\'s place',
        colors.primary,
        Icons.elderly_rounded,
      );
    }

    // Grandmother (if no mother)
    if (_hasGrandmother && !_hasMother) {
      fractions['Grandmother'] = 1 / 6;
      sharesMap['Grandmother'] = _ShareResult(
        'Grandmother',
        'جَدَّة',
        0,
        1 / 6,
        1,
        '1/6 — takes mother\'s place',
        colors.accent,
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
        colors.accent,
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
        colors.accent,
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
        colors.accent,
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
        colors.accent,
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
            colors.primary,
            Icons.boy_rounded,
          );
          sharesMap['Daughters'] = _ShareResult(
            'Daughters',
            'بَنَات',
            0,
            daughterFraction * _daughters,
            _daughters,
            '2:1 ratio with sons — each daughter: ${(daughterFraction * 100).toStringAsFixed(1)}%',
            colors.accent,
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
            colors.primary,
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
          colors.primary,
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
          colors.primary,
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
            colors.primary,
            Icons.boy_rounded,
          );
          sharesMap['Granddaughters'] = _ShareResult(
            'Granddaughters',
            'حَفِيدَات',
            0,
            gdaughterF * _granddaughters,
            _granddaughters,
            '2:1 ratio (Asabah)',
            colors.accent,
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
            colors.primary,
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
            colors.primary,
            Icons.people_rounded,
          );
          sharesMap['Sisters'] = _ShareResult(
            'Sisters',
            'أَخَوَات',
            0,
            sisterF * _sisters,
            _sisters,
            '2:1 ratio with brothers',
            colors.accent,
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
            colors.primary,
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
            colors.primary,
            Icons.people_rounded,
          );
          sharesMap['Half Sisters (Paternal)'] = _ShareResult(
            'Half Sisters (Paternal)',
            'أَخَوَاتٌ لِأَب',
            0,
            hsF * _halfSistersFather,
            _halfSistersFather,
            '2:1 ratio',
            colors.accent,
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
            colors.primary,
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
          colors.primary,
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
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: colors.textPrimary)),
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
                _buildSectionLabel(Icons.group_rounded, 'FAMILY MEMBERS'),
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: colors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notice',
                  style: TextStyle(
                    color: colors.error,
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
                    color: colors.error,
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primarySoft.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _understood
                ? colors.primary.withValues(alpha: 0.16)
                : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Calculation Method',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _school,
                    isDense: true,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    dropdownColor: colors.card,
                    icon: Icon(Icons.arrow_drop_down_rounded,
                        color: colors.textSecondary, size: 18),
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
              style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
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
                  activeColor: colors.primary,
                  checkColor: colors.onPrimary,
                  side: BorderSide(
                      color: _understood
                          ? colors.primary
                          : colors.textTertiary),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'I understand this is an educational estimate and I will consult a qualified Islamic scholar before distributing inheritance.',
                      style: TextStyle(
                          color: _understood
                              ? colors.textPrimary
                              : colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 130,
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
              color: colors.textPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_rounded,
              color: colors.textPrimary, size: 20),
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
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فَرَائِض',
                    style: AppArabicStyles.quranMedium.copyWith(
                      color: colors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text('Inheritance Calculator',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Islamic Law of Succession',
                      style: TextStyle(
                          color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primarySoft.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline_rounded,
                color: colors.primarySoft, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How It Works',
                    style: TextStyle(
                        color: colors.primarySoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '1. Enter estate value & debts\n'
                  '2. Select family members\n'
                  '3. Calculate automatic Islamic shares',
                  style: TextStyle(
                      color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Text('Deceased:',
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        _genderChip('male', Icons.male_rounded, 'Male', colors.primarySoft),
        const SizedBox(width: 8),
        _genderChip('female', Icons.female_rounded, 'Female', colors.accent),
      ],
    );
  }

  Widget _genderChip(String value, IconData icon, String label, Color color) {
    final colors = QibraColors.of(context);
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
                : colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color:
                    selected ? color : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? color
                          : colors.textSecondary,
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
    final colors = QibraColors.of(context);
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
                color: sel ? colors.primarySoft : colors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(c,
                  style: TextStyle(
                      color: sel
                          ? colors.onPrimary
                          : colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        _inputField(
            'Total Estate Value',
            'Total wealth of deceased',
            _estateController,
            colors.primary,
            Icons.account_balance_rounded),
        const SizedBox(height: 10),
        _inputField('Debts & Loans', 'Outstanding debts (deducted first)',
            _debtController, colors.error, Icons.money_off_rounded),
        const SizedBox(height: 10),
        _inputField(
            'Wasiyyah (Will)',
            'Max 1/3 of estate (optional)',
            _wasiyyahController,
            colors.accent,
            Icons.description_rounded),
      ],
    );
  }

  Widget _inputField(String label, String hint,
      TextEditingController controller, Color color, IconData icon) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
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
                    style: TextStyle(
                        color: colors.textPrimary,
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
                        color: colors.textPrimary.withValues(alpha: 0.15),
                        fontSize: 11),
                    prefixText: '${_currencySymbols[_currency]} ',
                    prefixStyle: TextStyle(
                        color: color, fontSize: 13),
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
}