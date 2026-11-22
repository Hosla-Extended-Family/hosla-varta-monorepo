import 'package:flutter/material.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

/// A clean, reusable card that displays a user's avatar, name, optional
/// subtitle and a trailing action widget. Used across Search results,
/// Friend Requests, and Friends lists.
class UserCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// An optional leading badge (e.g. incoming-request indicator).
  final Widget? badge;

  const UserCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConstants.resolveUrl(avatarUrl);
    final hasImage = resolvedUrl != null && resolvedUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // ── Avatar ──
              _buildAvatar(context, hasImage, resolvedUrl),
              const SizedBox(width: 14),

              // ── Name + subtitle ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          fontSize: 13,
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Action / trailing ──
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    bool hasImage,
    String? resolvedUrl,
  ) {
    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: ThemeColors.primaryColor.withValues(alpha: 0.12),
      backgroundImage: hasImage ? NetworkImage(resolvedUrl!) : null,
      child: hasImage
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: ThemeColors.primaryColor,
              ),
            ),
    );

    if (badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      );
    }

    return avatar;
  }
}
