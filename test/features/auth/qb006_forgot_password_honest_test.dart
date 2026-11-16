// test/features/auth/qb006_forgot_password_honest_test.dart
// ============================================================
// QB-006 (G2-D, workflows-free rebuild) — the forgot-password screen stops
// pretending it can send email.
//
// WHAT WAS ON SCREEN BEFORE THIS PASS (925 lines, lib/features/auth/
// presentation/forgot_password_screen.dart): an email field, a validator, a
// "Send reset link" button that ran `await Future.delayed(Duration(seconds: 2))`
// labelled `// Simulate API call`, a success state with its own elasticOut
// animation and a heavy-impact haptic, and an "Open Email App" button whose
// only action was a SnackBar. The backend has no recovery route of any kind:
// `grep -rniE "forgot|reset_password|password_reset|/reset" backend/app/` matches
// nothing (exit 1), and routers/auth.py mounts only POST /register, /login,
// /refresh, /logout, /logout-all plus GET /me, /sessions. The standing wall says
// there is no email system. So the screen's whole job was to fake a
// capability, and its "error state" was unreachable by construction — a catch
// around a Future.delayed.
//
// WHAT SHIPS INSTEAD: the truth, plus only the exits that exist. No field, no
// loading state, no success animation, no haptic theatre, no email-app button.
// Two real routes are offered as the real exits — sign in with the current
// password, or create a new account — as `context.go` on routes the router
// actually mounts (AppRoutes.login, AppRoutes.register). Three call sites,
// because the shared AuthHeader's back chevron also goes to login.
//
// The 9 tests, and which are expected to be RED before the change:
//   1. the fake flow is gone from the source .................. red
//   2. the honest copy renders, byte-exactly .................. red
//   3. no input field of any kind exists ...................... red
//   4. the two real exits, and no third ........................ red
//   5. all ten new AppStrings getters are real in en/ar/ur .... red
//   6. the invented "Open email app" getter stays deleted ...... red
//   7. raw-chrome census on this file, line-wise AND cross-line  red
//   8. it rides the shared auth chrome (AuthButton, 48dp+) .... red
//   9. CONTROLS (green before and after, so a reviewer can see the file is not
//      merely failing on demand): every Icons.* in the screen resolves against
//      the battery's own metadata, zero raw Color(0x…), zero emoji.
//
// RED EVIDENCE: written against `a3f9ebf` in a sandbox with no Dart/Flutter SDK
// — CI is the only compiler. This file is committed ALONE, so the run it produces
// is the pass's test-first red; the run id and the per-test Expected:/Actual:
// blocks are recorded in docs/G2_PASS_REPORT.md § QB-006. Test 9 is deliberately
// true on both trees (see above); the other eight are the change's specification.
//
// Conventions copied from the family: source pins through
// test/support/source_guards.dart (comments stripped, so a `// Simulate API
// call` in a doc comment cannot satisfy or sabotage a pin), real widget renders
// inside ProviderScope + MaterialApp + AppStringsScope, and every number
// measured rather than asserted from memory.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/auth/presentation/forgot_password_screen.dart';

import '../../support/source_guards.dart';

const String _screen =
    'lib/features/auth/presentation/forgot_password_screen.dart';
const String _strings = 'lib/core/l10n/app_strings.dart';
const String _icons = 'scripts/data/flutter_icons_stable.txt';

/// The copy this pass ships, as one table: getter, EN, AR, UR. Test 2 finds the
/// English strings in the rendered tree; test 5 checks every row against
/// `app_strings.dart` byte-for-byte. One table for both, so the render check and
/// the declaration check cannot drift into certifying different sentences.
const List<List<String>> _copy = [
  [
    'forgotEyebrow',
    'Password recovery',
    'استعادة كلمة المرور',
    'پاسورڈ کی بحالی',
  ],
  [
    'forgotUnavailableHeadline',
    'Not available in this build',
    'غير متاحة في هذا الإصدار',
    'اس بلڈ میں دستیاب نہیں',
  ],
  [
    'forgotUnavailableBody',
    'Qibra AI has no email service connected, so this app cannot send a password reset link.',
    'لا يملك التطبيق خدمة بريد إلكتروني موصولة، لذلك لا يمكنه إرسال رابط إعادة تعيين كلمة المرور.',
    'ایپ سے کوئی ای میل سروس جڑی ہوئی نہیں، اس لیے یہ پاسورڈ دوبارہ ترتیب دینے کا لنک نہیں بھیج سکتا۔',
  ],
  [
    'forgotNothingSentLabel',
    'Nothing was sent',
    'لم يُرسل شيء',
    'کچھ بھی نہیں بھیجا گیا',
  ],
  [
    'forgotNothingSentBody',
    'No reset request was made and no message is on its way. Your password is unchanged.',
    'لم تُطلب أي إعادة تعيين، ولا توجد رسالة في الطريق. كلمة مرورك لم تتغير.',
    'کوئی دوبارہ ترتیب کی درخواست نہیں کی گئی اور کوئی پیغام راستے میں نہیں۔ آپ کا پاسورڈ تبدیل نہیں ہوا۔',
  ],
  [
    'forgotOptionsLabel',
    'What you can do',
    'ما يمكنك فعله',
    'آپ کیا کر سکتے ہیں',
  ],
  [
    'forgotOptionSignInHint',
    'If you remember your password, sign in as usual — nothing needs resetting.',
    'إذا كنت تذكر كلمة المرور فسجّل الدخول كالمعتاد — لا حاجة لأي إعادة تعيين.',
    'اگر آپ پاسورڈ یاد رکھتے ہیں تو معمول کے مطابق سائن ان کریں — کسی دوبارہ ترتیب کی ضرورت نہیں۔',
  ],
  [
    'forgotOptionRegisterHint',
    'If you cannot sign in, create a new account and set a fresh password for it.',
    'وإن لم تتمكن من تسجيل الدخول فأنشئ حسابًا جديدًا واختر له كلمة مرور جديدة.',
    'اگر سائن ان نہیں ہو سکتا تو نیا کھاتہ بنائیں اور اس کے لیے نیا پاسورڈ مقرر کریں۔',
  ],
  [
    'forgotBackToSignIn',
    'Back to sign in',
    'العودة إلى تسجيل الدخول',
    'سائن ان پر واپس جائیں',
  ],
  [
    'forgotCreateAccount',
    'Create a new account',
    'إنشاء حساب جديد',
    'نیا کھاتہ بنائیں',
  ],
];

String _code(String path) => stripCommentsForGuard(File(path).readAsStringSync());

/// `String get NAME => _t('en', 'ar', 'ur');` in either of the file's two
/// layouts (single line, or the multi-line `_t(` form long copy uses). Same
/// shape the repo-wide i18n census parses, scoped to one name.
List<String>? _declared(String name) {
  final rx = RegExp(
    "String get $name => _t\\(\\s*'((?:[^'\\\\]|\\\\.)*)',\\s*"
    "'((?:[^'\\\\]|\\\\.)*)',\\s*'((?:[^'\\\\]|\\\\.)*)',?\\s*\\);",
    dotAll: true,
  );
  final m = rx.firstMatch(File(_strings).readAsStringSync());
  return m == null ? null : [m.group(1)!, m.group(2)!, m.group(3)!];
}

/// One harness for all three render tests. The box is deliberately generous
/// (400x1200): these tests certify COPY and AFFORDANCES, not narrow-screen fit,
/// and the narrow-screen rule this repo already owns belongs to the screens that
/// have toolbars. A tight box here would turn a clean assertion red into a
/// layout-exception red, which is how a real finding gets lost.
Widget _harness({double width = 400, double height = 1200, String locale = 'en'}) {
  return ProviderScope(
    child: SizedBox(
      width: width,
      height: height,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(
          home: AppStringsScope(
            locale: Locale(locale),
            child: const ForgotPasswordScreen(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('QB-006 · the forgot-password screen promises nothing it cannot do', () {
    test('the fake flow is gone from the source', () {
      final code = _code(_screen);
      for (final gone in [
        'Future.delayed',
        'Simulate',
        '_emailController',
        '_emailFocus',
        '_isLoading',
        '_emailSent',
        '_errorMessage',
        '_sentEmail',
        '_successController',
        '_handleSendResetLink',
        '_handleResend',
        '_handleOpenEmail',
        'AnimationController',
        'TickerProviderStateMixin',
        'AnimatedSwitcher',
        'HapticFeedback',
        'openingEmailApp',
        'Icons.mail',
        'mailto',
      ]) {
        expect(code.contains(gone), isFalse,
            reason: 'the screen still mentions "$gone" — that is the fake, not '
                'the feature');
      }
      // And with no haptics and no SnackBar, `package:flutter/services.dart`
      // must be UNimported: an unused import is an analyzer warning, and this
      // repo's gate is 0 warnings, so the pin catches both directions.
      expect(code.contains("import 'package:flutter/services.dart';"), isFalse,
          reason: 'services.dart is imported for nothing but haptics');
      // A form with no field cannot validate anything.
      expect(code.contains('Form('), isFalse);
      expect(code.contains('AppValidation'), isFalse);
    });

    testWidgets('the honest copy renders, byte-exactly',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 900));
      for (final row in _copy) {
        expect(find.text(row[1]), findsWidgets,
            reason: 'the screen does not render "${row[1]}" — the honest '
                'sentence is the deliverable, not a comment about it');
      }
      // The lie specifically, in its own words: the sentence that promised a
      // link, and the "no worries" that covered for it.
      expect(find.textContaining('send you a link'), findsNothing);
      expect(find.textContaining('No worries'), findsNothing);
    });

    testWidgets('no input field of any kind exists', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      // No fake progress affordance either: a spinner on a screen that runs no
      // request is the same lie in a different costume.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    test('the two real exits, and no third', () {
      final code = _code(_screen);
      expect(code.contains('context.go(AppRoutes.login)'), isTrue,
          reason: 'sign-in is the exit that exists');
      expect(code.contains('context.go(AppRoutes.register)'), isTrue,
          reason: 'register is the other exit that exists');
      // Three calls, two destinations: the header chevron and the sign-in
      // button both go to login (that is the shared AuthHeader's contract), the
      // second button goes to register. Anything else would need a route.
      final exits = RegExp(r'context\.go\((AppRoutes\.\w+)\)').allMatches(code);
      expect(exits.length, 3,
          reason: 'expected header-back + two AuthButtons, found '
              '${exits.length} — a fourth call would be a new promise');
      // The source must reference exactly these two route constants — no
      // context.push, no pop-then-push, no third destination wearing a name.
      expect(exits.map((m) => m.group(1)).toSet(),
          {'AppRoutes.login', 'AppRoutes.register'},
          reason: 'every exit must be login or register — those are the two '
              'routes this build has for a locked-out user');
      // And the names must be real, mounted routes — not strings this file made
      // up. The router spells them `path: AppRoutes.login`, so pin that shape.
      final router = File('lib/core/router/app_router.dart').readAsStringSync();
      for (final name in ['login', 'register']) {
        expect(router, contains('path: AppRoutes.$name'),
            reason: 'AppRoutes.$name is not mounted, so it is not an exit');
      }
    });

    test('all ten new AppStrings getters are real in en/ar/ur', () {
      for (final row in _copy) {
        final name = row[0];
        final declared = _declared(name);
        expect(declared, isNotNull,
            reason: '$name is used by the screen and must be declared as '
                'String get $name => _t(en, ar, ur);');
        // Explicit promotion, not a `!` sprinkled on each index: the analyzer
        // cannot know `isNotNull` passed, and a bare `declared[0]` on a
        // `List<String>?` is a compile error under this repo's strict-casts.
        if (declared == null) return;
        expect(declared[0], row[1], reason: '$name EN drifted');
        expect(declared[1], row[2], reason: '$name AR drifted');
        expect(declared[2], row[3], reason: '$name UR drifted');
        final arabic = RegExp(r'[؀-ۿ]');
        expect(arabic.hasMatch(declared[1]), isTrue,
            reason: '$name Arabic is not in Arabic script');
        expect(arabic.hasMatch(declared[2]), isTrue,
            reason: '$name Urdu is not in Arabic script');
        expect(declared[1], isNot(declared[0]));
        expect(declared[2], isNot(declared[0]));
        expect(declared[2], isNot(declared[1]),
            reason: '$name Urdu equals the Arabic row — a copy-paste miss');
      }
    });

    test('the invented "Open email app" getter stays deleted', () {
      final strings = File(_strings).readAsStringSync();
      expect(strings.contains('openingEmailApp'), isFalse,
          reason: 'the getter outlives its button, and then someone re-adds '
              'the button');
      var referenced = 0;
      for (final entry in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()) {
        if (!entry.path.endsWith('.dart')) continue;
        referenced +=
            RegExp(r'\.openingEmailApp\b').allMatches(_code(entry.path)).length;
      }
      expect(referenced, 0);
    });

    test('raw-chrome census on this file, line-wise AND cross-line', () {
      final src = File(_screen).readAsStringSync();
      // The repo's own census (test/core/i18n_phase_a_test.dart) is line-based,
      // which is how ten raw literals survived this 925-line screen while the
      // census counted 0 here: `Text(` at the end of a line and the string on
      // the next one never matches. Measured on the pre-QB-006 file — 0
      // line-based hits, 10 cross-line ones ('PASSWORD RECOVERY', 'Forgot
      // Password?', 'No worries!…', 'Check Your Email', 'NEXT STEPS', 'Link
      // expires in 15 minutes', 'Open Email App', 'Back to Login', …). The same
      // shape is checked here across newlines, so the file cannot dodge the rule
      // by formatting.
      final crossLine =
          RegExp(r"""Text\(\s*\n?\s*'[A-Za-z][^'\n]*""", dotAll: true)
              .allMatches(stripCommentsForGuard(src))
              .length;
      expect(crossLine, 0,
          reason: '$crossLine raw Text literal(s) still rendered by this file');
      // Comments do not count as chrome, but the strip must have been applied.
      expect(src.contains('Simulate API call'), isFalse,
          reason: 'the comment itself documents a call that should be gone');
    });

    test('it rides the shared auth chrome, at 48dp or better', () {
      final code = _code(_screen);
      expect(code.contains('AuthButton('), isTrue,
          reason: 'the two exits are real buttons, not hand-rolled detectors');
      expect(RegExp(r'AuthButton\(').allMatches(code).length, 2,
          reason: 'exactly two actions, matching the two real routes');
      expect(code.contains('AuthHeader('), isTrue,
          reason: 'the back affordance is the shared one, already labelled');
      // No hand-rolled tap target at all: AuthButton is 56dp by default and the
      // repo's floor is `AppA11y.minTapTarget == 48` (pinned since phase 10, e.g.
      // test/core/phase10_test.dart:12). A bare GestureDetector here would be a
      // tap target no a11y census can see — IconButton/Semantics are both pinned
      // repo-wide in test/core/a11y_pass_test.dart, and this file adds neither.
      expect(code.contains('GestureDetector('), isFalse,
          reason: 'the exits must be buttons, not tap-shaped containers');
      expect(code.contains('AppRadius.'), isTrue);
      expect(code.contains('QibraColors.of(context)'), isTrue);
    });

    testWidgets('controls: icons resolve, tokens are clean, no emoji',
        (tester) async {
      // Green on the OLD file and on the NEW one, on purpose. The original round
      // shipped `Icons.mail_off_rounded`, which does not exist, and the static
      // battery scored that as 2 hard findings — the rule is battery G8, and
      // nothing in the Dart suite enforced it. So the screen that introduced the
      // bug now carries the check.
      final known = File(_icons).readAsStringSync().split(RegExp(r'\s+'));
      final have = known.toSet();
      expect(have.length, greaterThan(5000),
          reason: 'the metadata file looks truncated — validate before trusting '
              'a zero in the loop below');
      for (final m in RegExp(r'\bIcons\.([A-Za-z0-9_]+)')
          .allMatches(_code(_screen))) {
        expect(have.contains(m.group(1)), isTrue,
            reason: 'Icons.${m.group(1)} is not a Flutter Material icon');
      }
      final src = _code(_screen);
      expect(RegExp(r'Color\(0x').allMatches(src).length, 0,
          reason: 'raw colors in a presentation file (battery L1)');
      final emoji = src.runes
          .where((r) =>
              (r >= 0x1F300 && r <= 0x1FAFF) || (r >= 0x2600 && r <= 0x27BF))
          .length;
      expect(emoji, 0, reason: 'this repo has one icon language');
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull,
          reason: 'the screen must render, not just grep');
    });
  });
}
