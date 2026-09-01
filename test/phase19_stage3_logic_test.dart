// Stage 3 — logic tests: extracted pure calculators (zakat, inheritance
// pre-check), the shared SearchNormalizer, the real prayer engine +
// astronomical service sanity checks, and structural guards for the
// part-file splits. All of these run on the Dart VM; no widget harness.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/prayer/data/services/next_prayer_engine.dart';
import 'package:qibra_ai/features/prayer/data/services/prayer_calculation_service.dart';
import 'package:qibra_ai/features/tools/logic/inheritance_estimator.dart';
import 'package:qibra_ai/features/tools/logic/zakat_calculator.dart';

NamedPrayerInstant _p(String n, int h, int m) => NamedPrayerInstant(
      name: n,
      time: DateTime(2026, 1, 15, h, m),
    );

void main() {
  group('SearchNormalizer', () {
    test('Arabic query without tashkeel matches tashkeel text', () {
      const text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      expect(SearchNormalizer.contains(text, 'الله'), isTrue);
      expect(SearchNormalizer.contains(text, 'الرحمن'), isTrue);
      expect(SearchNormalizer.contains(text, 'رحيم'), isTrue);
    });

    test('hamza + ta marbuta folding', () {
      expect(SearchNormalizer.contains('قُلْ هُوَ ٱللَّهُ', 'الله'), isTrue);
      expect(SearchNormalizer.contains('مَكة', 'مكه'), isTrue);
      expect(SearchNormalizer.contains('الصلاة', 'الصلاه'), isTrue);
      expect(SearchNormalizer.contains('إنسان', 'انسان'), isTrue);
    });

    test('tatweel is ignored', () {
      expect(SearchNormalizer.contains('قــرآن', 'قرآن'), isTrue);
      expect(SearchNormalizer.contains('قرآن', 'قــرآن'), isTrue);
    });

    test('Latin is case-insensitive and whitespace-collapsed', () {
      expect(SearchNormalizer.contains('Qul  Huwa Allahu Ahad', 'qul huwa'),
          isTrue);
      expect(SearchNormalizer.contains('AL-Ikhlas', 'al-ikhlas'), isTrue);
    });

    test('match spans are in ORIGINAL coordinates (highlight-safe)', () {
      const text = 'وَاللَّهُ بِكُلِّ شَيْءٍ عَلِيمٌ';
      final m = SearchNormalizer.firstMatch(text, 'الله')!;
      expect(m.start, greaterThanOrEqualTo(0));
      expect(m.end, lessThanOrEqualTo(text.length));
      // The span must actually contain the matched word's letters.
      final slice = text.substring(m.start, m.end);
      expect(SearchNormalizer.foldQuery(slice), contains('الله'));
    });

    test('allMatches finds every non-overlapping occurrence', () {
      const text = 'الله أكبر، الله أحد';
      expect(SearchNormalizer.allMatches(text, 'الله').length, 2);
      expect(SearchNormalizer.allMatches(text, 'لاإله').isEmpty, isTrue);
    });

    test('empty query never matches', () {
      expect(SearchNormalizer.firstMatch('abc', '   '), isNull);
      expect(SearchNormalizer.allMatches('abc', ''), isEmpty);
    });
  });

  group('ZakatCalculator', () {
    const silverPrice = 280.0; // PKR/g default
    final nisab = 612.36 * silverPrice;

    test('totals subtract debts', () {
      expect(
          ZakatCalculator.totalWealth(
              gold: 10000,
              silver: 5000,
              cash: 20000,
              investments: 15000,
              property: 50000,
              debts: 30000),
          70000);
    });

    test('below nisab → not due', () {
      final o = ZakatCalculator.evaluate(
        gold: 0,
        silver: 0,
        cash: nisab - 1,
        investments: 0,
        property: 0,
        debts: 0,
        silverPricePerGram: silverPrice,
      );
      expect(o.kind, ZakatOutcomeKind.belowNisab);
      expect(o.isDue, isFalse);
      expect(o.zakatAmount, 0);
    });

    test('at/above nisab → 2.5% of full wealth', () {
      final o = ZakatCalculator.evaluate(
        gold: 0,
        silver: 0,
        cash: nisab,
        investments: 0,
        property: 0,
        debts: 0,
        silverPricePerGram: silverPrice,
      );
      expect(o.isDue, isTrue);
      expect(o.zakatAmount, closeTo(nisab * 0.025, 1e-9));
      expect(o.nisabThreshold, closeTo(nisab, 1e-9));
    });

    test('debts pushing total ≤ 0 → emptyInput semantics', () {
      final o = ZakatCalculator.evaluate(
        gold: 0,
        silver: 0,
        cash: 100,
        investments: 0,
        property: 0,
        debts: 500,
        silverPricePerGram: silverPrice,
      );
      expect(o.kind, ZakatOutcomeKind.emptyInput);
      expect(o.isDue, isFalse);
      expect(o.zakatAmount, 0);
    });

    test('constants match the legacy screen values', () {
      expect(ZakatCalculator.rate, 0.025);
      expect(ZakatCalculator.silverNisabGrams, 612.36);
      expect(ZakatCalculator.goldNisabGrams, 87.48);
    });
  });

  group('InheritanceEstimator', () {
    InheritancePrecheckResult ok({
      double estate = 300000,
      double debts = 0,
      double wasiyyah = 0,
      String gender = 'male',
      bool hasFather = true,
    }) {
      final r = InheritanceEstimator.evaluate(
        estate: estate,
        debts: debts,
        wasiyyah: wasiyyah,
        deceasedGender: gender,
        hasHusband: false,
        hasWife: gender == 'female',
        hasFather: hasFather,
        hasMother: false,
        hasGrandfather: false,
        hasGrandmother: false,
        sons: 0,
        daughters: 0,
        grandsons: 0,
        granddaughters: 0,
        brothers: 0,
        sisters: 0,
        halfBrothersFather: 0,
        halfSistersFather: 0,
        halfBrothersMother: 0,
        halfSistersMother: 0,
        hasUncle: false,
      );
      expect(r, isA<InheritancePrecheckResult>());
      return r as InheritancePrecheckResult;
    }

    test('rejects zero estate first, then missing heirs', () {
      final r = InheritanceEstimator.evaluate(
        estate: 0,
        debts: 0,
        wasiyyah: 0,
        deceasedGender: 'male',
        hasHusband: false,
        hasWife: false,
        hasFather: false,
        hasMother: false,
        hasGrandfather: false,
        hasGrandmother: false,
        sons: 0,
        daughters: 0,
        grandsons: 0,
        granddaughters: 0,
        brothers: 0,
        sisters: 0,
        halfBrothersFather: 0,
        halfSistersFather: 0,
        halfBrothersMother: 0,
        halfSistersMother: 0,
        hasUncle: false,
      );
      expect((r as InheritancePrecheckFailure).message,
          'Please enter total estate value');
    });

    test('spouse + gender mismatches carry the exact wording', () {
      final r1 = InheritanceEstimator.evaluate(
        estate: 100,
        debts: 0,
        wasiyyah: 0,
        deceasedGender: 'male',
        hasHusband: true,
        hasWife: false,
        hasFather: true,
        hasMother: false,
        hasGrandfather: false,
        hasGrandmother: false,
        sons: 0,
        daughters: 0,
        grandsons: 0,
        granddaughters: 0,
        brothers: 0,
        sisters: 0,
        halfBrothersFather: 0,
        halfSistersFather: 0,
        halfBrothersMother: 0,
        halfSistersMother: 0,
        hasUncle: false,
      );
      expect((r1 as InheritancePrecheckFailure).message,
          'Deceased is male — husband cannot be an heir');
    });

    test('wasiyyah is capped at 1/3 of post-debt estate', () {
      final r = ok(estate: 300000, wasiyyah: 200000);
      expect(r.wasiyyahCapped, isTrue);
      expect(r.wasiyyahCap, 100000);
      expect(r.appliedWasiyyah, 100000);
      expect(r.netEstate, 200000);
    });

    test('uncapped wasiyyah is subtracted whole', () {
      final r = ok(estate: 300000, wasiyyah: 50000);
      expect(r.wasiyyahCapped, isFalse);
      expect(r.netEstate, 250000);
    });

    test('debts exceeding the estate block distribution', () {
      final r = InheritanceEstimator.evaluate(
        estate: 1000,
        debts: 1500,
        wasiyyah: 0,
        deceasedGender: 'male',
        hasHusband: false,
        hasWife: true,
        hasFather: true,
        hasMother: false,
        hasGrandfather: false,
        hasGrandmother: false,
        sons: 0,
        daughters: 0,
        grandsons: 0,
        granddaughters: 0,
        brothers: 0,
        sisters: 0,
        halfBrothersFather: 0,
        halfSistersFather: 0,
        halfBrothersMother: 0,
        halfSistersMother: 0,
        hasUncle: false,
      );
      expect((r as InheritancePrecheckFailure).message,
          'Debts exceed estate — no inheritance to distribute');
    });
  });

  group('NextPrayerEngine', () {
    final today = [
      _p('Fajr', 5, 10),
      _p('Sunrise', 6, 40),
      _p('Dhuhr', 12, 20),
      _p('Asr', 15, 40),
      _p('Maghrib', 18, 10),
      _p('Isha', 19, 40),
    ];
    final tomorrowFajr = _p('Fajr', 5, 12).time.add(const Duration(days: 1));

    test('next() skips non-obligatory (Sunrise never wins)', () {
      final now = DateTime(2026, 1, 15, 5, 30);
      final r = NextPrayerEngine.next(now: now, today: today)!;
      expect(r.name, 'Dhuhr');
      expect(r.isTomorrow, isFalse);
    });

    test('after Isha wraps to tomorrow Fajr with positive countdown', () {
      final now = DateTime(2026, 1, 15, 22, 0);
      final r = NextPrayerEngine.next(
        now: now,
        today: today,
        tomorrowFajr: NamedPrayerInstant(name: 'Fajr', time: tomorrowFajr),
      )!;
      expect(r.name, 'Fajr');
      expect(r.isTomorrow, isTrue);
      expect(r.countdown, const Duration(hours: 7, minutes: 12));
    });

    test('current() is null before Fajr and after Isha', () {
      expect(NextPrayerEngine.current(now: DateTime(2026, 1, 15, 3, 0), today: today),
          isNull);
      expect(NextPrayerEngine.current(now: DateTime(2026, 1, 15, 23, 30), today: today),
          isNull);
    });

    test('current() during a window returns that prayer; Sunrise is not current', () {
      expect(NextPrayerEngine.current(now: DateTime(2026, 1, 15, 13, 0), today: today)!.name,
          'Dhuhr');
      expect(NextPrayerEngine.current(now: DateTime(2026, 1, 15, 6, 0), today: today)!.name,
          'Fajr'); // between Fajr and Sunrise
    });
  });

  group('PrayerCalculationService (astronomical sanity)', () {
    final svc = PrayerCalculationService();
    final makkah = const PrayerLocation(
        latitude: 21.4225, longitude: 39.8262, city: 'Makkah', country: 'SA');
    final london = const PrayerLocation(
        latitude: 51.5074, longitude: -0.1278, city: 'London', country: 'UK');

    DailyPrayerTimes timesAt(PrayerLocation loc, DateTime date,
            {double offset = 3.0, AsrMethod asr = AsrMethod.standard}) =>
        svc.calculatePrayerTimes(
          date: date,
          location: loc,
          method: CalculationMethod.ummAlQura,
          asrMethod: asr,
          explicitTimezoneOffset: offset,
        );

    test('ordering: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha', () {
      final d = timesAt(makkah, DateTime(2026, 1, 15));
      final f = d.fajr.time,
          sr = d.sunrise.time,
          dh = d.dhuhr.time,
          as = d.asr.time,
          mg = d.maghrib.time,
          isha = d.isha.time;
      expect(sr.isAfter(f), isTrue);
      expect(dh.isAfter(sr), isTrue);
      expect(as.isAfter(dh), isTrue);
      expect(mg.isAfter(as), isTrue);
      expect(isha.isAfter(mg), isTrue);
    });

    test('Hanafi Asr is later than Standard Asr', () {
      final std = timesAt(makkah, DateTime(2026, 6, 21));
      final hanafi = timesAt(makkah, DateTime(2026, 6, 21),
          asr: AsrMethod.hanafi);
      expect(hanafi.asr.time.isAfter(std.asr.time), isTrue);
    });

    test('summer daylight is longer than winter in the northern hemisphere',
        () {
      final winter = timesAt(london, DateTime(2026, 1, 15), offset: 0.0);
      final summer = timesAt(london, DateTime(2026, 6, 21), offset: 1.0);
      Duration dayLight(DailyPrayerTimes d) =>
          d.maghrib.time.difference(d.fajr.time);
      expect(dayLight(summer), greaterThan(dayLight(winter)));
    });

    test('Dhuhr sits near solar noon for Makkah (zone +3)', () {
      final d = timesAt(makkah, DateTime(2026, 3, 20));
      final noonMinutes =
          d.dhuhr.time.hour * 60 + d.dhuhr.time.minute; // zone local noon = 720
      expect((noonMinutes - 720).abs(), lessThan(45));
    });

    test('qibla bearing matches published great-circle values (±2°)', () {
      final dubai = const PrayerLocation(
          latitude: 25.2048, longitude: 55.2708, city: 'Dubai', country: 'AE');
      final nyc = const PrayerLocation(
          latitude: 40.7128, longitude: -74.0060, city: 'NYC', country: 'US');
      expect(svc.calculateQiblaDirection(dubai), closeTo(244.9, 2.0));
      expect(svc.calculateQiblaDirection(nyc), closeTo(58.5, 2.0));
      expect(svc.calculateQiblaDirection(london), closeTo(119.0, 2.0));
    });

    test('great-circle distances to the Kaaba match published values (±2%)',
        () {
      final dubai = const PrayerLocation(
          latitude: 25.2048, longitude: 55.2708, city: 'Dubai', country: 'AE');
      final londonLoc = const PrayerLocation(
          latitude: 51.5074, longitude: -0.1278, city: 'London', country: 'UK');
      expect(svc.calculateDistanceToKaaba(dubai), closeTo(1630, 1630 * 0.025));
      expect(svc.calculateDistanceToKaaba(londonLoc), closeTo(4790, 4790 * 0.02));
      expect(svc.calculateDistanceToKaaba(makkah), lessThan(60));
    });

    test('country detection returns the published authority per country', () {
      expect(svc.detectMethodByCountry('PK'), CalculationMethod.karachi);
      expect(svc.detectMethodByCountry('US'), CalculationMethod.islamicSociety);
      expect(svc.detectMethodByCountry('SA'), CalculationMethod.ummAlQura);
      expect(svc.detectMethodByCountry(null),
          CalculationMethod.muslimWorldLeague);
    });
  });

  group('Stage-3 structural guards (part-file splits)', () {
    const pairs = {
      'lib/features/tasbih/presentation/tasbih_screen.dart':
          'tasbih_screen.detail.dart',
      'lib/features/settings/presentation/profile_setup_screen.dart':
          'profile_setup_screen.form.dart',
      'lib/features/tools/screens/inheritance_calculator_screen.dart':
          'inheritance_calculator_screen.results.dart',
      'lib/features/tools/screens/asma_ul_husna_screen.dart':
          'asma_ul_husna_screen.learn.dart',
    };

    test('every parent declares exactly one part; every part joins back', () {
      pairs.forEach((parent, part) {
        final psrc = File(parent).readAsStringSync();
        expect(RegExp("part '$part';").hasMatch(psrc), isTrue, reason: parent);
        final file =
            File('${parent.substring(0, parent.lastIndexOf('/'))}/$part');
        expect(file.existsSync(), isTrue, reason: part);
        expect(file.readAsStringSync().contains("part of '${parent.split('/').last}';"),
            isTrue,
            reason: '$part must be part of ${parent.split('/').last}');
      });
    });

    test('the six touched screens stay emoji-free and weather-free', () {
      final emoji =
          RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
      for (final f in [
        ...pairs.keys,
        ...pairs.keys.map((p) =>
            '${p.substring(0, p.lastIndexOf('/'))}/${pairs[p]}'),
        'lib/features/tools/logic/zakat_calculator.dart',
        'lib/features/tools/logic/inheritance_estimator.dart',
      ]) {
        final src = File(f).readAsStringSync();
        expect(emoji.hasMatch(src), isFalse, reason: f);
      }
      for (final f in pairs.keys) {
        expect(RegExp(r'[Ww]eather').hasMatch(File(f).readAsStringSync()),
            isFalse,
            reason: f);
      }
    });

    test('profile_setup lost every legacy emerald-skin hex', () {
      final src =
          File('lib/features/settings/presentation/profile_setup_screen.dart')
              .readAsStringSync();
      for (final hex in [
        '0xFF19312C',
        '0xFF123F36',
        '0xFFF5F3EC',
        '0xFFEEF1EA',
        '0xFFC6A15B'
      ]) {
        expect(src.contains(hex), isFalse, reason: hex);
      }
      expect(src.contains('🇵🇰'), isFalse); // flag data removed
    });

    test('screens delegate to the pure logic files', () {
      expect(
          File('lib/features/tools/screens/zakat_calculator_screen.dart')
              .readAsStringSync()
              .contains('ZakatCalculator.evaluate'),
          isTrue);
      expect(
          File('lib/features/tools/screens/inheritance_calculator_screen.dart')
              .readAsStringSync()
              .contains('InheritanceEstimator.evaluate'),
          isTrue);
      expect(
          File('lib/features/quran/presentation/quran_search_screen.dart')
              .readAsStringSync()
              .contains('SearchNormalizer.allMatches'),
          isTrue);
    });

    test('every relative import/part directive in lib/ resolves on disk', () {
      // Regression guard for the Stage-3 device-find: a relative import
      // with the wrong number of ../ silently passes bracket sweeps but
      // kills `flutter analyze`.
      final broken = <String>[];
      final importRe = RegExp(r"import '(\.{1,2}/[^']+\.dart)'");
      final partRe = RegExp(r"part '([^'/][^']*\.dart)'");
      String resolve(String dir, String rel) {
        final segs = <String>[];
        for (final s in [...dir.split('/'), ...rel.split('/')]) {
          if (s == '..') {
            if (segs.isNotEmpty) segs.removeLast();
          } else if (s != '.' && s.isNotEmpty) {
            segs.add(s);
          }
        }
        return segs.join('/');
      }

      for (final f
          in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        final dir = File(f.path).parent.path;
        for (final m in importRe.allMatches(src)) {
          final t = resolve(dir, m.group(1)!);
          if (!File(t).existsSync()) {
            broken.add('${f.path} -> ${m.group(1)}');
          }
        }
        for (final m in partRe.allMatches(src)) {
          final p = m.group(1)!;
          if (!File(resolve(dir, p)).existsSync()) {
            broken.add('${f.path} part->$p');
          }
        }
      }
      expect(broken, isEmpty, reason: 'unresolvable relative imports/parts');
    });
  });
}
