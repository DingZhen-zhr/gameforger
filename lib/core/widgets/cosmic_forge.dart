import 'dart:math' as math;
import 'dart:ui';

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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        gradient: RadialGradient(
          center: Alignment(-0.72, -0.78),
          radius: 0.86,
          colors: [Color(0x3F7B5CFF), Color(0x160A0916), AppTheme.bgDark],
          stops: [0, 0.48, 1],
        ),
      ),
      child: CustomPaint(painter: _StarFieldPainter()),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stars = <({double x, double y, double r, double a})>[
      (x: 0.12, y: 0.18, r: 1.2, a: 0.62),
      (x: 0.82, y: 0.13, r: 0.8, a: 0.48),
      (x: 0.68, y: 0.28, r: 1.1, a: 0.38),
      (x: 0.22, y: 0.43, r: 0.7, a: 0.44),
      (x: 0.91, y: 0.47, r: 1.0, a: 0.34),
      (x: 0.44, y: 0.64, r: 0.9, a: 0.36),
      (x: 0.14, y: 0.78, r: 1.0, a: 0.42),
      (x: 0.78, y: 0.83, r: 0.7, a: 0.32),
    ];
    for (final star in stars) {
      paint.color = Colors.white.withValues(alpha: star.a);
      canvas.drawCircle(
        Offset(size.width * star.x, size.height * star.y),
        star.r,
        paint,
      );
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.secondary.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.82, size.height * 0.22),
              radius: size.width * 0.62,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.22),
      size.width * 0.62,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForgeGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color accent;
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
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.065),
                accent.withValues(alpha: accentOpacity),
                Colors.white.withValues(alpha: 0.028),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              if (glow)
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Padding(padding: padding, child: child),
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
  final Color accent;
  final double size;
  final double iconSize;
  final bool glow;
  final String? tooltip;

  const ForgeIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.accent = AppTheme.primary,
    this.size = 38,
    this.iconSize = 18,
    this.glow = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: CupertinoButton(
          minimumSize: Size(size, size),
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: glow
                    ? [
                        accent.withValues(alpha: 0.34),
                        accent.withValues(alpha: 0.14),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.075),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              border: Border.all(
                color: glow
                    ? accent.withValues(alpha: 0.42)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.8,
              ),
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.36),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: glow ? Colors.white : AppTheme.textPrimary,
              size: iconSize,
            ),
          ),
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
  final Color accent;
  final bool compact;

  const ForgePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accent = AppTheme.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
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
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.03),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.2),
                    accent.withValues(alpha: 0.9),
                    AppTheme.primaryContainer.withValues(alpha: 0.96),
                  ],
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: onPressed == null ? 0.08 : 0.2,
            ),
            width: 0.8,
          ),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.42),
                    blurRadius: compact ? 14 : 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              fontWeight: FontWeight.w700,
              height: 1.0,
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
          bg: AppTheme.online.withValues(alpha: 0.1),
          border: AppTheme.online.withValues(alpha: 0.32),
          fg: const Color(0xFF9AF5C8),
          dot: AppTheme.online,
        );
      case ForgeChipTone.offline:
        return (
          bg: Colors.white.withValues(alpha: 0.06),
          border: Colors.white.withValues(alpha: 0.12),
          fg: AppTheme.textTertiary,
          dot: AppTheme.textTertiary,
        );
      case ForgeChipTone.violet:
        return (
          bg: AppTheme.primary.withValues(alpha: 0.14),
          border: const Color(0xFF9A7DFF).withValues(alpha: 0.36),
          fg: const Color(0xFFCBB8FF),
          dot: const Color(0xFF9A7DFF),
        );
      case ForgeChipTone.cyan:
        return (
          bg: AppTheme.secondary.withValues(alpha: 0.12),
          border: AppTheme.secondary.withValues(alpha: 0.36),
          fg: AppTheme.cyan,
          dot: AppTheme.secondary,
        );
      case ForgeChipTone.gold:
        return (
          bg: AppTheme.gold.withValues(alpha: 0.14),
          border: AppTheme.gold.withValues(alpha: 0.36),
          fg: const Color(0xFFFFD99E),
          dot: AppTheme.gold,
        );
      case ForgeChipTone.draft:
        return (
          bg: Colors.white.withValues(alpha: 0.05),
          border: Colors.white.withValues(alpha: 0.12),
          fg: AppTheme.textTertiary,
          dot: AppTheme.textTertiary,
        );
      case ForgeChipTone.danger:
        return (
          bg: AppTheme.error.withValues(alpha: 0.12),
          border: AppTheme.error.withValues(alpha: 0.32),
          fg: const Color(0xFFFF8A96),
          dot: AppTheme.error,
        );
      case ForgeChipTone.neutral:
        return (
          bg: Colors.white.withValues(alpha: 0.07),
          border: Colors.white.withValues(alpha: 0.12),
          fg: AppTheme.textSecondary,
          dot: AppTheme.primary,
        );
    }
  }
}

class ForgeEnergyBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const ForgeEnergyBar({
    super.key,
    required this.value,
    this.color = AppTheme.primary,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
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
                  colors: color == AppTheme.gold
                      ? [AppTheme.gold, const Color(0xFFFFE7B0)]
                      : [color, AppTheme.cyan],
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
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
        colors: const [
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
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.38),
          colors: [
            Colors.white.withValues(alpha: 0.52),
            base.withValues(alpha: 0.88),
            AppTheme.primaryContainer.withValues(alpha: 0.98),
          ],
          stops: const [0, 0.38, 1],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(painter: _NebulaSeedPainter(base)),
    );
  }

  Color _accentFromHue(int hue) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      const Color(0xFF5BE7A7),
      AppTheme.gold,
      const Color(0xFFCBB8FF),
    ];
    return colors[hue.abs() % colors.length];
  }
}

class _NebulaSeedPainter extends CustomPainter {
  final Color color;
  const _NebulaSeedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.78,
        height: size.height * 0.24,
      ),
      paint,
    );
    canvas.restore();
    canvas.drawCircle(center, size.width * 0.07, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.66),
      size.width * 0.17,
      Paint()..color = color.withValues(alpha: 0.28),
    );
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
          style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
