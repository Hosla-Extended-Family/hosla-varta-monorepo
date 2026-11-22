import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

/// Modern loading widget with indicator and text
class LoadingWidget extends StatelessWidget {
  final String message;
  final double? size;

  const LoadingWidget({super.key, this.message = 'Loading...', this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.getSecondaryTextColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
