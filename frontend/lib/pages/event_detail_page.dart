import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/providers/event_provider.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENT DETAIL PAGE — Complete Redesign
//
// Layout (top → bottom):
//   1. GlassAppBar (back, share, more-options)
//   2. Cover image with gradient overlay + status badge
//   3. Title
//   4. Date / time · Location · Organizer info tiles
//   5. Participant stat bar
//   6. Tags
//   7. About description section (card)
//   8. Attendees preview card
//   9. Map placeholder card
//  10. Bottom action bar (Interested / Join)
// ─────────────────────────────────────────────────────────────────────────────

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  const EventDetailPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) {
    final userPreferences = ref.watch(userEventPreferencesProvider);
    final userStatus = userPreferences[event.id];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        centerTitle: true,
        titleText: 'Event Details',
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            tooltip: 'Share',
            onPressed: _shareEvent,
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            tooltip: 'More',
            onPressed: _showMoreOptions,
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        event: event,
        userStatus: userStatus,
        onToggleInterested: () => _toggleInterested(userStatus),
        onToggleGoing: () => _toggleGoing(userStatus),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover image ──
                  _CoverImage(imageUrl: event.imageUrl, userStatus: userStatus),
                  const SizedBox(height: 20),

                  // ── Title ──
                  Text(
                    event.title,
                    style: TextThemes.getTitleStyle(
                      context,
                    ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ── Date & Time ──
                  _InfoTile(
                    icon: Icons.calendar_today_rounded,
                    title: 'Date & Time',
                    value: '${event.formattedDate} at ${event.formattedTime}',
                  ),
                  const SizedBox(height: 12),

                  // ── Location ──
                  _InfoTile(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    value: event.location,
                    subtitle: event.address,
                  ),
                  const SizedBox(height: 12),

                  // ── Organizer ──
                  _InfoTile(
                    icon: Icons.person_rounded,
                    title: 'Organizer',
                    value: 'Event Organizer', // TODO: fetch real name
                  ),
                  const SizedBox(height: 20),

                  // ── Participant stats ──
                  _ParticipantStats(event: event),
                  const SizedBox(height: 16),

                  // ── Tags ──
                  if (event.tags.isNotEmpty) ...[
                    _TagsRow(tags: event.tags),
                    const SizedBox(height: 20),
                  ],

                  // ── About section ──
                  _SectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About This Event',
                          style: TextThemes.getBodyLargeStyle(
                            context,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.description,
                          style: TextThemes.getBodyMediumStyle(
                            context,
                          ).copyWith(height: 1.6, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Attendees preview ──
                  if (event.goingUserIds.isNotEmpty) ...[
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Attendees',
                                style: TextThemes.getBodyLargeStyle(context)
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '${event.goingUserIds.length} going',
                                style: TextThemes.getBodySmallStyle(context)
                                    .copyWith(
                                      color: ThemeColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _AvatarStack(count: event.goingUserIds.length),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Map placeholder ──
                  if (event.latitude != null && event.longitude != null) ...[
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: TextThemes.getBodyLargeStyle(context)
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: ThemeColors.getSurfaceColor(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 40,
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to open in maps',
                                    style: TextThemes.getBodySmallStyle(context)
                                        .copyWith(
                                          color:
                                              ThemeColors.getSecondaryTextColor(
                                                context,
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Actions ─────────────────

  void _toggleInterested(EventStatus? current) {
    if (current == EventStatus.interested) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(event.id);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markInterested(event.id);
    }
  }

  void _toggleGoing(EventStatus? current) {
    if (event.isFull && current != EventStatus.going) {
      SnackBarWidget.show(context, 'This event is full!');
      return;
    }
    if (current == EventStatus.going) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(event.id);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markGoing(event.id);
    }
  }

  void _shareEvent() {
    SnackBarWidget.show(context, 'Share functionality coming soon!');
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _optionTile(Icons.calendar_month_rounded, 'Add to Calendar'),
              _optionTile(Icons.report_outlined, 'Report Event'),
              _optionTile(Icons.block_rounded, 'Block Organizer'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: ThemeColors.primaryColor),
      title: Text(label, style: TextThemes.getBodyMediumStyle(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.pop(context),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Cover image with rounded corners and gradient overlay.
class _CoverImage extends StatelessWidget {
  final String? imageUrl;
  final EventStatus? userStatus;
  const _CoverImage({this.imageUrl, this.userStatus});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ThemeColors.primaryColor.withValues(alpha: 0.18),
                      ThemeColors.primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event_rounded,
                    size: 56,
                    color: ThemeColors.primaryColor.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          if (userStatus != null)
            Positioned(
              top: 12,
              right: 12,
              child: _StatusBadge(status: userStatus!),
            ),
        ],
      ),
    );
  }
}

/// Reusable info tile: icon-box + title + value.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: ThemeColors.primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal stat bar: Going / Interested / Max.
class _ParticipantStats extends StatelessWidget {
  final Event event;
  const _ParticipantStats({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _statColumn(
            context,
            '${event.goingUserIds.length}',
            'Going',
            ThemeColors.getSuccessColor(context),
          ),
          _divider(context),
          _statColumn(
            context,
            '${event.interestedUserIds.length}',
            'Interested',
            ThemeColors.getWarningColor(context),
          ),
          if (event.maxParticipants > 0) ...[
            _divider(context),
            _statColumn(
              context,
              '${event.maxParticipants}',
              'Max',
              ThemeColors.getTextColor(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(
    BuildContext context,
    String count,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextThemes.getBodyLargeStyle(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: ThemeColors.getBorderColor(context).withValues(alpha: 0.4),
    );
  }
}

/// Horizontal tags row.
class _TagsRow extends StatelessWidget {
  final List<String> tags;
  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ThemeColors.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '#$tag',
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Generic rounded-card wrapper.
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : ThemeColors.primaryColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Placeholder avatar stack for the attendees section.
class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final display = count > 5 ? 5 : count;
    final remaining = count - display;

    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < display; i++)
            Positioned(
              left: i * 28.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(
                    alpha: 0.15 + (i * 0.1).clamp(0.0, 0.5),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeColors.getCardColor(context),
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: ThemeColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: display * 28.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ThemeColors.getSurfaceColor(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status badge — consistent with events list page.
class _StatusBadge extends StatelessWidget {
  final EventStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String text, IconData icon) = switch (status) {
      EventStatus.going => (
        ThemeColors.getSuccessColor(context),
        'Going',
        Icons.check_circle_rounded,
      ),
      EventStatus.interested => (
        ThemeColors.getWarningColor(context),
        'Interested',
        Icons.star_rounded,
      ),
      EventStatus.notGoing => (
        ThemeColors.getSecondaryTextColor(context),
        'Not Going',
        Icons.close_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom action bar with Interested + Join buttons.
class _BottomActionBar extends StatelessWidget {
  final Event event;
  final EventStatus? userStatus;
  final VoidCallback onToggleInterested;
  final VoidCallback onToggleGoing;

  const _BottomActionBar({
    required this.event,
    required this.userStatus,
    required this.onToggleInterested,
    required this.onToggleGoing,
  });

  @override
  Widget build(BuildContext context) {
    final isInterested = userStatus == EventStatus.interested;
    final isGoing = userStatus == EventStatus.going;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        border: Border(
          top: BorderSide(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Interested
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleInterested,
                icon: Icon(
                  isInterested ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                ),
                label: Text(isInterested ? 'Interested' : 'Interested?'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isInterested
                      ? ThemeColors.getWarningColor(context)
                      : ThemeColors.getTextColor(context),
                  side: BorderSide(
                    color: isInterested
                        ? ThemeColors.getWarningColor(context)
                        : ThemeColors.getBorderColor(context),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Going / Join
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: isGoing
                        ? [
                            ThemeColors.getSuccessColor(context),
                            ThemeColors.getSuccessColor(
                              context,
                            ).withValues(alpha: 0.85),
                          ]
                        : [
                            ThemeColors.primaryColor,
                            ThemeColors.primaryColor.withBlue(200),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isGoing
                                  ? ThemeColors.getSuccessColor(context)
                                  : ThemeColors.primaryColor)
                              .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: event.isFull && !isGoing ? null : onToggleGoing,
                  icon: Icon(
                    isGoing
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    event.isFull && !isGoing
                        ? 'Event Full'
                        : isGoing
                        ? 'Going'
                        : 'Join Event',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
