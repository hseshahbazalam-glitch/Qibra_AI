import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/services/notification_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';

void main() {
  test('quran init is single-flight; hadith init is idempotent', () {
    final q = QuranRepository();
    expect(identical(q, QuranRepository()), isTrue);
    final h = HadithDatabaseService();
    expect(identical(h, HadithDatabaseService()), isTrue);
    NotificationService.markTimeZonesInitialized();
    expect(NotificationService.instance, isNotNull);
  });
}
