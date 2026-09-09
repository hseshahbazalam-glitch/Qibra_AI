import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/content/word_by_word.dart';
import 'package:qibra_ai/core/location/location_resolver.dart';
import 'package:qibra_ai/core/offline/reachability.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/ai/services/rag_service.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';

void main() {
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
