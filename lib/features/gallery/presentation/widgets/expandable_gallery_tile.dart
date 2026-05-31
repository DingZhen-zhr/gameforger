import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_utils.dart';
import '../../../home/providers/home_provider.dart';

/// An iOS 26 App Store-style expandable gallery tile.
///
/// Parent controls expansion state via [isExpanded] and [onTap].
/// When expanded, a frosted glass panel with a live game preview
/// slides open above the card.
class ExpandableGalleryTile extends ConsumerStatefulWidget {
  final ProjectModel project;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExpandableGalleryTile({
    super.key,
    required this.project,
    required this.isExpanded,
    required this.onTap,
    required this.onDelete,
  });

  @override
  ConsumerState<ExpandableGalleryTile> createState() =>
      _ExpandableGalleryTileState();
}

class _ExpandableGalleryTileState extends ConsumerState<ExpandableGalleryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: GlassUtils.iosSpringCurve,
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    // If starting expanded, jump to end
    if (widget.isExpanded) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant ExpandableGalleryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _ctrl.forward();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daysAgo = DateTime.now().difference(widget.project.updatedAt).inDays;
    final timeStr = daysAgo == 0
        ? '今天'
        : daysAgo == 1
        ? '昨天'
        : '$daysAgo 天前';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _expandAnim.value;
        final previewHeight = 250.0 * t;
        final panelOpacity = _fadeAnim.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: widget.isExpanded ? 12 : 8,
            left: widget.isExpanded ? 2 : 0,
            right: widget.isExpanded ? 2 : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (t > 0.01) _buildPreviewPanel(previewHeight, panelOpacity, t),
              _buildCard(timeStr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewPanel(double height, double opacity, double t) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
        child: Container(
          height: height.clamp(0, 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceVariant.withValues(alpha: 0.85),
                AppTheme.surfaceDark.withValues(alpha: 0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ClipRect(
            child: height < 96
                ? const SizedBox.shrink()
                : Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: _buildPreviewContent(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Stack(
      children: [
        // Static cover with gradient, icon, and project info
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.tabGallery.withValues(alpha: 0.16),
                AppTheme.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.tabGallery.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppTheme.tabGallery,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.project.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  '轻触打开完整预览',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // Open full preview button
        Positioned(
          right: 8,
          top: 8,
          child: _MiniGlassButton(
            icon: Icons.open_in_full,
            label: '完整预览',
            onTap: () => context.push('/project/${widget.project.id}/preview'),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String timeStr) {
    return Dismissible(
      key: ValueKey(widget.project.id),
      direction: widget.isExpanded
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: _GlassTileCard(
        project: widget.project,
        timeStr: timeStr,
        isExpanded: widget.isExpanded,
        onTap: widget.onTap,
      ),
    );
  }
}

class _GlassTileCard extends StatefulWidget {
  final ProjectModel project;
  final String timeStr;
  final bool isExpanded;
  final VoidCallback onTap;

  const _GlassTileCard({
    required this.project,
    required this.timeStr,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_GlassTileCard> createState() => _GlassTileCardState();
}

class _GlassTileCardState extends State<_GlassTileCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.tabGallery.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppTheme.tabGallery,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.timeStr} 生成',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: GlassUtils.iosSpringCurve,
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textTertiary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny frosted glass button for the preview overlay.
class _MiniGlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniGlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: AppTheme.glassTinted,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: AppTheme.textPrimary),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
