// lib/features/tools/logic/zakat_calculator.dart

// ============================================================
// QIBRA AI — ZAKAT CALCULATOR (pure logic, Stage 3 extraction)
// Previously inlined in ZakatCalculatorScreen; behavior preserved
// byte-for-byte, now unit-testable.
// ============================================================

/// Which message the UI should show — wording stays in the screen, the
/// semantics live here.
enum ZakatOutcomeKind { emptyInput, belowNisab, due }

/// Immutable result of a zakat evaluation.
class ZakatOutcome {
  const ZakatOutcome({
    required this.totalWealth,
    required this.nisabThreshold,
    required this.zakatAmount,
    required this.isDue,
    required this.kind,
  });

  /// gold + silver + cash + investments + property − debts (never < 0 check
  /// is intentionally NOT applied: the legacy screen reported the raw sum,
  /// including negative, and the UI branch `totalWealth <= 0` handles it).
  final double totalWealth;

  /// 612.36 grams of silver priced at the selected currency's rate.
  final double nisabThreshold;

  /// totalWealth * 2.5% when due, otherwise 0.
  final double zakatAmount;

  final bool isDue;
  final ZakatOutcomeKind kind;
}

/// Cash-valued zakat engine (2.5% above the silver nisab).
abstract final class ZakatCalculator {
  /// 2.5% — one fortieth, the agreed rate for savings/assets zakat.
  static const double rate = 0.025;

  /// Nisab in grams of gold (reference only; app uses the more generous
  /// silver standard for obligations, per Hanafi practice).
  static const double goldNisabGrams = 87.48;

  /// Nisab in grams of silver — 612.36g ≈ 200 dirhams.
  static const double silverNisabGrams = 612.36;

  static double totalWealth({
    required double gold,
    required double silver,
    required double cash,
    required double investments,
    required double property,
    required double debts,
  }) =>
      gold + silver + cash + investments + property - debts;

  static double nisabForSilverPrice(double silverPricePerGram) =>
      silverNisabGrams * silverPricePerGram;

  /// Full evaluation mirroring the legacy screen logic:
  /// - total <= 0            → emptyInput (nothing to compute)
  /// - 0 < total < nisab     → belowNisab, due = false, amount = 0
  /// - total >= nisab        → due, amount = total * 2.5%
  static ZakatOutcome evaluate({
    required double gold,
    required double silver,
    required double cash,
    required double investments,
    required double property,
    required double debts,
    required double silverPricePerGram,
  }) {
    final total = totalWealth(
      gold: gold,
      silver: silver,
      cash: cash,
      investments: investments,
      property: property,
      debts: debts,
    );
    final nisab = nisabForSilverPrice(silverPricePerGram);

    if (total <= 0) {
      return ZakatOutcome(
        totalWealth: total,
        nisabThreshold: nisab,
        zakatAmount: 0,
        isDue: false,
        kind: ZakatOutcomeKind.emptyInput,
      );
    }
    if (total < nisab) {
      return ZakatOutcome(
        totalWealth: total,
        nisabThreshold: nisab,
        zakatAmount: 0,
        isDue: false,
        kind: ZakatOutcomeKind.belowNisab,
      );
    }
    return ZakatOutcome(
      totalWealth: total,
      nisabThreshold: nisab,
      zakatAmount: total * rate,
      isDue: true,
      kind: ZakatOutcomeKind.due,
    );
  }
}
