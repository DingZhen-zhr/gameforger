import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;
  final Color tintColor;
  final Color? surfaceColor;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blurSigma = 24,
    this.tintOpacity = 0.14,
    this.borderOpacity = 0.18,
    this.tintColor = Colors.white,
    this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            gradient: LinearGradient(
              colors: [
                tintColor.withValues(alpha: tintOpacity),
                tintColor.withValues(alpha: tintOpacity * 0.72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GlassSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const GlassSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class GlassMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color accent;
  final VoidCallback? onTap;

  const GlassMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(14),
      surfaceColor: Colors.white.withValues(alpha: 0.02),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(onTap: onTap, child: content);
  }
}

class GlassTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color accent;

  const GlassTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.accent,
  });
}

class FloatingGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<GlassTabItem> items;

  const FloatingGlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LiquidGlassSurface(
          borderRadius: BorderRadius.circular(30),
          blurSigma: 26,
          tintOpacity: 0.18,
          borderOpacity: 0.16,
          surfaceColor: Colors.white.withValues(alpha: 0.02),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? item.accent.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: selected
                          ? Border.all(
                              color: item.accent.withValues(alpha: 0.22),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: selected
                              ? item.accent
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: selected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            height: 1.0,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
