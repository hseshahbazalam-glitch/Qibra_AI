// test/quran_audio_stage_test.dart
// ============================================================
// QIBRA AI — AUDIO STAGE UNIT TESTS (pure logic, no device)
// ============================================================
// Covers the honest-core of the tilawat feature: URL builders against
// both CDNs, the global-ayah-number bridge built from the app's OWN
// metadata, the source ladder (local → primary → fallback → failed,
// no silent loops), queue auto-advance incl. end-of-surah stop, the
// download path/size math (0-byte = failure), and the player state
// object's real-data guarantees (no duration until the player reports
// one, progress only when computable).

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/quran/data/audio/tilawat.dart';
import 'package:qibra_ai/features/quran/providers/quran_audio_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('primary URL builder (everyayah.com, SSSAAA.mp3)', () {
    test('first, middle and last ayah of the Quran pad correctly', () {
      expect(Tilawat.primaryUrl(1, 1),
          'https://everyayah.com/data/Alafasy_128kbps/001001.mp3');
      expect(Tilawat.primaryUrl(2, 141),
          'https://everyayah.com/data/Alafasy_128kbps/002141.mp3');
      expect(Tilawat.primaryUrl(114, 6),
          'https://everyayah.com/data/Alafasy_128kbps/114006.mp3');
    });

    test('out-of-range refs build nothing (never a guessed URL)', () {
      expect(Tilawat.primaryUrl(1, 8), isNull); // Al-Fatiha has 7
      expect(Tilawat.primaryUrl(0, 1), isNull);
      expect(Tilawat.primaryUrl(115, 1), isNull);
      expect(Tilawat.primaryUrl(2, 287), isNull); // Al-Baqarah has 286
      expect(Tilawat.primaryUrl(114, 7), isNull);
    });
  });

  group('fallback URL builder (cdn.islamic.network, global number)', () {
    test('first, middle, last global ayahs', () {
      expect(Tilawat.fallbackUrl(1),
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3');
      expect(Tilawat.fallbackUrl(263),
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/263.mp3');
      expect(Tilawat.fallbackUrl(6236),
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6236.mp3');
    });

    test('out-of-range globals build nothing', () {
      expect(Tilawat.fallbackUrl(0), isNull);
      expect(Tilawat.fallbackUrl(6237), isNull);
      expect(Tilawat.fallbackUrl(-5), isNull);
    });
  });

  group('global ayah number from the app\'s own data', () {
    test('prefers bundled numberInQuran when present', () {
      expect(Tilawat.globalAyahNumber(
              surah: 2, ayah: 5, numberInQuran: 110),
          110);
      // Out-of-range bundled values are rejected, not trusted.
      expect(Tilawat.globalAyahNumber(surah: 1, ayah: 1, numberInQuran: 7000),
          1); // falls through to prefix-sum
    });

    test('prefix-sum fallback matches the app metadata table', () {
      expect(Tilawat.globalAyahNumber(
              surah: 1, ayah: 1, numberInQuran: 0),
          1);
      expect(Tilawat.globalAyahNumber(
              surah: 1, ayah: 7, numberInQuran: 0),
          7);
      expect(Tilawat.globalAyahNumber(
              surah: 2, ayah: 1, numberInQuran: 0),
          8); // after Al-Fatiha's 7
      expect(Tilawat.globalAyahNumber(
              surah: 2, ayah: 286, numberInQuran: 0),
          293);
      expect(Tilawat.globalAyahNumber(
              surah: 114, ayah: 6, numberInQuran: 0),
          6236); // the whole Mushaf adds up
      expect(Tilawat.globalAyahNumber(
              surah: 114, ayah: 7, numberInQuran: 0),
          6237); // invalid ayah → above range; callers must validate
      expect(Tilawat.globalAyahNumber(surah: 0, ayah: 1, numberInQuran: 0), 0);
    });

    test('fallback URLs for the extremes only exist inside 1..6236', () {
      final firstGlobal = Tilawat.globalAyahNumber(
          surah: 1, ayah: 1, numberInQuran: 0);
      final lastGlobal = Tilawat.globalAyahNumber(
          surah: 114, ayah: 6, numberInQuran: 0);
      expect(Tilawat.fallbackUrl(firstGlobal), isNotNull);
      expect(Tilawat.fallbackUrl(lastGlobal), isNotNull);
      expect(Tilawat.fallbackUrl(lastGlobal + 1), isNull);
    });
  });

  group('source ladder — exactly one fallback, then honest failure', () {
    test('local missing → primary; primary down → fallback; fallback down '
        '→ failed; failed never advances again (no silent retry loop)', () {
      var a = TilawatAttempt.primary;
      a = Tilawat.advance(a, ok: false);
      expect(a, TilawatAttempt.fallback);
      a = Tilawat.advance(a, ok: false);
      expect(a, TilawatAttempt.failed);
      a = Tilawat.advance(a, ok: false);
      expect(a, TilawatAttempt.failed);
    });

    test('a successful attempt stays; local failure falls to primary', () {
      expect(Tilawat.advance(TilawatAttempt.local, ok: true),
          TilawatAttempt.local);
      expect(Tilawat.advance(TilawatAttempt.local, ok: false),
          TilawatAttempt.primary);
      expect(Tilawat.advance(TilawatAttempt.primary, ok: true),
          TilawatAttempt.primary);
    });

    test('failure copy is the owner-mandated sentence', () {
      expect(Tilawat.offlineFailureMessage,
          'Recitation needs internet or a download');
    });
  });

  group('queue auto-advance', () {
    test('walks the queue and stops at the end of the surah', () {
      expect(Tilawat.nextQueueIndex(0, 3), 1);
      expect(Tilawat.nextQueueIndex(1, 3), 2);
      expect(Tilawat.nextQueueIndex(2, 3), isNull); // stop — no loop
      expect(Tilawat.nextQueueIndex(0, 1), isNull); // single-ayah queue
      expect(Tilawat.nextQueueIndex(-1, 3), isNull);
      expect(Tilawat.nextQueueIndex(5, 3), isNull);
    });
  });

  group('download path manager', () {
    test('paths follow appSupport/tilawat/<qari>/<SSSAAA>.mp3', () {
      expect(Tilawat.qariDirPath('/data/app/support'),
          '/data/app/support/tilawat/ar.alafasy');
      expect(Tilawat.filePath('/data/app/support', 2, 141),
          '/data/app/support/tilawat/ar.alafasy/002141.mp3');
      expect(Tilawat.fileName(114, 6), '114006.mp3');
    });

    test('per-surah file lists come from the app metadata counts', () {
      final fatihah = Tilawat.surahFileNames(1);
      expect(fatihah.length, 7);
      expect(fatihah.first, '001001.mp3');
      expect(fatihah.last, '001007.mp3');
      expect(Tilawat.surahFileNames(2).length, 286);
      expect(Tilawat.surahFileNames(114).length, 6);
      expect(Tilawat.surahFileNames(0), isEmpty);
      expect(Tilawat.surahFileNames(115), isEmpty);
    });

    test('tally sums real bytes; missing and 0-byte never count', () {
      final t = Tilawat.tallySurah([100, null, 0, 250, 3]);
      expect(t.bytes, 353);
      expect(t.present, 3);
      expect(t.total, 5);
      final empty = Tilawat.tallySurah(const []);
      expect(empty.bytes, 0);
      expect(empty.total, 0);
      final none = Tilawat.tallySurah([null, 0, null]);
      expect(none.present, 0);
      expect(none.bytes, 0);
    });

    test('status labels describe only real states; size label is honest', () {
      const none = SurahAudioStatus(checking: false);
      expect(none.label, 'Not downloaded');
      expect(none.noneOnDisk, isTrue);
      expect(none.downloaded, isFalse);

      const dl = SurahAudioStatus(
          checking: false,
          downloading: true,
          done: 3,
          total: 7,
          fileFraction: 0.45);
      expect(dl.label, 'Downloading 3/7 · 45%');

      const done = SurahAudioStatus(
          checking: false, done: 7, total: 7, bytes: 7 * 131072);
      expect(done.downloaded, isTrue);
      expect(done.label, 'Downloaded · 0.9 MB');

      expect(SurahAudioStatus.bytesLabel(0), '0 B');
      expect(SurahAudioStatus.bytesLabel(1023), '1023 B');
      expect(SurahAudioStatus.bytesLabel(1024), '1.0 KB');
      expect(SurahAudioStatus.bytesLabel(1024 * 1024), '1.0 MB');
    });
  });

  group('clock label', () {
    test('m:ss from real durations only', () {
      expect(Tilawat.clockLabel(Duration.zero), '0:00');
      expect(Tilawat.clockLabel(const Duration(seconds: 65)), '1:05');
      expect(Tilawat.clockLabel(const Duration(minutes: 10)), '10:00');
      expect(Tilawat.clockLabel(const Duration(seconds: 3599)), '59:59');
      expect(Tilawat.clockLabel(const Duration(seconds: -4)), '0:00');
    });
  });

  group('player state object — the UI honesty contract', () {
    test('idle means no bar anywhere', () {
      const s = QuranAudioState();
      expect(s.phase, QuranAudioPhase.idle);
      expect(s.active, isFalse);
      expect(s.isPlaying, isFalse);
      expect(s.progress, isNull);
    });

    test('duration stays null until a caller supplies a real one', () {
      const loading =
          QuranAudioState(phase: QuranAudioPhase.loading, buffering: true);
      expect(loading.duration, isNull);
      expect(loading.progress, isNull);
      final withDur = loading.copyWith(
        phase: QuranAudioPhase.playing,
        position: const Duration(seconds: 3),
        duration: const Duration(seconds: 12),
      );
      expect(withDur.progress, 0.25);
      final cleared = withDur.copyWith(clearDuration: true);
      expect(cleared.duration, isNull);
      expect(cleared.progress, isNull);
    });

    test('position beyond unknown-total progress clamps honestly', () {
      final s = const QuranAudioState(
        phase: QuranAudioPhase.playing,
        position: Duration(seconds: 30),
        duration: Duration(seconds: 12),
      );
      expect(s.progress, 1.0);
    });

    test('isCurrent is exact per surah+ayah while active', () {
      const s = QuranAudioState(
          phase: QuranAudioPhase.playing,
          surahNumber: 2,
          ayahNumber: 5,
          surahName: 'x');
      expect(s.isCurrent(2, 5), isTrue);
      expect(s.isCurrent(2, 6), isFalse);
      expect(s.isCurrent(1, 5), isFalse);
      const idle = QuranAudioState();
      expect(idle.isCurrent(2, 5), isFalse);
    });

    test('failure copy lands in the state via copyWith', () {
      const s = QuranAudioState(phase: QuranAudioPhase.playing);
      final failed = s.copyWith(
          phase: QuranAudioPhase.failed,
          error: Tilawat.offlineFailureMessage,
          buffering: false);
      expect(failed.error, 'Recitation needs internet or a download');
      expect(failed.active, isTrue); // bar stays visible with the reason
    });
  });
}
