import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/content/word_by_word.dart';
import 'package:qibra_ai/core/location/location_resolver.dart';
import 'package:qibra_ai/core/offline/reachability.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/ai/domain/rag_service.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';


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
      _m6bad.add('core_phase16_honesty_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase16_honesty_test :: $d :: ${e.toString().split('\n').first}');
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
    print('::error::M6BADEND core_phase16_honesty_test ${_m6bad.length}');
  });

  test('word-by-word unknown is not a meaning', () {
    final glosses = WordByWordResolver.tokenize('بِسْمِ اللَّهِ');
    expect(glosses, isNotEmpty);
    expect(glosses.every((g) => g.isUnknown), isTrue);
    expect(WordByWordResolver.glossFor('بِسْمِ'), 'UNKNOWN');
    expect(WordByWordResolver.glossFor('بِسْمِ'), isNot(equals('meaning')));
  });

  test('hadith book grade is not marketed as Authentic', () {
    expect(HadithGrade.sahih.description.toLowerCase().contains('100%'), isFalse);
    expect(HadithGrade.unknown.label, 'Unknown');
  });

  test('GPS without catalog city stays UNKNOWN', () {
    final far = LocationResolver.fromCoordinates(-80.0, 0.0);
    expect(far.displayName, 'UNKNOWN');
    expect(far.hasNamedCity, isFalse);
  });

  test('unknown reachability is not online', () {
    final unknown = ReachabilityMapper.fromConnectivityLabels(const []);
    expect(unknown.isOnline, isFalse);
    expect(unknown.mayUseNetwork, isFalse);
  });

  test('billing never trusts JSON isPremium', () {
    expect(BillingService.instance.trustPremiumFromJson({'isPremium': true}), isFalse);
    expect(BillingService.instance.storeStatus, StoreStatus.unconfigured);
  });

  test('cached profile offline is not serverValidated', () {
    const profile = CachedProfile(serverValidated: false);
    expect(profile.serverValidated, isFalse);
  });

  test('RAG with empty retrieve refuses', () async {
    final ctx = await RagService.instance.buildContextForQuery('');
    expect(ctx.startsWith('REFUSE:'), isTrue);
  });
}
