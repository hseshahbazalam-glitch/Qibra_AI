import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ye add karo
import 'package:qibra_ai/main.dart';

void main() {
  testWidgets('QIBRA AI smoke test', (WidgetTester tester) async {
    // Bas yahan ProviderScope wrap karna hai
    await tester.pumpWidget(
      const ProviderScope(
        child: QibraApp(),
      ),
    );

    // Verify karo ki app load hua
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
