// lib/features/qibla/providers/qibla_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/qibla_service.dart';

// ============================================================
// QIBLA STATE
// ============================================================

enum QiblaStatus { initial, loading, loaded, error }

class QiblaState {
  final QiblaStatus status;
  final QiblaResult? result;
  final String? errorMessage;
  final double compassHeading; // Live compass heading

  const QiblaState({
    this.status = QiblaStatus.initial,
    this.result,
    this.errorMessage,
    this.compassHeading = 0.0,
  });

  QiblaState copyWith({
    QiblaStatus? status,
    QiblaResult? result,
    String? errorMessage,
    double? compassHeading,
  }) {
    return QiblaState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      compassHeading: compassHeading ?? this.compassHeading,
    );
  }

  // Qibla needle angle = qiblaAngle - (magneticHeading + declination)
  // P0.7: Correct magnetic heading to true north using declination
  double get needleAngle {
    if (result == null) return 0.0;
    final decl = result!.magneticDeclination;
    final trueHeading = compassHeading + decl;
    return result!.qiblaAngle - trueHeading;
  }

  // True heading after declination correction
  double get trueHeading {
    if (result == null) return compassHeading;
    return compassHeading + result!.magneticDeclination;
  }
}

// ============================================================
// QIBLA NOTIFIER
// ============================================================

class QiblaNotifier extends StateNotifier<QiblaState> {
  QiblaNotifier() : super(const QiblaState());

  Future<void> loadQibla() async {
    state = state.copyWith(status: QiblaStatus.loading);

    try {
      final result = await QiblaService.getQiblaDirection();
      state = state.copyWith(
        status: QiblaStatus.loaded,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: QiblaStatus.error,
        errorMessage:
            'Could not determine Qibla direction. Please enable location.',
      );
    }
  }

  void updateCompassHeading(double heading) {
    state = state.copyWith(compassHeading: heading);
  }

  Future<void> refresh() async {
    await loadQibla();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier();
});
