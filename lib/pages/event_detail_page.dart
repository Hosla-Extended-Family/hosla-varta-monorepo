import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/providers/event_provider.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

/// Detailed event page with full information and action buttons
class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  @override
  Widget build(BuildContext context) {
    final userPreferences = ref.watch(userEventPreferencesProvider);
    final userStatus = userPreferences[widget.event.id];

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: ThemeColors.getNavBarColor(context),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareEvent(),
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showMoreOptions(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Event image
                  Image.network(
                    widget.event.imageUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: ThemeColors.getBorderColor(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 80,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.event.title,
                              style: TextThemes.getBodyLargeStyle(context)
                                  .copyWith(
                                    color: ThemeColors.getTextColor(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Status badge
                  if (userStatus != null)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: _buildStatusBadge(userStatus),
                    ),
                ],
              ),
            ),
          ),

          // Event details
          SliverToBoxAdapter(
            child: Container(
              color: ThemeColors.getBackgroundColor(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event header card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThemeColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ThemeColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : ThemeColors.getOverlayColor(
                                  context,
                                  opacity: 0.08,
                                ),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.event.title,
                          style: TextThemes.getTitleStyle(
                            context,
                          ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 16),

                        // Date and time
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date & Time',
                          '${widget.event.formattedDate} at ${widget.event.formattedTime}',
                        ),

                        const SizedBox(height: 12),

                        // Location
                        _buildInfoRow(
                          Icons.location_on,
                          'Location',
                          widget.event.location,
                          subtitle: widget.event.address,
                        ),

                        const SizedBox(height: 12),

                        // Organizer info
                        _buildInfoRow(
                          Icons.person,
                          'Organizer',
                          'Event Organizer', // TODO: Get actual organizer name
                        ),

                        const SizedBox(height: 16),

                        // Participants info
                        _buildParticipantsInfo(),

                        const SizedBox(height: 16),

                        // Tags
                        if (widget.event.tags.isNotEmpty) _buildTags(),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          'About This Event',
                          style: TextThemes.getBodyLargeStyle(
                            context,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.description,
                          style: TextThemes.getBodyMediumStyle(
                            context,
                          ).copyWith(height: 1.6, fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Attendees Section
                  if (widget.event.goingUserIds.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ThemeColors.getCardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendees',
                            style: TextThemes.getBodyLargeStyle(context)
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.event.goingUserIds.length} people are going to this event',
                            style: TextThemes.getBodyMediumStyle(context)
                                .copyWith(
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Location map placeholder
                  if (widget.event.latitude != null &&
                      widget.event.longitude != null)
                    _buildLocationSection(),

                  const SizedBox(height: 100), // Space for action buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Action buttons
      bottomNavigationBar: _buildActionButtons(userStatus),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(EventStatus status) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case EventStatus.going:
        badgeColor = Colors.green;
        label = 'Going';
        icon = Icons.check_circle;
        break;
      case EventStatus.interested:
        badgeColor = Colors.orange;
        label = 'Interested';
        icon = Icons.star;
        break;
      case EventStatus.notGoing:
        badgeColor = ThemeColors.getSecondaryTextColor(context);
        label = 'Not Going';
        icon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(
    IconData icon,
    String title,
    String content, {
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: ThemeColors.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  /// Build participants info
  Widget _buildParticipantsInfo() {
    final goingCount = widget.event.goingUserIds.length;
    final interestedCount = widget.event.interestedUserIds.length;
    final maxParticipants = widget.event.maxParticipants;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeColors.primaryColor.withValues(alpha: 0.08),
            ThemeColors.primaryColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Going count
          Expanded(
            child: Column(
              children: [
                Text(
                  '$goingCount',
                  style: TextThemes.getBodyLargeStyle(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryColor,
                  ),
                ),
                Text(
                  'Going',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getTextColor(context)),
                ),
              ],
            ),
          ),

          Container(
            height: 30,
            width: 1,
            color: ThemeColors.getBorderColor(context),
          ),

          // Interested count
          Expanded(
            child: Column(
              children: [
                Text(
                  '$interestedCount',
                  style: TextThemes.getBodyLargeStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  'Interested',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getTextColor(context)),
                ),
              ],
            ),
          ),

          if (maxParticipants > 0) ...[
            Container(
              height: 30,
              width: 1,
              color: ThemeColors.getBorderColor(context),
            ),

            // Max participants
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$maxParticipants',
                    style: TextThemes.getBodyLargeStyle(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                  Text(
                    'Max',
                    style: TextThemes.getBodySmallStyle(
                      context,
                    ).copyWith(color: ThemeColors.getTextColor(context)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build tags section
  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor.withValues(alpha: 0.15),
                    ThemeColors.primaryColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '#$tag',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Constants.defaultPadding.copyWith(bottom: 12),
          child: Text(
            'Location',
            style: TextThemes.getBodyLargeStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ThemeColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
                const SizedBox(height: 8),
                Text(
                  'Map View',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open in maps',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(EventStatus? userStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Interested button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: userStatus == EventStatus.interested
                    ? LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
              ),
              child: OutlinedButton.icon(
                onPressed: () => _toggleInterested(userStatus),
                icon: Icon(
                  userStatus == EventStatus.interested
                      ? Icons.star
                      : Icons.star_border,
                  size: 20,
                ),
                label: Text(
                  userStatus == EventStatus.interested
                      ? 'Interested'
                      : 'Interested?',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: userStatus == EventStatus.interested
                      ? Colors.orange
                      : ThemeColors.getTextColor(context),
                  side: BorderSide(
                    color: userStatus == EventStatus.interested
                        ? Colors.orange
                        : ThemeColors.getBorderColor(context),
                    width: 1.5,
                  ),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Going button
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: userStatus == EventStatus.going
                      ? [Colors.green, Colors.green.withValues(alpha: 0.8)]
                      : [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(200),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (userStatus == EventStatus.going
                                ? Colors.green
                                : ThemeColors.primaryColor)
                            .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed:
                    widget.event.isFull && userStatus != EventStatus.going
                    ? null
                    : () => _toggleGoing(userStatus),
                icon: Icon(
                  userStatus == EventStatus.going
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 20,
                ),
                label: Text(
                  widget.event.isFull && userStatus != EventStatus.going
                      ? 'Event Full'
                      : userStatus == EventStatus.going
                      ? 'Going'
                      : 'Join Event',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle interested status
  void _toggleInterested(EventStatus? currentStatus) {
    if (currentStatus == EventStatus.interested) {
      ref
          .read(userEventPreferencesProvider.notifier)
          .removeFromEvent(widget.event.id);
    } else {
      ref
          .read(userEventPreferencesProvider.notifier)
          .markInterested(widget.event.id);
    }
  }

  /// Toggle going status
  void _toggleGoing(EventStatus? currentStatus) {
    if (widget.event.isFull && currentStatus != EventStatus.going) {
      SnackBarWidget.show(context, 'This event is full!');
      return;
    }

    if (currentStatus == EventStatus.going) {
      ref
          .read(userEventPreferencesProvider.notifier)
          .removeFromEvent(widget.event.id);
    } else {
      ref
          .read(userEventPreferencesProvider.notifier)
          .markGoing(widget.event.id);
    }
  }

  /// Share event
  void _shareEvent() {
    // TODO: Implement share functionality
    SnackBarWidget.show(context, 'Share functionality coming soon!');
  }

  /// Show more options
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Add to Calendar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to calendar
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Event'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report event
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Organizer'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Block organizer
              },
            ),
          ],
        ),
      ),
    );
  }
}
