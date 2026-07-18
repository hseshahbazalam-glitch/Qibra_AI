// lib/features/tasbih/providers/tasbih_provider.dart

// ============================================================
// QIBRA AI — TASBIH PROVIDER
// Version: 1.0.0
// Description: Digital Tasbih state management with persistence.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// DHIKR MODEL
// ============================================================

class Dhikr {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int defaultTarget;

  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.defaultTarget,
  });
}

// ============================================================
// PREDEFINED DHIKRS
// ============================================================

class Dhikrs {
  static const Dhikr subhanAllah = Dhikr(
    id: 'subhan_allah',
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'SubhanAllah',
    translation: 'Glory be to Allah',
    defaultTarget: 33,
  );

  static const Dhikr alhamdulillah = Dhikr(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    translation: 'Praise be to Allah',
    defaultTarget: 33,
  );

  static const Dhikr allahuAkbar = Dhikr(
    id: 'allahu_akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    translation: 'Allah is Greatest',
    defaultTarget: 34,
  );

  static const Dhikr laIlahaIllallah = Dhikr(
    id: 'la_ilaha_illallah',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    transliteration: 'La ilaha illa Allah',
    translation: 'There is no god but Allah',
    defaultTarget: 100,
  );

  static const Dhikr astaghfirullah = Dhikr(
    id: 'astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    transliteration: 'Astaghfirullah',
    translation: 'I seek forgiveness from Allah',
    defaultTarget: 100,
  );

  static const Dhikr salawat = Dhikr(
    id: 'salawat',
    arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
    transliteration: 'Allahumma Salli Ala Muhammad',
    translation: 'O Allah, send prayers upon Muhammad',
    defaultTarget: 100,
  );

  static const List<Dhikr> all = [
    subhanAllah,
    alhamdulillah,
    allahuAkbar,
    laIlahaIllallah,
    astaghfirullah,
    salawat,
  ];
}

// ============================================================
// TASBIH STATE
// ============================================================

class TasbihState {
  final Dhikr currentDhikr;
  final int count;
  final int target;
  final int totalCount; // Lifetime total
  final bool vibrationEnabled;
  final bool soundEnabled;

  const TasbihState({
    this.currentDhikr = Dhikrs.subhanAllah,
    this.count = 0,
    this.target = 33,
    this.totalCount = 0,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
  });

  double get progress {
    if (target == 0) return 0.0;
    return (count / target).clamp(0.0, 1.0);
  }

  int get remaining => (target - count).clamp(0, target);
  bool get isComplete => count >= target;
  int get rounds => count ~/ target;

  TasbihState copyWith({
    Dhikr? currentDhikr,
    int? count,
    int? target,
    int? totalCount,
    bool? vibrationEnabled,
    bool? soundEnabled,
  }) {
    return TasbihState(
      currentDhikr: currentDhikr ?? this.currentDhikr,
      count: count ?? this.count,
      target: target ?? this.target,
      totalCount: totalCount ?? this.totalCount,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

// ============================================================
// TASBIH NOTIFIER
// ============================================================

class TasbihNotifier extends StateNotifier<TasbihState> {
  TasbihNotifier() : super(const TasbihState()) {
    _loadPersistedData();
  }

  static const String _keyTotalCount = 'tasbih_total_count';
  static const String _keyLastDhikr = 'tasbih_last_dhikr';
  static const String _keyVibration = 'tasbih_vibration';

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final totalCount = prefs.getInt(_keyTotalCount) ?? 0;
      final lastDhikrId =
          prefs.getString(_keyLastDhikr) ?? Dhikrs.subhanAllah.id;
      final vibration = prefs.getBool(_keyVibration) ?? true;

      final dhikr = Dhikrs.all.firstWhere(
        (d) => d.id == lastDhikrId,
        orElse: () => Dhikrs.subhanAllah,
      );

      state = state.copyWith(
        currentDhikr: dhikr,
        target: dhikr.defaultTarget,
        totalCount: totalCount,
        vibrationEnabled: vibration,
      );
    } catch (_) {}
  }

  Future<void> _saveTotalCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalCount, state.totalCount);
    } catch (_) {}
  }

  Future<void> _saveDhikr(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastDhikr, id);
    } catch (_) {}
  }

  Future<void> _saveVibration(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibration, enabled);
    } catch (_) {}
  }

  /// Increment counter
  void increment() {
    state = state.copyWith(
      count: state.count + 1,
      totalCount: state.totalCount + 1,
    );
    _saveTotalCount();
  }

  /// Reset current count (keep total)
  void reset() {
    state = state.copyWith(count: 0);
  }

  /// Reset everything including total
  void resetAll() {
    state = state.copyWith(count: 0, totalCount: 0);
    _saveTotalCount();
  }

  /// Change current dhikr
  void setDhikr(Dhikr dhikr) {
    state = state.copyWith(
      currentDhikr: dhikr,
      target: dhikr.defaultTarget,
      count: 0,
    );
    _saveDhikr(dhikr.id);
  }

  /// Set custom target
  void setTarget(int target) {
    if (target < 1) return;
    state = state.copyWith(target: target);
  }

  /// Toggle vibration
  void toggleVibration() {
    final newValue = !state.vibrationEnabled;
    state = state.copyWith(vibrationEnabled: newValue);
    _saveVibration(newValue);
  }
}

// ============================================================
// PROVIDER
// ============================================================

final tasbihProvider =
    StateNotifierProvider<TasbihNotifier, TasbihState>((ref) {
  return TasbihNotifier();
});
