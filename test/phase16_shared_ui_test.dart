import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/design_system/app_theme.dart';
import 'package:qibra_ai/shared/widgets/qibra_ui.dart';

void main() {
  testWidgets('Qibra icon button exposes a 48dp target', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: QibraIconButton(icon: Icons.close, onTap: () {})),
    ));
    final size = tester.getSize(find.byType(QibraIconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
