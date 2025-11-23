import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/providers/event_provider.dart';
import 'package:hosla/pages/event_detail_page.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

/// Events page displaying upcoming events in a scrollable list
class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '';

  final List<String> _categories = [
    'All',
    'Technology',
    'Community',
    'Art',
    'Business',
    'Wellness',
    'Education',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final userPreferences = ref.watch(userEventPreferencesProvider);
    final filteredEvents = _filterEvents(events);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        title: Text(
          'Events',
          style: TextThemes.getTitleStyle(context).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            onPressed: () => _toggleSearch(),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            onPressed: () => _showFilterOptions(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(eventsProvider.notifier).loadEvents();
        },
        child: Column(
          children: [
            // Search bar
            if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
              _buildSearchBar(),

            // Category filter
            _buildCategoryFilter(),

            // Events list
            Expanded(
              child: events.isEmpty
                  ? _buildEmptyState()
                  : filteredEvents.isEmpty
                  ? _buildNoResultsState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final userStatus = userPreferences[event.id];
                        return _buildEventCard(event, userStatus);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(),
        backgroundColor: ThemeColors.primaryColor,
        child: Icon(Icons.add, color: ThemeColors.getCardColor(context)),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16).copyWith(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: ThemeColors.getSecondaryTextColor(context)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search events...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Icon(
                Icons.clear,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
        ],
      ),
    );
  }

  /// Build category filter
  Widget _buildCategoryFilter() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected =
              _selectedCategory == category ||
              (category == 'All' && _selectedCategory.isEmpty);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category == 'All' ? '' : category;
                });
              },
              elevation: isSelected ? 2 : 0,
              backgroundColor: ThemeColors.getCardColor(context),
              selectedColor: ThemeColors.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextThemes.getBodySmallStyle(context).copyWith(
                color: isSelected
                    ? Colors.white
                    : ThemeColors.getSecondaryTextColor(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected
                      ? ThemeColors.primaryColor
                      : ThemeColors.getSecondaryTextColor(context).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build event card
  Widget _buildEventCard(Event event, EventStatus? userStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: ThemeColors.primaryColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _openEventDetail(event),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.imageUrl ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ThemeColors.primaryColor.withOpacity(0.3),
                                ThemeColors.primaryColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 56,
                                color: ThemeColors.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Event Image',
                                style: TextThemes.getBodyMediumStyle(context)
                                    .copyWith(
                                      color: ThemeColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Status badge overlay
                  if (userStatus != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildUserStatusChip(userStatus),
                    ),
                ],
              ),
            ),

            // Event content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    event.title,
                    style: TextThemes.getBodyLargeStyle(
                      context,
                    ).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Date and time
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: ThemeColors.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${event.formattedDate} • ${event.formattedTime}',
                            style: TextThemes.getBodySmallStyle(context).copyWith(
                              color: ThemeColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: ThemeColors.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    event.description,
                    style: TextThemes.getBodyMediumStyle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Tags
                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: event.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ThemeColors.primaryColor.withOpacity(0.15),
                                ThemeColors.primaryColor.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ThemeColors.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: ThemeColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 14),

                  // Participants info and actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeColors.getSuccessColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: ThemeColors.getSuccessColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.goingUserIds.length}',
                              style: TextThemes.getBodySmallStyle(context).copyWith(
                                color: ThemeColors.getSuccessColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeColors.getWarningColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: ThemeColors.getWarningColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.interestedUserIds.length}',
                              style: TextThemes.getBodySmallStyle(context).copyWith(
                                color: ThemeColors.getWarningColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildQuickActionButtons(event, userStatus),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build user status chip
  Widget _buildUserStatusChip(EventStatus? status) {
    if (status == null) return const SizedBox.shrink();

    Color chipColor;
    String label;
    IconData icon;

    switch (status) {
      case EventStatus.going:
        chipColor = ThemeColors.getSuccessColor(context);
        label = 'Going';
        icon = Icons.check_circle;
        break;
      case EventStatus.interested:
        chipColor = ThemeColors.getWarningColor(context);
        label = 'Interested';
        icon = Icons.star;
        break;
      case EventStatus.notGoing:
        chipColor = ThemeColors.getSecondaryTextColor(context);
        label = 'Not Going';
        icon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActionButtons(Event event, EventStatus? userStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.star_border,
          isSelected: userStatus == EventStatus.interested,
          onPressed: () => _toggleInterested(event.id, userStatus),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.check_circle_outline,
          isSelected: userStatus == EventStatus.going,
          onPressed: () => _toggleGoing(event.id, userStatus),
        ),
      ],
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeColors.primaryColor
              : ThemeColors.getCardColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? ThemeColors.primaryColor
                : ThemeColors.getSecondaryTextColor(context).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ThemeColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected
              ? Colors.white
              : ThemeColors.getSecondaryTextColor(context),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_note,
              size: 72,
              color: ThemeColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No events available',
            style: TextThemes.getBodyLargeStyle(
              context,
            ).copyWith(
              color: ThemeColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for upcoming events!',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  /// Build no search results state
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 72,
              color: ThemeColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No events found',
            style: TextThemes.getBodyLargeStyle(
              context,
            ).copyWith(
              color: ThemeColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  /// Filter events based on search and category
  List<Event> _filterEvents(List<Event> events) {
    List<Event> filtered = events;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            event.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    // Filter by category
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.tags.any(
          (tag) => tag.toLowerCase().contains(_selectedCategory.toLowerCase()),
        );
      }).toList();
    }

    // Sort by start time
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filtered;
  }

  /// Toggle search bar
  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isEmpty && _searchController.text.isEmpty) {
        _searchQuery = ' '; // Trigger search bar visibility
      } else {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Show filter options
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ThemeColors.getSecondaryTextColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Filter Events',
              style: TextThemes.getBodyLargeStyle(
                context,
              ).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: Icon(Icons.today, color: ThemeColors.primaryColor),
              title: const Text('Today'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by today
              },
            ),
            ListTile(
              leading: Icon(Icons.date_range, color: ThemeColors.primaryColor),
              title: const Text('This Week'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by this week
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: ThemeColors.primaryColor),
              title: const Text('Nearby'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by location
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: ThemeColors.primaryColor),
              title: const Text('My Events'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by user's events
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show create event dialog
  void _showCreateEventDialog() {
    // TODO: Implement create event dialog or navigate to create event page
    SnackBarWidget.show(context, 'Create event feature coming soon!');
  }

  /// Open event detail page
  void _openEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
    );
  }

  /// Toggle interested status
  void _toggleInterested(String eventId, EventStatus? currentStatus) {
    if (currentStatus == EventStatus.interested) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(eventId);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markInterested(eventId);
    }
  }

  /// Toggle going status
  void _toggleGoing(String eventId, EventStatus? currentStatus) {
    if (currentStatus == EventStatus.going) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(eventId);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markGoing(eventId);
    }
  }
}
