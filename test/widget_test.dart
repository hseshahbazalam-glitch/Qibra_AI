// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/main.dart';

void main() {
  testWidgets('QIBRA AI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QibraApp());
    expect(find.byType(QibraApp), findsOneWidget);
  });
}
