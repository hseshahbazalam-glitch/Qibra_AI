// lib/features/tools/screens/dhikr_counter_screen.dart
// Legacy class name. Home, More, /tasbih, and /tools/dhikr share TasbihScreen
// and tasbihProvider so there is one dhikr counter.

import 'package:flutter/material.dart';

import '../../tasbih/presentation/tasbih_screen.dart';

class DhikrCounterScreen extends StatelessWidget {
  const DhikrCounterScreen({super.key});

  @override
  Widget build(BuildContext context) => const TasbihScreen();
}
