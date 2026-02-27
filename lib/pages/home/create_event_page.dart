import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/providers/event_provider.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE EVENT PAGE
//
// Form layout (top → bottom):
//   1. GlassAppBar with "Create" submit button
//   2. Cover image section
//   3. Title
//   4. Description
//   5. Date & Time (start + end)
//   6. Location
//   7. Tags
//   8. Settings (visibility, max participants)
//
// Design: Section-card pattern matching the Create Post page, consistent
// with the Hosla design system (rounded cards, teal accents, Quicksand font).
// ─────────────────────────────────────────────────────────────────────────────

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime? _endDate;
  TimeOfDay? _endTime;

  XFile? _coverImage;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _tagsController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSubmit = !_isLoading && _titleController.text.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        titleText: 'Create Event',
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: canSubmit ? _submitEvent : null,
              style: FilledButton.styleFrom(
                backgroundColor: ThemeColors.primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: ThemeColors.primaryColor.withValues(
                  alpha: 0.3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      'Create',
                      style: TextThemes.getButtonStyle(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spacer behind glass app bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Cover Image Section ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader('Cover Image', Icons.image_rounded),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _isLoading ? null : _pickCoverImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ThemeColors.getSurfaceColor(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ThemeColors.getBorderColor(context),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _coverImage != null
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.file(
                                                File(_coverImage!.path),
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: _circleAction(
                                                  icon: Icons.close_rounded,
                                                  onTap: () => setState(
                                                    () => _coverImage = null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    14,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: ThemeColors
                                                        .primaryColor
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: 28,
                                                    color: ThemeColors
                                                        .primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Add cover image',
                                                  style:
                                                      TextThemes.getBodyMediumStyle(
                                                        context,
                                                      ).copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Recommended: 16:9 ratio',
                                                  style:
                                                      TextThemes.getBodySmallStyle(
                                                        context,
                                                      ).copyWith(
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Title ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader('Title', Icons.title_rounded),
                            const SizedBox(height: 12),
                            _textField(
                              controller: _titleController,
                              hint: 'What\'s the event called?',
                              maxLines: 1,
                              maxLength: 100,
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Description ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader(
                              'Description',
                              Icons.description_rounded,
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              controller: _descriptionController,
                              hint: 'Tell people what this event is about…',
                              maxLines: 5,
                              maxLength: 1000,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Date & Time ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              'Date & Time',
                              Icons.schedule_rounded,
                            ),
                            const SizedBox(height: 14),

                            // Start
                            _dateTimePicker(
                              label: 'Starts',
                              date: _startDate,
                              time: _startTime,
                              onPickDate: () => _pickDate(isStart: true),
                              onPickTime: () => _pickTime(isStart: true),
                            ),
                            const SizedBox(height: 14),

                            // End (optional)
                            Row(
                              children: [
                                Text(
                                  'Add end time',
                                  style: TextThemes.getBodyMediumStyle(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Switch.adaptive(
                                  value: _endDate != null,
                                  activeTrackColor: ThemeColors.primaryColor,
                                  onChanged: (on) {
                                    setState(() {
                                      if (on) {
                                        _endDate = _startDate.add(
                                          const Duration(hours: 2),
                                        );
                                        _endTime = TimeOfDay(
                                          hour: (_startTime.hour + 2) % 24,
                                          minute: _startTime.minute,
                                        );
                                      } else {
                                        _endDate = null;
                                        _endTime = null;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),

                            if (_endDate != null) ...[
                              const SizedBox(height: 8),
                              _dateTimePicker(
                                label: 'Ends',
                                date: _endDate!,
                                time: _endTime!,
                                onPickDate: () => _pickDate(isStart: false),
                                onPickTime: () => _pickTime(isStart: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Location ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader(
                              'Location',
                              Icons.location_on_rounded,
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              controller: _locationController,
                              hint: 'Venue or place name',
                              maxLines: 1,
                            ),
                            const SizedBox(height: 10),
                            _textField(
                              controller: _addressController,
                              hint: 'Full address (optional)',
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Tags ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader('Tags', Icons.tag_rounded),
                            const SizedBox(height: 12),
                            _textField(
                              controller: _tagsController,
                              hint: 'music, outdoor, tech (comma-separated)',
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Settings ──
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Settings', Icons.settings_rounded),
                            const SizedBox(height: 14),

                            // Visibility toggle
                            Row(
                              children: [
                                Icon(
                                  _isPublic
                                      ? Icons.public_rounded
                                      : Icons.lock_rounded,
                                  size: 20,
                                  color: ThemeColors.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPublic
                                            ? 'Public Event'
                                            : 'Private Event',
                                        style: TextThemes.getBodyMediumStyle(
                                          context,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        _isPublic
                                            ? 'Anyone can discover this event'
                                            : 'Only invited people can see this',
                                        style:
                                            TextThemes.getBodySmallStyle(
                                              context,
                                            ).copyWith(
                                              color:
                                                  ThemeColors.getSecondaryTextColor(
                                                    context,
                                                  ),
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _isPublic,
                                  activeTrackColor: ThemeColors.primaryColor,
                                  onChanged: (v) =>
                                      setState(() => _isPublic = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              color: ThemeColors.getBorderColor(
                                context,
                              ).withValues(alpha: 0.2),
                              height: 1,
                            ),
                            const SizedBox(height: 14),

                            // Max participants
                            Row(
                              children: [
                                Icon(
                                  Icons.group_rounded,
                                  size: 20,
                                  color: ThemeColors.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Max Participants',
                                    style: TextThemes.getBodyMediumStyle(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: _textField(
                                    controller: _maxParticipantsController,
                                    hint: '0',
                                    maxLines: 1,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leave 0 for unlimited',
                              style: TextThemes.getBodySmallStyle(context)
                                  .copyWith(
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionCard({required bool isDark, required Widget child}) {
    return Container(
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: TextThemes.getBodyLargeStyle(
            context,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const Spacer(),
        Icon(icon, size: 20, color: ThemeColors.getSecondaryTextColor(context)),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textAlign: textAlign,
      enabled: !_isLoading,
      validator: validator,
      style: TextThemes.getBodyMediumStyle(context),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextThemes.getBodyMediumStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
        filled: true,
        fillColor: ThemeColors.getSurfaceColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ThemeColors.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ThemeColors.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: ThemeColors.primaryColor,
            width: 2,
          ),
        ),
        counterStyle: TextThemes.getBodySmallStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _dateTimePicker({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onPickDate,
    required VoidCallback onPickTime,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeColors.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _chipButton(
            icon: Icons.calendar_today_rounded,
            label: '${date.day}/${date.month}/${date.year}',
            onTap: onPickDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chipButton(
            icon: Icons.access_time_rounded,
            label: time.format(context),
            onTap: onPickTime,
          ),
        ),
      ],
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.getBorderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ThemeColors.primaryColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextThemes.getBodySmallStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickCoverImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: ThemeColors.getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Choose Image Source',
            style: TextThemes.getTitleStyle(context).copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: ThemeColors.primaryColor,
                ),
                title: Text(
                  'Camera',
                  style: TextThemes.getBodyMediumStyle(context),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: ThemeColors.primaryColor,
                ),
                title: Text(
                  'Gallery',
                  style: TextThemes.getBodyMediumStyle(context),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => _coverImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarWidget.show(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: ThemeColors.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : (_endTime ?? _startTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: ThemeColors.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final parsedTags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final maxPart = int.tryParse(_maxParticipantsController.text.trim()) ?? 0;

      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _coverImage?.path,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        organizerId: '', // TODO: use current user id
        isPublic: _isPublic,
        tags: parsedTags,
        maxParticipants: maxPart,
      );

      await ref.read(eventsProvider.notifier).createEvent(event);

      if (!mounted) return;
      setState(() => _isLoading = false);

      SnackBarWidget.show(context, 'Event created successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackBarWidget.show(context, 'Error creating event: $e');
    }
  }
}
