// test/profile_avatar_honesty_test.dart
// ============================================================
// QIBRA AI — PROFILE AVATAR HONESTY TESTS (deep audit 2026-09-04)
// ============================================================
// Pins the fix for the fabricated avatar-selection flow:
//   • the screen really uses image_picker (import + call present),
//   • no identifier in the file contains 'mock' (the name of the old
//     fabricated method),
//   • the pure state logic: a cancelled pick (null file) NEVER changes
//     the stored avatar path, and a failed pick keeps the previous one;
//   • removal deletes the real file before updating state.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/settings/presentation/profile_setup_screen.dart';

const _screenPath =
    'lib/features/settings/presentation/profile_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('avatar screen wiring — real picker, no fabrication', () {
    test('screen imports image_picker and calls the real API', () {
      final src = File(_screenPath).readAsStringSync();
      expect(
        src.contains("import 'package:image_picker/image_picker.dart';"),
        isTrue,
        reason: 'the selection flow must use the real package',
      );
      expect(src.contains('ImagePicker().pickImage('), isTrue,
          reason: 'pickImage must actually be called');
      expect(src.contains('await picked.readAsBytes()'), isTrue,
          reason: 'the picked file bytes are really stored');
    });

    test('the file contains no mock identifier (name-level honesty)', () {
      final src = File(_screenPath).readAsStringSync();
      expect(src.toLowerCase().contains('mock'), isFalse,
          reason: 'the word mock must not appear anywhere, even in '
              'comments — the old _mockAvatarUpload era is closed');
    });

    test('cancel is not an error: the null path returns immediately', () {
      final src = File(_screenPath).readAsStringSync();
      // The cancel branch must be an early return with NO setState and
      // NO snackbar between it and the statement — pin the shape:
      final i = src.indexOf('if (picked == null) return;');
      expect(i, greaterThan(-1),
          reason: 'a cancelled pick must do nothing at all');
      final rest = src.substring(i, i + 80);
      expect(rest.contains('setState'), isFalse);
      expect(rest.contains('SnackBar'), isFalse);
    });

    test('delete happens on disk BEFORE state drops the avatar', () {
      final src = File(_screenPath).readAsStringSync();
      final del = src.indexOf('await f.delete()');
      final st = src.indexOf('setState(() => _avatarPath = null)');
      expect(del, greaterThan(-1), reason: 'removal must really delete');
      expect(st, greaterThan(del),
          reason: 'UI may only drop the avatar after the file is gone');
    });
  });

  group('pure avatar logic (device-independent semantics)', () {
    test('stored path shape is <appSupport>/profile/avatar.jpg, '
        'Windows separators normalized', () {
      expect(ProfileSetupScreen.avatarDestPath('/data/x/app-support'),
          '/data/x/app-support/profile/avatar.jpg');
      expect(
        ProfileSetupScreen.avatarDestPath(r'C:\Users\q\AppData'),
        'C:/Users/q/AppData/profile/avatar.jpg',
      );
    });

    test('cancel (null pick) keeps the current path untouched', () {
      expect(
        ProfileSetupScreen.nextAvatarPath(current: null, pickedAndStored: null),
        isNull,
      );
      expect(
        ProfileSetupScreen.nextAvatarPath(
            current: '/a/profile/avatar.jpg', pickedAndStored: null),
        '/a/profile/avatar.jpg',
      ); // failure/cancel NEVER clears or invents
    });

    test('a verified stored file is the only thing that changes state', () {
      expect(
        ProfileSetupScreen.nextAvatarPath(
            current: '/a/profile/avatar.jpg',
            pickedAndStored: '/a/profile/avatar.new'),
        '/a/profile/avatar.new',
      );
      expect(
        ProfileSetupScreen.nextAvatarPath(
            current: null, pickedAndStored: '/a/profile/avatar.jpg'),
        '/a/profile/avatar.jpg',
      );
    });
  });
}
