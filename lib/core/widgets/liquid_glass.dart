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
    final borderColor = AppTheme.textPrimary.withValues(
      alpha: AppTheme.isLight ? borderOpacity * 0.72 : borderOpacity,
    );
    final highlight = Colors.white.withValues(
      alpha: AppTheme.isLight ? tintOpacity * 2.0 : tintOpacity * 0.92,
    );
    final baseTint = tintColor.withValues(alpha: tintOpacity);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color:
                surfaceColor ??
                AppTheme.surfaceDark.withValues(
                  alpha: AppTheme.isLight ? 0.56 : 0.5,
                ),
            gradient: LinearGradient(
              colors: [
                highlight,
                baseTint,
                AppTheme.surfaceVariant.withValues(
                  alpha: AppTheme.isLight ? 0.26 : 0.2,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.46, 1.0],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.glassShadow.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: AppTheme.isLight ? 0.34 : 0.08,
                ),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 1,
                left: 10,
                right: 10,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: AppTheme.isLight ? 0.48 : 0.16,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
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
                  style: TextStyle(
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
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: TextStyle(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 220) return;
        final next = velocity < 0 ? currentIndex + 1 : currentIndex - 1;
        if (next >= 0 && next < items.length) {
          onChanged(next);
        }
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withValues(
                alpha: AppTheme.isLight ? 0.84 : 0.9,
              ),
              border: Border(
                top: BorderSide(
                  color: AppTheme.textPrimary.withValues(
                    alpha: AppTheme.isLight ? 0.16 : 0.2,
                  ),
                  width: 0.6,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glassShadow.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              8,
              10,
              8,
              MediaQuery.paddingOf(context).bottom + 8,
            ),
            child: SizedBox(
              height: 48,
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(index),
                      child: AnimatedScale(
                        scale: selected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              top: selected ? -10 : -4,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: selected ? 1 : 0,
                                child: Container(
                                  width: 14,
                                  height: 2,
                                  color: item.accent,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? item.accent.withValues(alpha: 0.10)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    selected ? item.selectedIcon : item.icon,
                                    size: 20,
                                    color: selected
                                        ? item.accent
                                        : AppTheme.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label.toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? item.accent
                                        : AppTheme.textTertiary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    height: 1.0,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
