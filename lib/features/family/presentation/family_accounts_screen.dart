// lib/features/family/presentation/family_accounts_screen.dart
// Phase 15: a local-first family space that does not pretend to sync offline data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/family_models.dart';
import '../providers/family_provider.dart';

class FamilyAccountsScreen extends ConsumerWidget {
  const FamilyAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final family = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            QibraScreenHeader(
              title: 'Family space',
              subtitle: 'A shared place for your household\'s worship goals',
            ),
            if (family.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!family.hasFamily)
              _EmptyFamilyState(
                onCreate: () => _showCreateFamilyDialog(context, ref),
              )
            else
              _FamilyContent(family: family),
            if (family.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(
                message: family.errorMessage!,
                onDismiss: ref.read(familyProvider.notifier).clearError,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateFamilyDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final userName = ref.read(userDisplayNameProvider);
    final draft = await showDialog<_CreateFamilyDraft>(
      context: context,
      builder: (_) => _CreateFamilyDialog(
        suggestedOwnerName: userName == 'Guest' ? '' : userName,
      ),
    );
    if (draft == null || !context.mounted) return;

    ref.read(familyProvider.notifier).createFamily(
          name: draft.familyName,
          ownerName: draft.ownerName,
        );
  }
}

class _FamilyContent extends ConsumerWidget {
  const _FamilyContent({required this.family});

  final FamilyState family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final notifier = ref.read(familyProvider.notifier);
    final inviteCode = family.inviteCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FamilyHero(
          familyName: family.familyName!,
          memberCount: family.members.length,
          onRename: () => _renameFamily(context, notifier, family.familyName!),
        ),
        const SizedBox(height: 16),
        QibraCard(
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link_rounded, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Local invite code',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (inviteCode != null)
                    IconButton(
                      tooltip: 'Copy invite code',
                      onPressed: () => _copyInviteCode(context, inviteCode),
                      icon: Icon(Icons.copy_outlined, color: colors.primary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  family.inviteCode ?? '—',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This space is stored on this device. Online invitations and cross-device sync will be enabled with the Qibra backend.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        QibraSectionHeader(
          title: 'Members',
          actionLabel: 'Add member',
          onAction: () => _showAddMemberDialog(context, ref),
        ),
        ...family.members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MemberCard(
              member: member,
              onRemove: member.role == FamilyMemberRole.member
                  ? () => _removeMember(context, notifier, member)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _showAddMemberDialog(context, ref),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add a family member'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.border),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 30),
        QibraSectionHeader(title: 'Family space settings'),
        QibraCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text(
              'Delete family space',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Remove this local space from this device',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            onTap: () => _deleteFamily(context, notifier),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final draft = await showDialog<_MemberDraft>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (draft == null || !context.mounted) return;
    ref.read(familyProvider.notifier).addMember(
          name: draft.name,
          relation: draft.relation,
        );
  }

  Future<void> _renameFamily(
    BuildContext context,
    FamilyNotifier notifier,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename family space'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Family name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) notifier.renameFamily(name);
  }

  Future<void> _removeMember(
    BuildContext context,
    FamilyNotifier notifier,
    FamilyMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: const Text(
          'This removes the member from this family space on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.removeMember(member.id);
  }

  Future<void> _deleteFamily(
    BuildContext context,
    FamilyNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete family space?'),
        content: const Text(
          'All members and this local invite code will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.deleteFamily();
  }

  void _copyInviteCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }
}

class _FamilyHero extends StatelessWidget {
  const _FamilyHero({
    required this.familyName,
    required this.memberCount,
    required this.onRename,
  });

  final String familyName;
  final int memberCount;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: colors.onPrimary,
                  size: 24,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Rename family',
                onPressed: onRename,
                icon: Icon(Icons.edit_outlined, color: colors.onPrimary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            familyName,
            style: AppTextStyles.headlineSmall.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Small steps are easier together.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 18, color: colors.onPrimary),
              const SizedBox(width: 7),
              Text(
                '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 18, color: colors.onPrimary.withValues(alpha: 0.25)),
              const SizedBox(width: 16),
              Text(
                'On this device',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, this.onRemove});

  final FamilyMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final initials = member.name.trim().isEmpty
        ? '?'
        : member.name.trim().substring(0, 1).toUpperCase();

    return QibraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.isCurrentUser
                      ? '${member.relation} · You'
                      : member.relation,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.role.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove member',
              onPressed: onRemove,
              icon: Icon(Icons.more_vert_rounded, color: colors.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _EmptyFamilyState extends StatelessWidget {
  const _EmptyFamilyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              size: 42,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Build your family space',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a private, local space for the people you worship with. Add household members and keep the setup on this device.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create family space'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No account or cloud sync is required.',
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CreateFamilyDraft {
  const _CreateFamilyDraft({required this.familyName, required this.ownerName});

  final String familyName;
  final String ownerName;
}

class _MemberDraft {
  const _MemberDraft({required this.name, required this.relation});

  final String name;
  final String relation;
}

class _CreateFamilyDialog extends StatefulWidget {
  const _CreateFamilyDialog({required this.suggestedOwnerName});

  final String suggestedOwnerName;

  @override
  State<_CreateFamilyDialog> createState() => _CreateFamilyDialogState();
}

class _CreateFamilyDialogState extends State<_CreateFamilyDialog> {
  late final TextEditingController _familyNameController;
  late final TextEditingController _ownerNameController;

  @override
  void initState() {
    super.initState();
    _familyNameController = TextEditingController();
    _ownerNameController =
        TextEditingController(text: widget.suggestedOwnerName);
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final familyName = _familyNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    if (familyName.isEmpty || ownerName.isEmpty) return;
    Navigator.of(context).pop(
      _CreateFamilyDraft(familyName: familyName, ownerName: ownerName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create family space'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This stays on your device until cloud accounts are available.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _familyNameController,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Family name',
                hintText: 'For example, The Khan family',
              ),
              onSubmitted: (_) => _submit(),
            ),
            TextField(
              controller: _ownerNameController,
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final relation = _relationController.text.trim();
    if (name.isEmpty || relation.isEmpty) return;
    Navigator.of(context).pop(_MemberDraft(name: name, relation: relation));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add family member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (_) => _submit(),
          ),
          TextField(
            controller: _relationController,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              hintText: 'For example, Parent or Sibling',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add member')),
      ],
    );
  }
}
