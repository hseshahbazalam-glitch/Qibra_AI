// Shared loading / empty / error / offline / retry states.

import 'package:flutter/material.dart';

import '../../core/a11y/app_a11y.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/qibra_colors.dart';
import '../../core/l10n/app_strings.dart';

enum QibraStatusKind { loading, empty, error, offline }

class QibraStatus extends StatelessWidget {
  const QibraStatus({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  final QibraStatusKind kind;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  factory QibraStatus.loading({String? message}) => QibraStatus(
        kind: QibraStatusKind.loading,
        message: message,
      );

  factory QibraStatus.empty({String? title, String? message}) => QibraStatus(
        kind: QibraStatusKind.empty,
        title: title,
        message: message,
      );

  factory QibraStatus.error({
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) =>
      QibraStatus(
        kind: QibraStatusKind.error,
        title: title,
        message: message,
        onRetry: onRetry,
      );

  factory QibraStatus.skeleton({double height = 88}) => QibraStatus(
        kind: QibraStatusKind.loading,
        message: '__skeleton__$height',
      );

  factory QibraStatus.offline({VoidCallback? onRetry}) => QibraStatus(
        kind: QibraStatusKind.offline,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);

    if (kind == QibraStatusKind.loading) {
      if (message != null && message!.startsWith('__skeleton__')) {
        final h = double.tryParse(message!.replaceFirst('__skeleton__', '')) ?? 88;
        return Container(
          height: h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.cardMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? s.loading,
              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final icon = switch (kind) {
      QibraStatusKind.empty => Icons.inbox_outlined,
      QibraStatusKind.error => Icons.error_outline,
      QibraStatusKind.offline => Icons.wifi_off_rounded,
      QibraStatusKind.loading => Icons.hourglass_empty,
    };
    final resolvedTitle = title ??
        switch (kind) {
          QibraStatusKind.empty => s.empty,
          QibraStatusKind.error => s.error,
          QibraStatusKind.offline => s.offline,
          QibraStatusKind.loading => s.loading,
        };
    final resolvedMessage = message ??
        switch (kind) {
          QibraStatusKind.offline => s.offlineHint,
          QibraStatusKind.error => s.unknown,
          _ => null,
        };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.textTertiary),
          const SizedBox(height: 12),
          Text(
            resolvedTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
          ),
          if (resolvedMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: AppA11y.minTapTarget,
              child: FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? s.retry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
