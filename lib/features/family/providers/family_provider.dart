// lib/features/family/providers/family_provider.dart
// Local-first storage with an explicit boundary for future cloud sync.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../data/family_models.dart';

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier(this._secureStorage) : super(const FamilyState(isLoading: true)) {
    _load();
  }

  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();

  Future<void> _load() async {
    try {
      final encoded = await _secureStorage.read(key: AppStorageKeys.familySpace);
      if (encoded == null || encoded.isEmpty) {
        if (mounted) state = const FamilyState();
        return;
      }

      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        if (mounted) state = const FamilyState();
        return;
      }
      if (mounted) {
        state = FamilyState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // A corrupt local record must not block the rest of the app.
      if (mounted) state = const FamilyState();
    }
  }

  Future<void> _persist() async {
    try {
      await _secureStorage.write(
        key: AppStorageKeys.familySpace,
        value: jsonEncode(state.toJson()),
      );
    } catch (_) {
      // Family space remains usable in memory when storage is unavailable.
    }
  }

  Future<void> _clearPersistedSpace() async {
    try {
      await _secureStorage.delete(key: AppStorageKeys.familySpace);
    } catch (_) {
      // The in-memory state is still cleared even if storage is unavailable.
    }
  }

  void createFamily({required String name, required String ownerName}) {
    final familyName = name.trim();
    final trimmedOwnerName = ownerName.trim();
    if (familyName.isEmpty || trimmedOwnerName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Enter a family name and your name to continue.',
      );
      return;
    }

    final owner = FamilyMember(
      id: _newId('owner'),
      name: trimmedOwnerName,
      relation: 'You',
      role: FamilyMemberRole.owner,
      isCurrentUser: true,
    );
    state = FamilyState(
      familyName: familyName,
      inviteCode: _newInviteCode(),
      members: [owner],
    );
    unawaited(_persist());
  }

  void addMember({required String name, required String relation}) {
    final trimmedName = name.trim();
    final trimmedRelation = relation.trim();
    if (!state.hasFamily) {
      state = state.copyWith(
        errorMessage: 'Create a family space before adding members.',
      );
      return;
    }
    if (trimmedName.isEmpty || trimmedRelation.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Enter a name and relationship for this member.',
      );
      return;
    }
    if (state.members.length >= 8) {
      state = state.copyWith(
        errorMessage: 'A family space can have up to eight members.',
      );
      return;
    }

    state = state.copyWith(
      members: [
        ...state.members,
        FamilyMember(
          id: _newId('member'),
          name: trimmedName,
          relation: trimmedRelation,
          role: FamilyMemberRole.member,
        ),
      ],
      clearError: true,
    );
    unawaited(_persist());
  }

  void removeMember(String memberId) {
    FamilyMember? member;
    for (final candidate in state.members) {
      if (candidate.id == memberId) {
        member = candidate;
        break;
      }
    }
    if (member == null || member.role == FamilyMemberRole.owner) return;

    state = state.copyWith(
      members: state.members.where((item) => item.id != memberId).toList(),
      clearError: true,
    );
    unawaited(_persist());
  }

  void renameFamily(String name) {
    final familyName = name.trim();
    if (familyName.isEmpty || !state.hasFamily) return;
    state = state.copyWith(familyName: familyName, clearError: true);
    unawaited(_persist());
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void deleteFamily() {
    state = const FamilyState();
    unawaited(_clearPersistedSpace());
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(9999)}';
  }

  String _newInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    return 'QIBRA-$code';
  }
}

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier(ref.watch(secureStorageProvider));
});

final familyMemberCountProvider = Provider<int>((ref) {
  return ref.watch(familyProvider).members.length;
});
