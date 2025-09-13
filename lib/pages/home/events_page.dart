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
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.navBarColor,
        elevation: 1,
        title: Text(
          'Events',
          style: TextThemes.title.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ThemeColors.navBarIconColor),
            onPressed: () => _toggleSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: ThemeColors.navBarIconColor),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      margin: Constants.defaultMargin.copyWith(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
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
              child: const Icon(Icons.clear, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// Build category filter
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category || 
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
              backgroundColor: Colors.white,
              selectedColor: ThemeColors.primaryColor.withOpacity(0.2),
              checkmarkColor: ThemeColors.primaryColor,
              labelStyle: TextThemes.bodySmall.copyWith(
                color: isSelected ? ThemeColors.primaryColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openEventDetail(event),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  event.imageUrl ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Event Image',
                            style: TextThemes.bodySmall.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Event content
            Padding(
              padding: Constants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextThemes.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildUserStatusChip(userStatus),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Date and time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: ThemeColors.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${event.formattedDate} • ${event.formattedTime}',
                        style: TextThemes.bodySmall.copyWith(
                          color: ThemeColors.secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: ThemeColors.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextThemes.bodySmall.copyWith(
                            color: ThemeColors.secondaryColor,
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
                    style: TextThemes.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tags
                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: event.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextThemes.bodySmall.copyWith(
                              color: ThemeColors.primaryColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Participants info and actions
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.goingUserIds.length} going • ${event.interestedUserIds.length} interested',
                        style: TextThemes.bodySmall.copyWith(
                          color: Colors.grey.shade600,
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
        chipColor = Colors.green;
        label = 'Going';
        icon = Icons.check_circle;
        break;
      case EventStatus.interested:
        chipColor = Colors.orange;
        label = 'Interested';
        icon = Icons.star;
        break;
      case EventStatus.notGoing:
        chipColor = Colors.grey;
        label = 'Not Going';
        icon = Icons.close;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextThemes.bodySmall.copyWith(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected 
              ? ThemeColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected 
              ? ThemeColors.primaryColor 
              : Colors.grey.shade600,
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
          Icon(
            Icons.event_note,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No events available',
            style: TextThemes.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for upcoming events!',
            style: TextThemes.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
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
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextThemes.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextThemes.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
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
               event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               event.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               event.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.tags.any((tag) => 
          tag.toLowerCase().contains(_selectedCategory.toLowerCase())
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
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Events',
              style: TextThemes.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by today
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('This Week'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by this week
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Nearby'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by location
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('My Events'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter by user's events
              },
            ),
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
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
      ),
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