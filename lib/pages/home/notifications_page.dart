import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/glass_app_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: true,
        titleText: 'Notifications',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 48,
                  color: ThemeColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Notifications Yet',
                style: TextThemes.getTitleStyle(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up! New updates, friend requests, and alerts will appear here.',
                textAlign: TextAlign.center,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
