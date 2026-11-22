import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarWidget {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final config = _getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [config.color, config.color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(config.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Text(
                message,
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2428),
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: SnackBarType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: SnackBarType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: SnackBarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: SnackBarType.info);
  }

  static _SnackBarConfig _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          icon: Icons.check_circle_rounded,
          color: ThemeColors.successColor,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          icon: Icons.error_rounded,
          color: ThemeColors.errorColor,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          icon: Icons.warning_rounded,
          color: ThemeColors.warningColor,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          icon: Icons.info_rounded,
          color: ThemeColors.primaryColor,
        );
    }
  }
}

class _SnackBarConfig {
  final IconData icon;
  final Color color;

  _SnackBarConfig({required this.icon, required this.color});
}
