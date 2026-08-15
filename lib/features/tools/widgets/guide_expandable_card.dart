import 'package:flutter/material.dart';

/// Shared animated/tappable shell for expandable cards in guide screens.
class GuideExpandableCard extends StatelessWidget {
  const GuideExpandableCard({
    super.key,
    required this.isExpanded,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  final bool isExpanded;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded
              ? accentColor.withValues(alpha: 0.06)
              : const Color(0xFF141926),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? accentColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: child,
      ),
    );
  }
}
