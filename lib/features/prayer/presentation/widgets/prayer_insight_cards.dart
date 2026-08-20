import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class PrayerInsightCards {
  PrayerInsightCards._();

  static Widget tahajjud(
          {required String startsIn, required VoidCallback onTap}) =>
      _Card(
        onTap: onTap,
        colors: const [Color(0xFF34206B), Color(0xFF17122D)],
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.nightlight_round, color: Color(0xFFFFD166)),
              const SizedBox(height: 10),
              const Text('TAHAJJUD COUNTDOWN',
                  style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('Tahajjud',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const Text('قيام الليل',
                  style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontFamily: 'Amiri',
                      fontSize: 15)),
              const SizedBox(height: 12),
              Text(startsIn,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              Text('Available after Isha',
                  style: AppTextStyles.labelXSmall
                      .copyWith(color: Colors.white70)),
            ]),
      );

  static Widget streak(
          {required int days,
          required int completed,
          required VoidCallback onTap}) =>
      _Card(
        onTap: onTap,
        colors: const [Color(0xFF0C3329), Color(0xFF071B17)],
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFFF9F1C)),
                const SizedBox(width: 6),
                Text('PRAYER STREAK',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('$days',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900)),
                const Text(' days', style: TextStyle(color: Colors.white70)),
              ]),
              Text('Keep it up! May Allah accept.',
                  style: AppTextStyles.labelXSmall
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 14),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                      7,
                      (i) => Icon(
                            i < completed
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: i < completed
                                ? const Color(0xFF00E676)
                                : Colors.white24,
                            size: 18,
                          ))),
            ]),
      );

  static Widget progress(
          {required int completed, required VoidCallback onTap}) =>
      _Card(
        onTap: onTap,
        colors: const [Color(0xFF083E31), Color(0xFF06261F)],
        child: Row(children: [
          SizedBox(
              width: 68,
              height: 68,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                    value: (completed / 5).clamp(0, 1).toDouble(),
                    strokeWidth: 6,
                    color: const Color(0xFF00E676),
                    backgroundColor: Colors.white12),
                Text('$completed/5',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ])),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text("TODAY'S PROGRESS",
                    style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$completed of 5 prayers completed',
                    style:
                        AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ])),
        ]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.colors, required this.child, required this.onTap});
  final List<Color> colors;
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 142),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      );
}
