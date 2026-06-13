import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cosmic_forge.dart';
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
    return Container(
      height: height.clamp(0, 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.18 * t),
            AppTheme.surfaceDark.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.22),
          width: 0.8,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: ClipRect(
        child: height < 96
            ? const SizedBox.shrink()
            : Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: _buildPreviewContent(),
              ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 1.1,
                colors: [
                  AppTheme.secondary.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.bgDark,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _TilePreviewPainter(widget.project.title.hashCode),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NebulaOrb(size: 58, spin: false),
                const SizedBox(height: 12),
                Text(
                  widget.project.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 8),
                ForgeChip(
                  label: '轻触打开完整预览',
                  tone: ForgeChipTone.cyan,
                  icon: Icons.open_in_full_rounded,
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
        child: Row(
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
        child: ForgeGlassCard(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(12),
          accent: widget.isExpanded ? AppTheme.secondary : AppTheme.primary,
          accentOpacity: widget.isExpanded ? 0.08 : 0.04,
          borderOpacity: widget.isExpanded ? 0.16 : 0.08,
          child: Row(
            children: [
              NebulaSeed(
                size: 56,
                hue: widget.project.title.hashCode,
                accent: widget.isExpanded
                    ? AppTheme.secondary
                    : AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.timeStr} 生成',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ForgeChip(label: '可玩', tone: ForgeChipTone.cyan),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: widget.isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 300),
                curve: GlassUtils.iosSpringCurve,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 18,
                ),
              ),
            ],
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
                    style: TextStyle(
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

class _TilePreviewPainter extends CustomPainter {
  final int seed;

  const _TilePreviewPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.secondary.withValues(alpha: 0.5)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.42 + i * 0.12);
      final path = Path()
        ..moveTo(size.width * 0.06, y)
        ..quadraticBezierTo(
          size.width * 0.5,
          y - 20 + (seed % 17),
          size.width * 0.94,
          y + 8,
        );
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      38,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppTheme.gold.withValues(alpha: 0.28),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.72, size.height * 0.28),
                radius: 46,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
