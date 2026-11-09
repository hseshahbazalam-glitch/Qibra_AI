// Device-log pass 2 — QibraCard ink surface. The widget-level contract
// the CPH2573 device run demanded: a ListTile inside a NON-tappable
// QibraCard must not trip Flutter's ink-visibility assertion, and a
// tappable QibraCard must actually show its splash ON the colored
// surface (color on the Material, not on a Container above it).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/shared/widgets/qibra_ui.dart';

/// Slice of the file covering ONLY the QibraCard class.
String qibracardSource() {
  final ui = File('lib/shared/widgets/qibra_ui.dart').readAsStringSync();
  final a = ui.indexOf('class QibraCard extends');
  final b = ui.indexOf('class QibraSectionHeader extends');
  expect(a, greaterThan(0));
  expect(b, greaterThan(a));
  return ui.substring(a, b);
}

Widget host(Widget child, {double width = 360}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('core_qibracard_ink_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('core_qibracard_ink_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
    print('::error::M6BADEND core_qibracard_ink_test ${_m6bad.length}');
  });

  test('source guard: both paths fixed in one widget, no transparency card',
      () {
    final src = qibracardSource();
    expect(src, contains('color: filled'));
    expect(
      src,
      contains('Material(\n        color: filled ? colors.primarySoft : colors.card,'),
    );
    expect(src.contains('MaterialType.transparency'), isFalse);
    expect(src.contains('width: double.infinity'), isTrue); // parity pin
  });

  testWidgets('non-tappable QibraCard + ListTile: no ink assertion',
      (tester) async {
    await tester.pumpWidget(host(QibraCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('row'),
        onTap: () {},
      ),
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tappable QibraCard: tap works, ink lands on a colored Material',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(QibraCard(
      onTap: () => taps++,
      child: const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('row'),
      ),
    )));
    await tester.tap(find.byType(QibraCard));
    await tester.pump(); // splash begins — no exception during paint
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    final material = tester.widget<Material>(
      find.ancestor(of: find.byType(ListTile), matching: find.byType(Material)).first,
    );
    expect(material.color, isNotNull);
    expect(material.color, isNot(Colors.transparent));
    expect(material.color, QibraColors.light.card); // the visible surface
    expect(material.clipBehavior, Clip.antiAlias);
  });

  testWidgets('320dp: padded tile keeps the card overflow-free',
      (tester) async {
    await tester.pumpWidget(host(
      QibraCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'A deliberately long translation line that will ellipsize',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        ),
      ),
      width: 320,
    ));
    expect(tester.takeException(), isNull);
  });
}
