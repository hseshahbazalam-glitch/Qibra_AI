// lib/features/prayer/presentation/prayer_settings_screen.dart

// ============================================================
// QIBRA AI — PRAYER SETTINGS SCREEN (v1.0)
// Phase: 9 — Prayer Configuration
// ============================================================
import '../data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  ConsumerState<PrayerSettingsScreen> createState() =>
      _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showCalculationMethodPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CalculationMethodSheet(
        currentMethod: ref.read(prayerSettingsProvider).calculationMethod,
        onSelect: (method) {
          ref
              .read(prayerSettingsProvider.notifier)
              .setCalculationMethod(method);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAsrMethodPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AsrMethodSheet(
        currentMethod: ref.read(prayerSettingsProvider).asrMethod,
        onSelect: (method) {
          ref.read(prayerSettingsProvider.notifier).setAsrMethod(method);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAdjustmentDialog(PrayerType type) {
    HapticFeedback.selectionClick();
    final current = ref.read(prayerSettingsProvider).getAdjustment(type);

    showDialog(
      context: context,
      builder: (dialogContext) => _AdjustmentDialog(
        prayerType: type,
        currentValue: current,
        onSave: (value) {
          ref.read(prayerSettingsProvider.notifier).setAdjustment(type, value);
        },
      ),
    );
  }

  void _showPreReminderPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreReminderSheet(
        current: ref.read(prayerSettingsProvider).preReminderMinutes,
        onSelect: (minutes) {
          ref
              .read(prayerSettingsProvider.notifier)
              .setPreReminderMinutes(minutes);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _confirmReset() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        title: Row(
          children: [
            const Icon(Icons.restore_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Reset to Defaults?',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'All settings will be restored to default values. This cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(prayerSettingsProvider.notifier)
                  .updateSettings(const PrayerSettings());
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Settings reset to defaults',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              'Reset',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(prayerSettingsProvider);
    final location = ref.watch(locationProvider).location;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await NotificationService.instance.showTestNotification();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 Test notification sent!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        icon:
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
        label: const Text(
          'Test Azan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _buildTopBar(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl3,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Calculation section
                      _buildSectionHeader('CALCULATION'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTile(
                        icon: Icons.calculate_rounded,
                        iconColor: AppColors.primary,
                        title: 'Calculation Method',
                        subtitle: settings.calculationMethod.fullName,
                        badge: settings.calculationMethod.shortName,
                        onTap: _showCalculationMethodPicker,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTile(
                        icon: Icons.wb_twilight_rounded,
                        iconColor: const Color(0xFFFF7043),
                        title: 'Asr Method',
                        subtitle: settings.asrMethod.description,
                        badge: settings.asrMethod.shortName,
                        onTap: _showAsrMethodPicker,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Time adjustments
                      _buildSectionHeader('TIME ADJUSTMENTS'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color:
                              AppColors.surfaceElevated.withValues(alpha: 0.80),
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Column(
                          children: PrayerType.values.map((type) {
                            final adjustment = settings.getAdjustment(type);
                            final isLast = type == PrayerType.values.last;
                            return Column(
                              children: [
                                _buildAdjustmentRow(type, adjustment),
                                if (!isLast)
                                  Divider(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    height: 1,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Notifications
                      _buildSectionHeader('NOTIFICATIONS'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.primary,
                        title: 'Prayer Notifications',
                        subtitle: 'Get notified for each prayer',
                        value: settings.enableNotifications,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .toggleNotifications(val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.campaign_rounded,
                        iconColor: AppColors.accent,
                        title: 'Adhan (Call to Prayer)',
                        subtitle: 'Play adhan sound at prayer time',
                        value: settings.enableAdhan,
                        enabled: settings.enableNotifications,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .toggleAdhan(val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.access_alarm_rounded,
                        iconColor: const Color(0xFFAB47BC),
                        title: 'Pre-Prayer Reminder',
                        subtitle:
                            '${settings.preReminderMinutes} minutes before',
                        value: settings.enablePreReminder,
                        enabled: settings.enableNotifications,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .togglePreReminder(val);
                        },
                        trailing: settings.enablePreReminder
                            ? IconButton(
                                onPressed: _showPreReminderPicker,
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.do_not_disturb_on_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        title: 'Silent Mode',
                        subtitle: 'Auto-silence during prayer',
                        value: settings.enableSilentMode,
                        enabled: settings.enableNotifications,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .toggleSilentMode(val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Display
                      _buildSectionHeader('DISPLAY'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFFFA726),
                        title: 'Show Sunrise',
                        subtitle: 'Display sunrise time in schedule',
                        value: settings.showSunrise,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .toggleSunrise(val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSwitchTile(
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFF26A69A),
                        title: '24-Hour Format',
                        subtitle:
                            settings.use24HourFormat ? '14:30' : '2:30 PM',
                        value: settings.use24HourFormat,
                        onChanged: (val) {
                          ref
                              .read(prayerSettingsProvider.notifier)
                              .set24HourFormat(val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Location
                      _buildSectionHeader('LOCATION'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildLocationCard(location),
                      const SizedBox(height: AppSpacing.xl),

                      // Reset
                      _buildResetButton(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONFIGURATION',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prayer Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            AppColors.surfaceElevated.withValues(alpha: enabled ? 0.80 : 0.40),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: enabled ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              icon,
              color: enabled ? iconColor : iconColor.withValues(alpha: 0.40),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.30),
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceHigh,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentRow(PrayerType type, int adjustment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(type.icon, color: type.color, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              type.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _AdjustmentButton(
            icon: Icons.remove_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(prayerSettingsProvider.notifier)
                  .setAdjustment(type, adjustment - 1);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _showAdjustmentDialog(type),
            child: Container(
              constraints: const BoxConstraints(minWidth: 60),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: adjustment != 0
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : AppColors.surface.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: adjustment != 0
                      ? AppColors.accent.withValues(alpha: 0.30)
                      : AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Center(
                child: Text(
                  adjustment > 0
                      ? '+$adjustment min'
                      : adjustment < 0
                          ? '$adjustment min'
                          : '0 min',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: adjustment != 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _AdjustmentButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(prayerSettingsProvider.notifier)
                  .setAdjustment(type, adjustment + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(PrayerLocation? location) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  location?.isManuallySet == true
                      ? Icons.push_pin_rounded
                      : Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location?.displayName ?? 'Not set',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (location != null)
                      Text(
                        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(locationProvider.notifier).fetchCurrentLocation();
                  },
                  icon: const Icon(
                    Icons.gps_fixed_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Update GPS',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(locationProvider.notifier).resetToDefault();
                  },
                  icon: const Icon(
                    Icons.mosque_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  label: Text(
                    'Makkah',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmReset,
        icon: const Icon(
          Icons.restore_rounded,
          color: AppColors.warning,
          size: 20,
        ),
        label: Text(
          'Reset to Defaults',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.30),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CALCULATION METHOD SHEET
// ============================================================

class _CalculationMethodSheet extends StatelessWidget {
  const _CalculationMethodSheet({
    required this.currentMethod,
    required this.onSelect,
  });

  final CalculationMethod currentMethod;
  final ValueChanged<CalculationMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.90,
      minChildSize: 0.50,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceSheet,
            borderRadius: BorderRadius.circular(AppRadius.xl3),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Calculation Method',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: CalculationMethod.values.length,
                  itemBuilder: (context, index) {
                    final method = CalculationMethod.values[index];
                    final isSelected = method == currentMethod;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onSelect(method),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.14)
                                  : AppColors.surfaceElevated
                                      .withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.40)
                                    : AppColors.primary.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.20)
                                        : AppColors.surfaceHigh,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: Center(
                                    child: Text(
                                      method.shortName,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method.fullName,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method.description,
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ASR METHOD SHEET
// ============================================================

class _AsrMethodSheet extends StatelessWidget {
  const _AsrMethodSheet({
    required this.currentMethod,
    required this.onSelect,
  });

  final AsrMethod currentMethod;
  final ValueChanged<AsrMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: Color(0xFFFF7043)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Asr Method',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...AsrMethod.values.map((method) {
            final isSelected = method == currentMethod;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(method),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7043).withValues(alpha: 0.14)
                          : AppColors.surfaceElevated.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF7043).withValues(alpha: 0.40)
                            : AppColors.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.fullName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.description,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFFF7043),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// PRE-REMINDER SHEET
// ============================================================

class _PreReminderSheet extends StatelessWidget {
  const _PreReminderSheet({
    required this.current,
    required this.onSelect,
  });

  final int current;
  final ValueChanged<int> onSelect;

  static const _options = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reminder Time',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'How many minutes before prayer?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _options.map((minutes) {
              final isSelected = minutes == current;
              return GestureDetector(
                onTap: () => onSelect(minutes),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.50)
                          : AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    '$minutes min',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADJUSTMENT DIALOG
// ============================================================

class _AdjustmentDialog extends StatefulWidget {
  const _AdjustmentDialog({
    required this.prayerType,
    required this.currentValue,
    required this.onSave,
  });

  final PrayerType prayerType;
  final int currentValue;
  final ValueChanged<int> onSave;

  @override
  State<_AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends State<_AdjustmentDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
      ),
      title: Row(
        children: [
          Icon(widget.prayerType.icon, color: widget.prayerType.color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${widget.prayerType.name} Adjustment',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Minutes to add/subtract (-60 to +60)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
              suffixText: 'min',
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            widget.onSave(value.clamp(-60, 60));
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: Text(
            'Save',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SMALL WIDGETS
// ============================================================

class _AdjustmentButton extends StatelessWidget {
  const _AdjustmentButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — prayer_settings_screen.dart
// ============================================================
