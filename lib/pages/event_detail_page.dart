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

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  @override
  Widget build(BuildContext context) {
    final userPreferences = ref.watch(userEventPreferencesProvider);
    final userStatus = userPreferences[widget.event.id];
    
    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: ThemeColors.navBarColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareEvent(),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMoreOptions(),
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
                        color: Colors.grey.shade300,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 80,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.event.title,
                              style: TextThemes.bodyLarge.copyWith(
                                color: Colors.grey.shade700,
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
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
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
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event header
                  Padding(
                    padding: Constants.defaultPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.event.title,
                          style: TextThemes.title.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Description section
                  Padding(
                    padding: Constants.defaultPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About This Event',
                          style: TextThemes.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.description,
                          style: TextThemes.bodyMedium.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Location map placeholder
                  if (widget.event.latitude != null && widget.event.longitude != null)
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
        badgeColor = Colors.grey;
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
            color: Colors.black.withOpacity(0.2),
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
            style: TextThemes.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
            color: ThemeColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ThemeColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextThemes.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextThemes.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextThemes.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Going count
          Expanded(
            child: Column(
              children: [
                Text(
                  '$goingCount',
                  style: TextThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryColor,
                  ),
                ),
                Text(
                  'Going',
                  style: TextThemes.bodySmall.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Interested count
          Expanded(
            child: Column(
              children: [
                Text(
                  '$interestedCount',
                  style: TextThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Interested',
                  style: TextThemes.bodySmall.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          if (maxParticipants > 0) ...[
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.shade300,
            ),
            
            // Max participants
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$maxParticipants',
                    style: TextThemes.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Max',
                    style: TextThemes.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
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
        Text(
          'Tags',
          style: TextThemes.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.event.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextThemes.bodySmall.copyWith(
                  color: ThemeColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
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
            style: TextThemes.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Map View',
                  style: TextThemes.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open in maps',
                  style: TextThemes.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Interested button
          Expanded(
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
                    : Colors.grey.shade700,
                side: BorderSide(
                  color: userStatus == EventStatus.interested
                      ? Colors.orange
                      : Colors.grey.shade300,
                ),
                backgroundColor: userStatus == EventStatus.interested
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Going button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.event.isFull && userStatus != EventStatus.going
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
                backgroundColor: userStatus == EventStatus.going
                    ? Colors.green
                    : ThemeColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(widget.event.id);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markInterested(widget.event.id);
    }
  }

  /// Toggle going status
  void _toggleGoing(EventStatus? currentStatus) {
    if (widget.event.isFull && currentStatus != EventStatus.going) {
      SnackBarWidget.show(context, 'This event is full!');
      return;
    }

    if (currentStatus == EventStatus.going) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(widget.event.id);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markGoing(widget.event.id);
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
