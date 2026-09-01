// QIBRA AI — INHERITANCE CALCULATOR (results widgets + painter part)

part of 'inheritance_calculator_screen.dart';


// ══════════════════════════════════════════════════════════
// Moved by Stage 3 file split — same library (part file),
// private classes/fields still resolve. Behavior unchanged.
// ══════════════════════════════════════════════════════════

extension _InheritanceResultsWidgets on _InheritanceCalculatorScreenState {
  Widget _buildSectionLabel(IconData icon, String label) {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Icon(
            icon,
            size: 14,
            color: colors.textPrimary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
      ],
    );
  }

  // ─── Spouse Section ─────────────────────────────────────────
  Widget _buildSpouseSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spouse',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_deceasedGender == 'female')
            _toggleRow(
                'Husband', Icons.man_rounded,
                _hasHusband,
                (v) => setState(() => _hasHusband = v),
                colors.primarySoft),
          if (_deceasedGender == 'male') ...[
            _toggleRow('Wife', Icons.woman_rounded, _hasWife,
                (v) => setState(() => _hasWife = v), colors.accent),
            if (_hasWife)
              _counterRow(
                  'Number of Wives',
                  _wifeCount,
                  1,
                  4,
                  (v) => setState(() => _wifeCount = v),
                  colors.accent),
          ],
        ],
      ),
    );
  }

  // ─── Parents Section ────────────────────────────────────────
  Widget _buildParentsSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parents & Grandparents',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Father', Icons.man_rounded, _hasFather,
              (v) => setState(() => _hasFather = v), colors.primary),
          _toggleRow('Mother', Icons.woman_rounded, _hasMother,
              (v) => setState(() => _hasMother = v), colors.primarySoft),
          if (!_hasFather)
            _toggleRow(
                'Grandfather', Icons.elderhood_rounded,
                _hasGrandfather,
                (v) => setState(() => _hasGrandfather = v),
                colors.primarySoft),
          if (!_hasMother)
            _toggleRow(
                'Grandmother', Icons.elderhood_rounded,
                _hasGrandmother,
                (v) => setState(() => _hasGrandmother = v),
                colors.accent),
        ],
      ),
    );
  }

  // ─── Children Section ───────────────────────────────────────
  Widget _buildChildrenSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Children & Grandchildren',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Sons', _sons, 0, 20, (v) => setState(() => _sons = v),
              colors.primarySoft),
          _counterRow('Daughters', _daughters, 0, 20,
              (v) => setState(() => _daughters = v), colors.accent),
          if (_sons == 0 && _daughters == 0) ...[
            _counterRow('Grandsons', _grandsons, 0, 20,
                (v) => setState(() => _grandsons = v), colors.primarySoft),
            _counterRow(
                'Granddaughters',
                _granddaughters,
                0,
                20,
                (v) => setState(() => _granddaughters = v),
                colors.accent),
          ],
        ],
      ),
    );
  }

  // ─── Siblings Section ───────────────────────────────────────
  Widget _buildSiblingsSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Siblings',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _counterRow('Brothers', _brothers, 0, 20,
              (v) => setState(() => _brothers = v), colors.primarySoft),
          _counterRow('Sisters', _sisters, 0, 20,
              (v) => setState(() => _sisters = v), colors.accent),
        ],
      ),
    );
  }

  // ─── Half Siblings Section (NEW — FIXED) ────────────────────
  Widget _buildHalfSiblingsSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Half Siblings',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Paternal (same father)',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.3), fontSize: 10)),
          const SizedBox(height: 8),
          _counterRow(
              'Paternal Half Brothers',
              _halfBrothersFather,
              0,
              20,
              (v) => setState(() => _halfBrothersFather = v),
              colors.primarySoft),
          _counterRow(
              'Paternal Half Sisters',
              _halfSistersFather,
              0,
              20,
              (v) => setState(() => _halfSistersFather = v),
              colors.accent),
          const SizedBox(height: 8),
          Text('Maternal (same mother)',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.3), fontSize: 10)),
          const SizedBox(height: 8),
          _counterRow(
              'Maternal Half Brothers',
              _halfBrothersMother,
              0,
              20,
              (v) => setState(() => _halfBrothersMother = v),
              colors.accent),
          _counterRow(
              'Maternal Half Sisters',
              _halfSistersMother,
              0,
              20,
              (v) => setState(() => _halfSistersMother = v),
              colors.accent),
        ],
      ),
    );
  }

  // ─── Other Section ──────────────────────────────────────────
  Widget _buildOtherSection() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Other Relatives',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _toggleRow('Paternal Uncle', Icons.man_rounded, _hasUncle,
              (v) => setState(() => _hasUncle = v), colors.primarySoft),
        ],
      ),
    );
  }

  // ─── Toggle Row ─────────────────────────────────────────────
  Widget _toggleRow(String label, IconData icon, bool value,
      ValueChanged<bool> onChanged, Color color) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
              icon,
              size: 16,
              color:
                  value ? colors.accent : colors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: value
                          ? colors.textPrimary
                          : colors.textSecondary,
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
                color: value ? color : colors.border,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      color: colors.textPrimary, shape: BoxShape.circle),
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
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: value > 0
                          ? colors.textPrimary
                          : colors.textSecondary,
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
                  color: colors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.remove_rounded,
                  color: colors.textPrimary.withValues(alpha: 0.3), size: 16),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text('$value',
                style: TextStyle(
                    color:
                        value > 0 ? color : colors.textTertiary,
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
    final colors = QibraColors.of(context);
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
                    ? [colors.primarySoft, colors.accent]
                    : [
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2)
                      ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: colors.primarySoft.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate_rounded,
                  color: enabled ? colors.onPrimary : colors.textSecondary, size: 22),
              const SizedBox(width: 10),
              Text('Calculate Shares',
                  style: TextStyle(
                      color: enabled ? colors.onPrimary : colors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              if (!enabled) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_rounded, color: colors.textTertiary, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result Summary ─────────────────────────────────────────
  Widget _buildResultSummary() {
    final colors = QibraColors.of(context);
    final debt = double.tryParse(_debtController.text) ?? 0;
    final wasiyyah = double.tryParse(_wasiyyahController.text) ?? 0;
    final maxW = (_totalEstate - debt) / 3;
    final actualW = wasiyyah > maxW ? maxW : wasiyyah;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [colors.backgroundSecondary, colors.card]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: colors.primarySoft.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('DISTRIBUTION SUMMARY',
              style: TextStyle(
                  color: colors.primarySoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0)),
          const SizedBox(height: 14),
          _summaryRow(
              'Total Estate', _formatAmount(_totalEstate), colors.onPrimary),
          if (debt > 0)
            _summaryRow('Debts Deducted', '- ${_formatAmount(debt)}',
                colors.error),
          if (actualW > 0)
            _summaryRow('Wasiyyah (Will)', '- ${_formatAmount(actualW)}',
                colors.accent),
          const Divider(color: Color(0xFF4A3F6B), height: 20),
          _summaryRow('Net Distributable', _formatAmount(_netEstate),
              colors.primary),
          _summaryRow('Heirs', '${_results.length}', colors.primarySoft),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.5), fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─── Shares List ────────────────────────────────────────────
  Widget _buildSharesList() {
    final colors = QibraColors.of(context);
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
                                style: TextStyle(
                                    color: colors.textPrimary,
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
                              color: colors.textPrimary.withValues(alpha: 0.4),
                              fontSize: 10)),
                      if (r.count > 1)
                        Text('${_formatAmount(r.amount / r.count)} each',
                            style: TextStyle(
                                color: colors.textPrimary.withValues(alpha: 0.3),
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
                                color: colors.textPrimary.withValues(alpha: 0.4),
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
    final colors = QibraColors.of(context);
    if (_results.isEmpty) return const SizedBox.shrink();
    final total = _results.fold<double>(0, (s, r) => s + r.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text('VISUAL BREAKDOWN',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.4),
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
                          color: colors.textPrimary.withValues(alpha: 0.5),
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
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _resetAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded,
                color: colors.textPrimary.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 8),
            Text('Reset All',
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Islamic Note ───────────────────────────────────────────
  Widget _buildIslamicNote() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colors.primarySoft.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 14),
              SizedBox(width: 8),
              Text('Quran Reference',
                  style: TextStyle(
                      color: colors.primarySoft,
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
                color: colors.textPrimary.withValues(alpha: 0.6),
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
                color: colors.textPrimary.withValues(alpha: 0.35),
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
    final colors = QibraColors.light;
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
        ..color = colors.background
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
      ..color = colors.background
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
