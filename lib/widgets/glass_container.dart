import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';

/// A reusable glassmorphic container with consistent blur, opacity, and border
/// styling across the app.
///
/// Use this for app bars, floating panels, bottom sheets, and any surface that
/// needs the frosted-glass look.
class GlassContainer extends StatelessWidget {
  /// Child widget rendered inside the glass surface.
  final Widget child;

  /// Border radius applied to the container. Defaults to no rounding.
  final BorderRadius borderRadius;

  /// Blur sigma for the backdrop filter (both X and Y). Higher = more frosted.
  final double blurSigma;

  /// Opacity multiplier applied to the theme's nav-bar colour.
  /// 0.0 = fully transparent, 1.0 = fully opaque.
  final double opacity;

  /// Optional border. When null a subtle 1 px border matching the theme's
  /// border colour at 30 % opacity is drawn.
  final Border? border;

  /// Optional padding inside the glass surface.
  final EdgeInsetsGeometry? padding;

  /// Optional margin outside the glass surface.
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.blurSigma = 20,
    this.opacity = 0.7,
    this.border,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = ThemeColors.getNavBarColor(context);
    final borderColor =
        ThemeColors.getBorderColor(context).withValues(alpha: isDark ? 0.2 : 0.15);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: opacity),
              borderRadius: borderRadius,
              border: border ??
                  Border.all(
                    color: borderColor,
                    width: 0.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
