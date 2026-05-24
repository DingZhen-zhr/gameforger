import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// iOS 26 Liquid Glass utility helpers.
class GlassUtils {
  GlassUtils._();

  /// The iOS spring curve used throughout iOS 26 for card expansions.
  static const Curve iosSpringCurve = Cubic(0.25, 0.1, 0.25, 1);

  /// Wraps [child] in a BackdropFilter + ClipRRect + gradient overlay
  /// to produce the iOS 26 Liquid Glass look.
  ///
  /// [sigma] controls blur intensity (default 16, range 12-20).
  /// [borderRadius] controls corner rounding (default 20).
  /// [tintOpacity] controls how much white overlay (0-1, default 0.16).
  static Widget applyGlass({
    required Widget child,
    double sigma = 16,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(20)),
    double borderOpacity = 0.20,
    double tintOpacity = 0.16,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: tintOpacity),
                Colors.white.withValues(alpha: tintOpacity * 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: borderOpacity > 0
                ? Border.all(
                    color: Colors.white.withValues(alpha: borderOpacity),
                    width: 1,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Returns a [BoxDecoration] for a glass surface.
  /// Use this when you need a decoration for a Container that sits
  /// inside a BackdropFilter.
  static BoxDecoration glassDecoration({
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(20)),
    bool withBorder = true,
    double tintOpacity = 0.16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: tintOpacity),
          Colors.white.withValues(alpha: tintOpacity * 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: withBorder
          ? Border.all(
              color: AppTheme.glassBorder,
              width: 1,
            )
          : null,
      borderRadius: borderRadius,
    );
  }

  /// A thin, semi-transparent separator line for glass panels.
  static BorderSide get glassSeparator => BorderSide(
        color: Colors.white.withValues(alpha: 0.08),
        width: 0.5,
      );

  /// Wraps [child] with a 1px glass border edge using a thin Container
  /// to create definition for glass panels against busy backgrounds.
  static Widget glassEdge({required Widget child, double borderRadius = 20}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: child,
    );
  }
}
