import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CosmicBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;

  const CosmicBackground({
    super.key,
    required this.child,
    this.safeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        const Positioned.fill(child: _CosmicBackdrop()),
        Positioned.fill(child: child),
      ],
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}

class _CosmicBackdrop extends StatelessWidget {
  const _CosmicBackdrop();

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.isLight
        ? [const Color(0xFFFBF8F0), AppTheme.bgDark, const Color(0xFFECE4D5)]
        : [const Color(0xFF17140F), AppTheme.bgDark, const Color(0xFF0E0C09)];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ),
      ),
      child: CustomPaint(painter: _PaperGrainPainter()),
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 42; i++) {
      final x = ((i * 37) % 101) / 100;
      final y = ((i * 61) % 97) / 96;
      paint.color = AppTheme.textPrimary.withValues(
        alpha: i.isEven ? 0.018 : 0.01,
      );
      canvas.drawCircle(Offset(size.width * x, size.height * y), 0.65, paint);
    }

    final wash = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.85, size.height * 0.08),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08),
      size.width * 0.7,
      wash,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForgeGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? accent;
  final double accentOpacity;
  final double borderOpacity;
  final bool glow;
  final VoidCallback? onTap;

  const ForgeGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.accent = Colors.white,
    this.accentOpacity = 0.045,
    this.borderOpacity = 0.09,
    this.glow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(
              alpha: AppTheme.isLight ? 0.78 : 0.86,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: AppTheme.isLight ? 0.28 : 0.06),
                (accent ?? AppTheme.textPrimary).withValues(
                  alpha: accentOpacity,
                ),
                AppTheme.surfaceVariant.withValues(
                  alpha: AppTheme.isLight ? 0.16 : 0.1,
                ),
              ],
              stops: const [0.0, 0.46, 1.0],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: AppTheme.textPrimary.withValues(
                alpha: AppTheme.isLight ? 0.13 : 0.18,
              ),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.glassShadow.withValues(
                  alpha: glow ? 0.46 : 0.16,
                ),
                blurRadius: glow ? 24 : 12,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: AppTheme.isLight ? 0.2 : 0.04,
                ),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: AppTheme.isLight ? 0.12 : 0.04,
                        ),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class ForgeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accent;
  final double size;
  final double iconSize;
  final bool glow;
  final String? tooltip;

  const ForgeIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.accent,
    this.size = 38,
    this.iconSize = 18,
    this.glow = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? AppTheme.primary;
    final button = CupertinoButton(
      minimumSize: Size(size, size),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      onPressed: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: glow
              ? effectiveAccent.withValues(
                  alpha: AppTheme.isLight ? 0.88 : 0.82,
                )
              : AppTheme.surfaceDark.withValues(
                  alpha: AppTheme.isLight ? 0.48 : 0.22,
                ),
          gradient: glow
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    effectiveAccent,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(
                      alpha: AppTheme.isLight ? 0.36 : 0.11,
                    ),
                    Colors.white.withValues(
                      alpha: AppTheme.isLight ? 0.08 : 0.02,
                    ),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (glow ? effectiveAccent : AppTheme.textPrimary).withValues(
              alpha: glow ? 0.34 : 0.22,
            ),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glassShadow.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: glow ? AppTheme.primaryContainer : AppTheme.textPrimary,
          size: iconSize,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class ForgePrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? accent;
  final bool compact;

  const ForgePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? AppTheme.primary;
    return CupertinoButton(
      minimumSize: Size(compact ? 36 : 64, compact ? 36 : 52),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(compact ? 13 : 18),
      onPressed: onPressed,
      child: Container(
        height: compact ? 36 : 52,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 13 : 18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: onPressed == null
                ? [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ]
                : [effectiveAccent, effectiveAccent],
          ),
          border: Border.all(
            color: onPressed == null
                ? Colors.white.withValues(alpha: 0.08)
                : effectiveAccent.withValues(alpha: 0.3),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveAccent.withValues(
                alpha: onPressed == null ? 0 : 0.26,
              ),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 1,
              left: 8,
              right: 8,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.white, size: compact ? 15 : 19),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ForgeChipTone {
  neutral,
  online,
  offline,
  violet,
  cyan,
  gold,
  draft,
  danger,
}

class ForgeChip extends StatelessWidget {
  final String label;
  final ForgeChipTone tone;
  final bool dot;
  final IconData? icon;

  const ForgeChip({
    super.key,
    required this.label,
    this.tone = ForgeChipTone.neutral,
    this.dot = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _chipColors(tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.dot,
                boxShadow: [
                  BoxShadow(
                    color: colors.dot.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color border, Color fg, Color dot}) _chipColors(
    ForgeChipTone tone,
  ) {
    switch (tone) {
      case ForgeChipTone.online:
        return (
          bg: AppTheme.primary.withValues(alpha: 0.14),
          border: AppTheme.primary.withValues(alpha: 0.36),
          fg: AppTheme.primary,
          dot: AppTheme.online,
        );
      case ForgeChipTone.offline:
        return (
          bg: Colors.transparent,
          border: AppTheme.textPrimary.withValues(alpha: 0.18),
          fg: AppTheme.textTertiary,
          dot: AppTheme.textTertiary,
        );
      case ForgeChipTone.violet:
        return (
          bg: AppTheme.primary.withValues(alpha: 0.14),
          border: AppTheme.primary.withValues(alpha: 0.36),
          fg: AppTheme.primary,
          dot: AppTheme.primary,
        );
      case ForgeChipTone.cyan:
        return (
          bg: Colors.transparent,
          border: AppTheme.textPrimary.withValues(alpha: 0.18),
          fg: AppTheme.textSecondary,
          dot: AppTheme.primary,
        );
      case ForgeChipTone.gold:
        return (
          bg: AppTheme.gold.withValues(alpha: 0.14),
          border: AppTheme.gold.withValues(alpha: 0.36),
          fg: AppTheme.gold,
          dot: AppTheme.gold,
        );
      case ForgeChipTone.draft:
        return (
          bg: Colors.transparent,
          border: AppTheme.textPrimary.withValues(alpha: 0.18),
          fg: AppTheme.textTertiary,
          dot: AppTheme.textTertiary,
        );
      case ForgeChipTone.danger:
        return (
          bg: AppTheme.error.withValues(alpha: 0.12),
          border: AppTheme.error.withValues(alpha: 0.32),
          fg: AppTheme.error,
          dot: AppTheme.error,
        );
      case ForgeChipTone.neutral:
        return (
          bg: Colors.transparent,
          border: AppTheme.textPrimary.withValues(alpha: 0.18),
          fg: AppTheme.textSecondary,
          dot: AppTheme.primary,
        );
    }
  }
}

class ForgeEnergyBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const ForgeEnergyBar({
    super.key,
    required this.value,
    this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: Colors.white.withValues(alpha: 0.08),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: effectiveColor == AppTheme.gold
                      ? [AppTheme.gold, const Color(0xFFFFE7B0)]
                      : [effectiveColor, AppTheme.cyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.7),
                    blurRadius: 8,
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

class NebulaOrb extends StatefulWidget {
  final double size;
  final bool spin;

  const NebulaOrb({super.key, this.size = 96, this.spin = true});

  @override
  State<NebulaOrb> createState() => _NebulaOrbState();
}

class _NebulaOrbState extends State<NebulaOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.spin) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant NebulaOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spin && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spin && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return CustomPaint(
            painter: _NebulaOrbPainter(
              phase: widget.spin ? _controller.value : 0.08,
            ),
          );
        },
      ),
    );
  }
}

class _NebulaOrbPainter extends CustomPainter {
  final double phase;

  const _NebulaOrbPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withValues(alpha: 0.62),
          AppTheme.secondary.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18));
    canvas.drawCircle(center, radius * 1.08, glow);

    final core = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white,
          Color(0xFFC8B8FF),
          AppTheme.primary,
          AppTheme.primaryContainer,
        ],
        stops: [0.0, 0.2, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.34));
    canvas.drawCircle(center, radius * 0.24, core);

    _drawRing(
      canvas,
      center,
      radius,
      -0.38 + phase * math.pi * 2,
      AppTheme.primary.withValues(alpha: 0.58),
      radius * 0.92,
      radius * 0.28,
      radius * 0.014,
    );
    _drawRing(
      canvas,
      center,
      radius,
      0.62 - phase * math.pi * 1.55,
      AppTheme.secondary.withValues(alpha: 0.48),
      radius * 0.88,
      radius * 0.4,
      radius * 0.012,
    );
    _drawRing(
      canvas,
      center,
      radius,
      1.18 + phase * math.pi * 1.05,
      Colors.white.withValues(alpha: 0.22),
      radius * 0.95,
      radius * 0.13,
      radius * 0.009,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
    double rx,
    double ry,
    double width,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      paint,
    );
    final nodePaint = Paint()..color = color.withValues(alpha: 1);
    canvas.drawCircle(Offset(rx, 0), math.max(width * 1.7, 1.0), nodePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NebulaOrbPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class NebulaSeed extends StatelessWidget {
  final double size;
  final int hue;
  final Color? accent;

  const NebulaSeed({super.key, this.size = 44, this.hue = 0, this.accent});

  @override
  Widget build(BuildContext context) {
    final base = accent ?? _accentFromHue(hue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        color: base.withValues(alpha: 0.12),
        border: Border.all(color: base.withValues(alpha: 0.36), width: 0.7),
      ),
      child: CustomPaint(painter: _NebulaSeedPainter(base)),
    );
  }

  Color _accentFromHue(int hue) {
    final colors = [
      AppTheme.primary,
      AppTheme.textSecondary,
      AppTheme.primary,
      AppTheme.gold,
      AppTheme.textTertiary,
    ];
    return colors[hue.abs() % colors.length];
  }
}

class ForgeAppMark extends StatelessWidget {
  final double size;

  const ForgeAppMark({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        color: AppTheme.surfaceDark.withValues(
          alpha: AppTheme.isLight ? 0.82 : 0.74,
        ),
        border: Border.all(
          color: AppTheme.textPrimary.withValues(alpha: 0.18),
          width: 0.7,
        ),
      ),
      child: CustomPaint(painter: _ForgeAppMarkPainter()),
    );
  }
}

class _ForgeAppMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.55 * unit;

    final green = AppTheme.primary;
    final text = AppTheme.textPrimary;

    paint.color = green;
    final blade = Path()
      ..moveTo(6.5 * unit, 16.5 * unit)
      ..lineTo(6.5 * unit, 7.5 * unit)
      ..lineTo(13.8 * unit, 7.5 * unit)
      ..moveTo(6.5 * unit, 12 * unit)
      ..lineTo(12 * unit, 12 * unit);
    canvas.drawPath(blade, paint);

    paint.color = text.withValues(alpha: 0.92);
    final spark = Path()
      ..moveTo(15.7 * unit, 7.2 * unit)
      ..lineTo(18.2 * unit, 9.7 * unit)
      ..lineTo(15.7 * unit, 12.2 * unit)
      ..lineTo(13.2 * unit, 9.7 * unit)
      ..close();
    canvas.drawPath(spark, paint);

    paint.color = green.withValues(alpha: 0.75);
    canvas.drawLine(
      Offset(15 * unit, 16.5 * unit),
      Offset(19 * unit, 16.5 * unit),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NebulaSeedPainter extends CustomPainter {
  final Color color;
  const _NebulaSeedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width * 0.44,
          height: size.height * 0.44,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawCircle(center, size.width * 0.045, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NebulaSeedPainter oldDelegate) =>
      oldDelegate.color != color;
}

class StarRingLoader extends StatefulWidget {
  final double size;
  final String? label;

  const StarRingLoader({super.key, this.size = 64, this.label});

  @override
  State<StarRingLoader> createState() => _StarRingLoaderState();
}

class _StarRingLoaderState extends State<StarRingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return Transform.rotate(
            angle: _controller.value * math.pi * 2,
            child: CustomPaint(painter: _StarRingPainter()),
          );
        },
      ),
    );
    if (widget.label == null) return ring;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ring,
        const SizedBox(height: 14),
        Text(
          widget.label!,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StarRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.39;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppTheme.secondary,
          AppTheme.primary,
          Colors.transparent,
        ],
      ).createShader(rect)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.15, false, paint);
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      1.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForgeSectionLabel extends StatelessWidget {
  final String title;
  final String? trailing;

  const ForgeSectionLabel({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10.5,
                letterSpacing: 0.6,
              ),
            ),
        ],
      ),
    );
  }
}
