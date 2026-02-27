import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/providers/event_provider.dart';
import 'package:hosla/pages/event_detail_page.dart';
import 'package:hosla/pages/home/friends_page.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/create_event_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS PAGE — Complete Redesign
//
// Design principles:
//   • Clean, modern card-based layout consistent with Feed & Friends pages
//   • Glassmorphic AppBar with "Add Friends" action
//   • Horizontal category chips for quick filtering
//   • Compact event cards with image, metadata, and quick-action buttons
//   • Soft shadows, rounded corners, clear visual hierarchy
//   • Proper empty + no-results states
// ─────────────────────────────────────────────────────────────────────────────

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '';

  static const List<String> _categories = [
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

  // ───────────────────────────── BUILD ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final userPreferences = ref.watch(userEventPreferencesProvider);
    final filteredEvents = _filterEvents(events);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        titleText: 'Events',
        actions: [
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
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            tooltip: 'Filters',
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: const CreateEventFab(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
        color: ThemeColors.primaryColor,
        backgroundColor: ThemeColors.getSurfaceColor(context),
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Top spacer behind the glass app bar
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              ),
            ),

            // Search bar
            SliverToBoxAdapter(child: _buildSearchBar()),

            // Category chips
            SliverToBoxAdapter(child: _buildCategoryChips()),

            // Content
            if (events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (filteredEvents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildNoResultsState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final event = filteredEvents[index];
                    final status = userPreferences[event.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EventCard(
                        event: event,
                        userStatus: status,
                        onTap: () => _openDetail(event),
                        onToggleInterested: () =>
                            _toggleInterested(event.id, status),
                        onToggleGoing: () => _toggleGoing(event.id, status),
                      ),
                    );
                  }, childCount: filteredEvents.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── SEARCH BAR ─────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: ThemeColors.getSecondaryTextColor(context),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextThemes.getBodyMediumStyle(context),
                decoration: InputDecoration(
                  hintText: 'Search events…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(
                  Icons.close_rounded,
                  color: ThemeColors.getSecondaryTextColor(context),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── CATEGORY CHIPS ──────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected =
              _selectedCategory == cat ||
              (cat == 'All' && _selectedCategory.isEmpty);

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = cat == 'All' ? '' : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? ThemeColors.primaryColor
                    : ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? ThemeColors.primaryColor
                      : ThemeColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: ThemeColors.primaryColor.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: isSelected
                      ? Colors.black
                      : ThemeColors.getSecondaryTextColor(context),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── EMPTY STATES ───────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 64,
                color: ThemeColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No events yet',
              style: TextThemes.getTitleStyle(context).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for upcoming events in your community!',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: ThemeColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No matches',
              style: TextThemes.getTitleStyle(context).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── FILTER SHEET ───────────────────────

  void _showFilterSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(
                'Filter Events',
                style: TextThemes.getTitleStyle(context).copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _filterTile(Icons.today_rounded, 'Today'),
              _filterTile(Icons.date_range_rounded, 'This Week'),
              _filterTile(Icons.location_on_rounded, 'Nearby'),
              _filterTile(Icons.people_rounded, 'My Events'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: ThemeColors.primaryColor),
      title: Text(label, style: TextThemes.getBodyMediumStyle(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        // TODO: Apply filter
      },
    );
  }

  // ───────────────────────── HELPERS ────────────────────────────

  List<Event> _filterEvents(List<Event> events) {
    var filtered = events.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.tags.any(
          (t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()),
        );
      }).toList();
    }

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  void _openDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
    );
  }

  void _toggleInterested(String eventId, EventStatus? status) {
    if (status == EventStatus.interested) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(eventId);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markInterested(eventId);
    }
  }

  void _toggleGoing(String eventId, EventStatus? status) {
    if (status == EventStatus.going) {
      ref.read(userEventPreferencesProvider.notifier).removeFromEvent(eventId);
    } else {
      ref.read(userEventPreferencesProvider.notifier).markGoing(eventId);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT CARD — Extracted to a self-contained widget for reuse
// ═══════════════════════════════════════════════════════════════════════════════

class _EventCard extends StatelessWidget {
  final Event event;
  final EventStatus? userStatus;
  final VoidCallback onTap;
  final VoidCallback onToggleInterested;
  final VoidCallback onToggleGoing;

  const _EventCard({
    required this.event,
    required this.userStatus,
    required this.onTap,
    required this.onToggleInterested,
    required this.onToggleGoing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : ThemeColors.primaryColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image header ───
            _buildImageHeader(context),

            // ─── Content body ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: TextThemes.getBodyLargeStyle(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Date + Time chip
                  _buildDateChip(context),
                  const SizedBox(height: 8),

                  // Location
                  _buildLocationRow(context),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    event.description,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tags
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildTags(context),
                  ],

                  const SizedBox(height: 12),

                  // Footer — stats + quick actions
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── Image header ─────────────────

  Widget _buildImageHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 2.2,
            child: Image.network(
              event.imageUrl ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ThemeColors.primaryColor.withValues(alpha: 0.15),
                      ThemeColors.primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event_rounded,
                    size: 48,
                    color: ThemeColors.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // Status badge
          if (userStatus != null)
            Positioned(
              top: 10,
              right: 10,
              child: _StatusBadge(status: userStatus!),
            ),
        ],
      ),
    );
  }

  // ───────────────── Date chip ─────────────────

  Widget _buildDateChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: ThemeColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: ThemeColors.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${event.formattedDate}  •  ${event.formattedTime}',
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Location row ─────────────────

  Widget _buildLocationRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: ThemeColors.getSecondaryTextColor(context),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            event.location,
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ───────────────── Tags ─────────────────

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: event.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeColors.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '#$tag',
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────── Footer ─────────────────

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Going count
        _StatChip(
          icon: Icons.people_rounded,
          label: '${event.goingUserIds.length}',
          color: ThemeColors.getSuccessColor(context),
        ),
        const SizedBox(width: 8),

        // Interested count
        _StatChip(
          icon: Icons.star_rounded,
          label: '${event.interestedUserIds.length}',
          color: ThemeColors.getWarningColor(context),
        ),

        const Spacer(),

        // Quick action — Interested
        _QuickActionButton(
          icon: Icons.star_border_rounded,
          isSelected: userStatus == EventStatus.interested,
          onPressed: onToggleInterested,
        ),
        const SizedBox(width: 8),

        // Quick action — Going
        _QuickActionButton(
          icon: Icons.check_circle_outline_rounded,
          isSelected: userStatus == EventStatus.going,
          onPressed: onToggleGoing,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Compact stat chip (e.g. "👤 12")
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Status badge shown on the event image
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

/// Circular quick-action button used in the event card footer
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        splashColor: ThemeColors.primaryColor.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? ThemeColors.primaryColor
                : ThemeColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? ThemeColors.primaryColor
                  : ThemeColors.getBorderColor(context).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ThemeColors.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.black
                : ThemeColors.getSecondaryTextColor(context),
          ),
        ),
      ),
    );
  }
}
