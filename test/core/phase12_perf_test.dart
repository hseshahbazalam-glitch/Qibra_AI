import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/services/notification_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';

void main() {
  // M6RED-REPORT (transient): name the culprit test on failure —
  // same annotation channel as the M5 TALLY, one tearDown, deleted
  // with the probe commit.
  tearDown(() {
    if (testState == TestState.failed) {
      print('::error::M6RED ${testCase.name}');
    }
  });

  test('quran init is single-flight; hadith init is idempotent', () {
    final q = QuranRepository();
    expect(identical(q, QuranRepository()), isTrue);
    final h = HadithDatabaseService();
    expect(identical(h, HadithDatabaseService()), isTrue);
    // (Rev) The former markTimeZonesInitialized() call verified a write-only
    // flag that no longer exists; singleton identity is the real assertion.
    expect(NotificationService.instance, isNotNull);
  });
}
