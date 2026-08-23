// lib/features/family/data/family_models.dart
// Local-first family space models for Phase 15.

import 'package:flutter/foundation.dart';

enum FamilyMemberRole { owner, member }

extension FamilyMemberRoleLabel on FamilyMemberRole {
  String get label => this == FamilyMemberRole.owner ? 'Owner' : 'Member';

  String get value => this == FamilyMemberRole.owner ? 'owner' : 'member';
}

FamilyMemberRole _familyMemberRoleFromValue(String? value) {
  return value == 'owner' ? FamilyMemberRole.owner : FamilyMemberRole.member;
}

@immutable
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.role,
    this.isCurrentUser = false,
  });

  final String id;
  final String name;
  final String relation;
  final FamilyMemberRole role;
  final bool isCurrentUser;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relation,
    FamilyMemberRole? role,
    bool? isCurrentUser,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      role: role ?? this.role,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? 'Family member',
      role: _familyMemberRoleFromValue(json['role']?.toString()),
      isCurrentUser: json['is_current_user'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'role': role.value,
      'is_current_user': isCurrentUser,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FamilyMember &&
            other.id == id &&
            other.name == name &&
            other.relation == relation &&
            other.role == role &&
            other.isCurrentUser == isCurrentUser;
  }

  @override
  int get hashCode => Object.hash(id, name, relation, role, isCurrentUser);
}

@immutable
class FamilyState {
  const FamilyState({
    this.familyName,
    this.inviteCode,
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final String? familyName;
  final String? inviteCode;
  final List<FamilyMember> members;
  final bool isLoading;
  final String? errorMessage;

  bool get hasFamily => familyName != null && familyName!.trim().isNotEmpty;

  bool get hasOwner => members.any((member) => member.role == FamilyMemberRole.owner);

  FamilyState copyWith({
    String? familyName,
    String? inviteCode,
    List<FamilyMember>? members,
    bool? isLoading,
    String? errorMessage,
    bool clearFamily = false,
    bool clearError = false,
  }) {
    return FamilyState(
      familyName: clearFamily ? null : (familyName ?? this.familyName),
      inviteCode: clearFamily ? null : (inviteCode ?? this.inviteCode),
      members: clearFamily ? const [] : (members ?? this.members),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory FamilyState.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = rawMembers is List
        ? rawMembers
            .whereType<Map>()
            .map((member) =>
                FamilyMember.fromJson(Map<String, dynamic>.from(member)))
            .where((member) => member.id.isNotEmpty && member.name.isNotEmpty)
            .toList(growable: false)
        : const <FamilyMember>[];
    final name = json['family_name']?.toString().trim();
    final inviteCode = json['invite_code']?.toString().trim();

    return FamilyState(
      familyName: name == null || name.isEmpty ? null : name,
      inviteCode: inviteCode == null || inviteCode.isEmpty ? null : inviteCode,
      members: members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_name': familyName,
      'invite_code': inviteCode,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
}
