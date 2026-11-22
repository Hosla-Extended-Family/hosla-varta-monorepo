import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/glass_container.dart';

/// A reusable glassmorphic [AppBar] that applies a consistent frosted-glass
/// look across the app.
///
/// Wraps [GlassContainer] inside a [PreferredSize] so it can be used directly
/// as [Scaffold.appBar]. All pages (Feed, Events, Chat, Emergency, etc.)
/// should use this widget to maintain visual continuity.
///
/// Usage:
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: GlassAppBar(title: 'Events', actions: [...]),
///   body: ...,
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title displayed in the app bar.
  final String? titleText;

  /// Optional custom title widget. Takes precedence over [titleText].
  final Widget? title;

  /// Action buttons on the right side.
  final List<Widget>? actions;

  /// Optional leading widget (back button, etc.).
  final Widget? leading;

  /// Whether to show back button automatically.
  final bool automaticallyImplyLeading;

  /// Whether to center the title.
  final bool centerTitle;

  /// Optional bottom widget (e.g. TabBar).
  final PreferredSizeWidget? bottom;

  /// Height of the app bar (excluding bottom). Defaults to [kToolbarHeight].
  final double toolbarHeight;

  const GlassAppBar({
    super.key,
    this.titleText,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveTitle =
        title ??
        (titleText != null
            ? ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [ThemeColors.primaryColor, ThemeColors.primaryColor],
                ).createShader(bounds),
                child: Text(
                  titleText!,
                  style: TextThemes.getTitleStyle(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              )
            : null);

    return GlassContainer(
      blurSigma: 20,
      opacity: 0.7,
      child: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: toolbarHeight,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: ThemeColors.getNavBarIconColor(context),
        ),
        title: effectiveTitle,
        leading: leading,
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}
