import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class ListTileWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ListTileWidget({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Constants.defaultPadding / 4,
      child: ListTile(
        title: Text(title, style: TextThemes.getBodyMediumStyle(context)),
        tileColor: ThemeColors.getSurfaceColor(context),
        onTap: onTap,
        selectedTileColor: ThemeColors.getOverlayColor(context, opacity: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: ThemeColors.getSecondaryTextColor(context)),
      ),
    );
  }
}
