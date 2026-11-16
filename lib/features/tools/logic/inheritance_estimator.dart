// lib/features/tools/logic/inheritance_estimator.dart

// ============================================================
// QIBRA AI — INHERITANCE PRE-CHECK (pure logic, Stage 3 extraction)
// Input validation + net-estate arithmetic + the Sharia cap on the
// bequest (wasiyyah ≤ 1/3 of what remains after debts), extracted
// verbatim from InheritanceCalculatorScreen._calculate so it can be
// unit-tested without a widget harness. The share engine itself
// (awrāḍ/farāʾiḍ distribution) remains on the screen for now — see
// the Stage 3 report.
// ============================================================

/// One-line user-facing error (exact strings the screen showed before).
class InheritancePrecheckFailure {
  const InheritancePrecheckFailure(this.message);
  final String message;
}

/// Successful pre-computation inputs for the share engine.
class InheritancePrecheckResult {
  const InheritancePrecheckResult({
    required this.netEstate,
    required this.appliedWasiyyah,
    required this.wasiyyahCapped,
    required this.wasiyyahCap,
  });

  /// estate − debts − wasiyyah(applied). This is what gets distributed.
  final double netEstate;

  /// The wasiyyah actually deducted (min(requested, cap)).
  final double appliedWasiyyah;

  /// True when the requested bequest exceeded 1/3 and was capped.
  final bool wasiyyahCapped;

  /// 1/3 of (estate − debts) — the cap itself, for the notice text.
  final double wasiyyahCap;
}

abstract final class InheritanceEstimator {
  /// Mirrors the screen's validation order exactly so snackbar wording
  /// and precedence are preserved.
  static Object evaluate({
    required double estate,
    required double debts,
    required double wasiyyah,
    required String deceasedGender,
    required bool hasHusband,
    required bool hasWife,
    required bool hasFather,
    required bool hasMother,
    required bool hasGrandfather,
    required bool hasGrandmother,
    required int sons,
    required int daughters,
    required int grandsons,
    required int granddaughters,
    required int brothers,
    required int sisters,
    required int halfBrothersFather,
    required int halfSistersFather,
    required int halfBrothersMother,
    required int halfSistersMother,
    required bool hasUncle,
  }) {
    if (estate <= 0) {
      return const InheritancePrecheckFailure(
          'Please enter total estate value');
    }

    final hasAnyHeir = hasHusband ||
        hasWife ||
        hasFather ||
        hasMother ||
        hasGrandfather ||
        hasGrandmother ||
        sons > 0 ||
        daughters > 0 ||
        grandsons > 0 ||
        granddaughters > 0 ||
        brothers > 0 ||
        sisters > 0 ||
        halfBrothersFather > 0 ||
        halfSistersFather > 0 ||
        halfBrothersMother > 0 ||
        halfSistersMother > 0 ||
        hasUncle;
    if (!hasAnyHeir) {
      return const InheritancePrecheckFailure(
          'Please select at least one heir');
    }

    if (hasHusband && hasWife) {
      return const InheritancePrecheckFailure(
          'Cannot have both husband and wife as heirs — invalid combination');
    }
    if (deceasedGender == 'male' && hasHusband) {
      return const InheritancePrecheckFailure(
          'Deceased is male — husband cannot be an heir');
    }
    if (deceasedGender == 'female' && hasWife) {
      return const InheritancePrecheckFailure(
          'Deceased is female — wife cannot be an heir');
    }

    final afterDebts = estate - debts;
    if (afterDebts <= 0) {
      return const InheritancePrecheckFailure(
          'Debts exceed estate — no inheritance to distribute');
    }

    final cap = afterDebts / 3;
    final applied = wasiyyah > cap ? cap : wasiyyah;

    return InheritancePrecheckResult(
      netEstate: afterDebts - applied,
      appliedWasiyyah: applied,
      wasiyyahCapped: wasiyyah > cap,
      wasiyyahCap: cap,
    );
  }
}
