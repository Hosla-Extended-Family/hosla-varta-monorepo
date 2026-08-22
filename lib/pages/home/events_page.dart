import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/friends_page.dart';
import 'package:hosla/pages/home/notifications_page.dart';
import 'package:hosla/widgets/glass_app_bar.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        titleText: 'Events',
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: ThemeColors.getNavBarIconColor(context),
              size: 24,
            ),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              color: ThemeColors.getNavBarIconColor(context),
              size: 24,
            ),
            tooltip: 'Add Friends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsPage()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              // Icon container with soft glow
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 54,
                    color: ThemeColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Coming soon pill badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'COMING SOON',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: ThemeColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Community Events',
                style: TextThemes.getTitleStyle(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: ThemeColors.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'We are building an interactive events experience for you to explore local workshops, community meetups, wellness sessions, and social gatherings.',
                textAlign: TextAlign.center,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 28),
              // Feature highlights card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ThemeColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : ThemeColors.getOverlayColor(context, opacity: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      Icons.groups_outlined,
                      'Local Gatherings',
                      'Connect with elders and neighbors nearby',
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildFeatureItem(
                      context,
                      Icons.self_improvement_outlined,
                      'Health & Wellness',
                      'Yoga, walking clubs, and wellness workshops',
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildFeatureItem(
                      context,
                      Icons.celebration_outlined,
                      'Cultural & Social Events',
                      'Festival celebrations and community talks',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ThemeColors.primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: ThemeColors.getTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  fontSize: 12,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
