import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/family/data/family_models.dart';

void main() {
  group('FamilyMember', () {
    test('serializes and restores the member role', () {
      const member = FamilyMember(
        id: 'member-1',
        name: 'Amina',
        relation: 'Sibling',
        role: FamilyMemberRole.member,
      );

      final restored = FamilyMember.fromJson(member.toJson());

      expect(restored, member);
      expect(restored.role.label, 'Member');
    });

    test('unknown role values are safe non-owner members', () {
      final member = FamilyMember.fromJson({
        'id': 'member-2',
        'name': 'Yusuf',
        'relation': 'Child',
        'role': 'unexpected',
      });

      expect(member.role, FamilyMemberRole.member);
      expect(member.isCurrentUser, isFalse);
    });
  });

  group('FamilyState', () {
    test('round trip preserves family data', () {
      const state = FamilyState(
        familyName: 'The Rahman family',
        inviteCode: 'QIBRA-AB12CD',
        members: [
          FamilyMember(
            id: 'owner-1',
            name: 'Samir',
            relation: 'You',
            role: FamilyMemberRole.owner,
            isCurrentUser: true,
          ),
          FamilyMember(
            id: 'member-1',
            name: 'Noor',
            relation: 'Child',
            role: FamilyMemberRole.member,
          ),
        ],
      );

      final restored = FamilyState.fromJson(state.toJson());

      expect(restored.familyName, state.familyName);
      expect(restored.inviteCode, state.inviteCode);
      expect(restored.members, orderedEquals(state.members));
      expect(restored.hasOwner, isTrue);
    });

    test('invalid persisted members are ignored without blocking the space', () {
      final state = FamilyState.fromJson({
        'family_name': 'Family',
        'invite_code': 'QIBRA-ABC123',
        'members': [
          {'id': '', 'name': 'Missing id'},
          {'id': 'valid', 'name': 'Valid', 'relation': 'Parent'},
        ],
      });

      expect(state.hasFamily, isTrue);
      expect(state.members, hasLength(1));
      expect(state.members.single.name, 'Valid');
    });
  });
}
