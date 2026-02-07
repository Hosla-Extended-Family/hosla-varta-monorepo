import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/tag_model.dart';
import 'package:hosla/services/tag_service.dart';

/// Widget for selecting tags from a predefined list
///
/// Fetches available tags from the API and displays them as selectable chips.
/// Supports multiple selection and provides selected tag IDs back to parent.
class TagSelectionWidget extends StatefulWidget {
  /// Callback fired when selected tags change
  final Function(List<String> selectedTagIds, List<String> selectedTagNames)
  onTagsChanged;

  /// Initially selected tag names (optional)
  final List<String> initialSelectedTags;

  const TagSelectionWidget({
    Key? key,
    required this.onTagsChanged,
    this.initialSelectedTags = const [],
  }) : super(key: key);

  @override
  State<TagSelectionWidget> createState() => _TagSelectionWidgetState();
}

class _TagSelectionWidgetState extends State<TagSelectionWidget> {
  final TagService _tagService = TagService();

  // State management
  List<Tag> _availableTags = [];
  Set<String> _selectedTagIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  /// Fetch tags from API on component load
  Future<void> _fetchTags() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tags = await _tagService.fetchTags();

      setState(() {
        _availableTags = tags;
        _isLoading = false;

        // Pre-select tags if initial values provided
        if (widget.initialSelectedTags.isNotEmpty) {
          for (final tag in tags) {
            if (widget.initialSelectedTags.contains(tag.name)) {
              _selectedTagIds.add(tag.id);
            }
          }
          _notifyParent();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Toggle tag selection
  void _toggleTag(Tag tag) {
    setState(() {
      if (_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.remove(tag.id);
      } else {
        _selectedTagIds.add(tag.id);
      }
    });
    _notifyParent();
  }

  /// Notify parent widget of selection changes
  void _notifyParent() {
    final selectedIds = _selectedTagIds.toList();
    final selectedNames = _availableTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .map((tag) => tag.name)
        .toList();

    widget.onTagsChanged(selectedIds, selectedNames);
  }

  /// Check if tag is high priority (e.g., EMERGENCY, HEALTH)
  /// High priority tags have priority >= 80
  bool _isHighPriority(Tag tag) {
    return tag.priority >= 80;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.label_outline,
                size: 20,
                color: ThemeColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Tags',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.getTextColor(context),
                ),
              ),
              if (_selectedTagIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedTagIds.length} selected',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 12,
                      color: ThemeColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Content area
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_availableTags.isEmpty)
            _buildEmptyState()
          else
            _buildTagsGrid(),
        ],
      ),
    );
  }

  /// Loading state UI
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading tags...',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 14,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state UI
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ThemeColors.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load tags',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.errorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 12,
                    color: ThemeColors.errorColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: ThemeColors.errorColor),
            onPressed: _fetchTags,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  /// Empty state UI
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.label_off_outlined,
              size: 48,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No tags available',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 14,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tags grid UI - displays all tags as selectable chips
  Widget _buildTagsGrid() {
    // Separate high-priority and normal tags
    final highPriorityTags = _availableTags.where(_isHighPriority).toList();
    final normalTags = _availableTags
        .where((tag) => !_isHighPriority(tag))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // High priority tags section (if any)
        if (highPriorityTags.isNotEmpty) ...[
          Text(
            'Priority Tags',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highPriorityTags
                .map((tag) => _buildTagChip(tag, isHighPriority: true))
                .toList(),
          ),
          if (normalTags.isNotEmpty) const SizedBox(height: 16),
        ],

        // Normal tags section
        if (normalTags.isNotEmpty) ...[
          if (highPriorityTags.isNotEmpty)
            Text(
              'Other Tags',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          if (highPriorityTags.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: normalTags.map((tag) => _buildTagChip(tag)).toList(),
          ),
        ],
      ],
    );
  }

  /// Build individual tag chip with selection support
  Widget _buildTagChip(Tag tag, {bool isHighPriority = false}) {
    final isSelected = _selectedTagIds.contains(tag.id);

    return GestureDetector(
      onTap: () => _toggleTag(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeColors.primaryColor
              : isHighPriority
              ? ThemeColors.warningColor.withOpacity(0.1)
              : ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ThemeColors.primaryColor
                : isHighPriority
                ? ThemeColors.warningColor.withOpacity(0.3)
                : ThemeColors.getBorderColor(context),
            width: isSelected || isHighPriority ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority indicator for high-priority tags
            if (isHighPriority && !isSelected) ...[
              Icon(
                Icons.priority_high,
                size: 16,
                color: ThemeColors.warningColor,
              ),
              const SizedBox(width: 4),
            ],
            // Tag name
            Text(
              tag.name,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 14,
                fontWeight: isSelected || isHighPriority
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isHighPriority
                    ? ThemeColors.warningColor
                    : ThemeColors.getTextColor(context),
              ),
            ),
            // Selected indicator
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
