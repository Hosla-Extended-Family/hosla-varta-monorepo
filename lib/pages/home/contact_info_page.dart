import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT INFO PAGE — Modernised
//
// Replaces the old WhatsApp-style flat sections with:
//   • Gradient hero header with avatar, name, status
//   • Rounded card sections with Hosla design tokens
//   • Teal accents, Quicksand font, rounded corners
//   • Consistent with Edit Profile, User Profile View pages
// ─────────────────────────────────────────────────────────────────────────────

class ContactInfoPage extends ConsumerWidget {
  final User user;
  final List<String>? mutualGroups;

  const ContactInfoPage({super.key, required this.user, this.mutualGroups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Hero header ──
          _buildSliverHeader(context),

          // ── Profile card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildProfileCard(context),
            ),
          ),

          // ── About section ──
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildAboutCard(context),
              ),
            ),

          // ── Quick actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildActionsCard(context),
            ),
          ),

          // ── Mutual groups ──
          if (mutualGroups != null && mutualGroups!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildMutualGroupsCard(context),
              ),
            ),

          // ── Danger zone ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: _buildDangerCard(context),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: ThemeColors.getNavBarColor(context),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => _showMoreOptions(context),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(180),
                    ThemeColors.secondaryColor,
                  ],
                ),
              ),
            ),

            // Dot pattern overlay
            Positioned.fill(child: CustomPaint(painter: _DotOverlayPainter())),

            // Bottom fade
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // Avatar + info at bottom
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => _viewFullImage(context),
                    child: Hero(
                      tag: 'contact_${user.id}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty
                              ? Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _defaultAvatar(36),
                                )
                              : _defaultAvatar(36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? ThemeColors.primaryColor
                                    : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        children: [
          if (user.email != null && user.email!.isNotEmpty)
            _infoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email!,
            ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            _divider(context),
            _infoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone!,
            ),
          ],
          if ((user.email == null || user.email!.isEmpty) &&
              (user.phone == null || user.phone!.isEmpty))
            _infoRow(
              context,
              icon: Icons.info_outline_rounded,
              label: 'Contact',
              value: 'No contact info available',
            ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: ThemeColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            user.bio!,
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(height: 1.5, color: ThemeColors.getTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return _card(
      context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _actionTile(
            context,
            icon: Icons.image_outlined,
            label: 'Media, Links & Docs',
            trailing: '0',
            onTap: () {},
          ),
          _divider(context),
          _actionTile(
            context,
            icon: Icons.star_outline_rounded,
            label: 'Starred Messages',
            onTap: () {},
          ),
          _divider(context),
          _actionTile(
            context,
            icon: Icons.search_rounded,
            label: 'Search in Chat',
            onTap: () {},
          ),
          _divider(context),
          _actionTile(
            context,
            icon: Icons.notifications_outlined,
            label: 'Mute Notifications',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMutualGroupsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.group_rounded,
                size: 18,
                color: ThemeColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${mutualGroups!.length} group${mutualGroups!.length > 1 ? 's' : ''} in common',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _card(
          context,
          padding: EdgeInsets.zero,
          child: Column(
            children: mutualGroups!.asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              return Column(
                children: [
                  _actionTile(
                    context,
                    icon: Icons.group_rounded,
                    label: group,
                    onTap: () {},
                  ),
                  if (index < mutualGroups!.length - 1) _divider(context),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerCard(BuildContext context) {
    return _card(
      context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _actionTile(
            context,
            icon: Icons.block_rounded,
            label: 'Block ${user.name.split(' ').first}',
            iconColor: ThemeColors.errorColor,
            textColor: ThemeColors.errorColor,
            onTap: () => _showBlockDialog(context),
          ),
          _divider(context),
          _actionTile(
            context,
            icon: Icons.thumb_down_outlined,
            label: 'Report Contact',
            iconColor: ThemeColors.errorColor,
            textColor: ThemeColors.errorColor,
            onTap: () => _showReportDialog(context),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.25),
        ),
      ),
      child: child,
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ThemeColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? trailing,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? ThemeColors.primaryColor).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? ThemeColors.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    trailing,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
    );
  }

  Widget _defaultAvatar(double iconSize) {
    return Container(
      color: ThemeColors.primaryColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _viewFullImage(BuildContext context) {
    if (user.avatarUrl == null || user.avatarUrl!.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(user.avatarUrl!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeColors.getSecondaryTextColor(
                      ctx,
                    ).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _sheetTile(
                ctx,
                Icons.share_rounded,
                'Share Contact',
                onTap: () => Navigator.pop(ctx),
              ),
              _sheetTile(
                ctx,
                Icons.edit_rounded,
                'Edit Contact',
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(
    BuildContext context,
    IconData icon,
    String label, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? ThemeColors.errorColor
            : ThemeColors.primaryColor,
      ),
      title: Text(
        label,
        style: TextThemes.getBodyMediumStyle(context).copyWith(
          color: isDestructive
              ? ThemeColors.errorColor
              : ThemeColors.getTextColor(context),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeColors.getCardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Block ${user.name.split(' ').first}?',
          style: TextThemes.getTitleStyle(
            ctx,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Blocked contacts will no longer be able to message you.',
          style: TextThemes.getBodyMediumStyle(ctx).copyWith(
            color: ThemeColors.getSecondaryTextColor(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(ctx),
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Block user
            },
            child: const Text(
              'Block',
              style: TextStyle(
                color: ThemeColors.errorColor,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeColors.getCardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Report this contact?',
          style: TextThemes.getTitleStyle(
            ctx,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'The last 5 messages will be forwarded to Hosla Varta. This contact will not be notified.',
          style: TextThemes.getBodyMediumStyle(ctx).copyWith(
            color: ThemeColors.getSecondaryTextColor(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(ctx),
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Report user
            },
            child: const Text(
              'Report',
              style: TextStyle(
                color: ThemeColors.errorColor,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Dot pattern overlay painter (matches app's design language)
// ═══════════════════════════════════════════════════════════════════

class _DotOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (
        double x = (y ~/ spacing).isEven ? 0 : spacing / 2;
        x < size.width;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
