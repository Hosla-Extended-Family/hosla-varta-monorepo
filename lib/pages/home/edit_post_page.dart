import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/widgets/tag_selection_widget.dart';
import 'package:image_picker/image_picker.dart';

class EditPostPage extends ConsumerStatefulWidget {
  final Post post;

  const EditPostPage({super.key, required this.post});

  @override
  ConsumerState<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends ConsumerState<EditPostPage> {
  late final TextEditingController _captionController;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  XFile? _selectedImage;

  List<String> _tagIds = [];
  List<String> _tagNames = [];
  late String _visibility;

  static const _allowedVisibilities = <String>['PUBLIC', 'FRIENDS', 'ONLY_ME'];

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.content);
    _visibility = widget.post.visibility.toUpperCase();
    _tagNames = List<String>.from(widget.post.tags);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String _visibilityLabel(String value) {
    switch (value.toUpperCase()) {
      case 'PUBLIC':
        return 'Public';
      case 'FRIENDS':
        return 'Friends';
      case 'ONLY_ME':
        return 'Only me';
      default:
        return value;
    }
  }

  IconData _visibilityIcon(String value) {
    switch (value.toUpperCase()) {
      case 'PUBLIC':
        return Icons.public;
      case 'FRIENDS':
        return Icons.group;
      case 'ONLY_ME':
        return Icons.lock;
      default:
        return Icons.visibility;
    }
  }

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16),
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.getOverlayColor(context, opacity: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _selectedImage = picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _save() async {
    final content = _captionController.text.trim();

    final existingImageUrl = (widget.post.imageUrl ?? '').trim();
    final hasAnyImage = _selectedImage != null || existingImageUrl.isNotEmpty;

    if (content.isEmpty && !hasAnyImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please add an image or caption',
            style: TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      List<String> mediaUrls = const [];

      if (_selectedImage != null) {
        final postService = ref.read(postServiceProvider);
        final uploaded = await postService.uploadImage(_selectedImage!.path);
        if (uploaded == null || uploaded.trim().isEmpty) {
          throw Exception('Image upload failed');
        }
        imageUrl = uploaded;
        mediaUrls = [uploaded];
      } else if (widget.post.mediaUrls.isNotEmpty) {
        mediaUrls = widget.post.mediaUrls;
      } else if (existingImageUrl.isNotEmpty) {
        mediaUrls = [existingImageUrl];
      }

      final postActions = ref.read(postActionsProvider);
      final result = await postActions.editPost(
        post: widget.post,
        content: content,
        imageUrl: imageUrl,
        mediaUrls: mediaUrls,
        tagIds: _tagIds,
        tagNames: _tagNames,
        visibility: _visibility,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Post updated successfully',
              style: const TextStyle(fontFamily: 'Quicksand'),
            ),
            backgroundColor: ThemeColors.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      setState(() => _isSaving = false);

      if (result['conflict'] == true) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conflict Detected'),
            content: Text(
              result['message']?.toString() ??
                  'The post has been modified elsewhere.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Failed to update post',
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update post: $e',
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit = !_isSaving;

    final existingImageUrl = (widget.post.imageUrl ?? '').trim();
    final showExistingImage =
        existingImageUrl.isNotEmpty && _selectedImage == null;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: const Text('Edit Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton(
              onPressed: canSubmit ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: ThemeColors.primaryColor,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            _sectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caption',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _captionController,
                    maxLines: 5,
                    cursorColor: ThemeColors.primaryColor,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: ThemeColors.getSecondaryTextColor(
                          context,
                        ).withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: ThemeColors.getCardColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ThemeColors.primaryColor.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Photo',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ThemeColors.getTextColor(context),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _isSaving ? null : _pickImage,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          showExistingImage ? 'Change' : 'Add',
                          style: const TextStyle(fontFamily: 'Quicksand'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_selectedImage!.path),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (showExistingImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        existingImageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ThemeColors.getBackgroundColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ThemeColors.getBorderColor(context),
                            ),
                          ),
                          child: const Text(
                            'Could not load image',
                            style: TextStyle(fontFamily: 'Quicksand'),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: ThemeColors.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ThemeColors.getBorderColor(context),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No image attached',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TagSelectionWidget(
                initialSelectedTags: widget.post.tags,
                onTagsChanged: (ids, names) {
                  setState(() {
                    _tagIds = ids;
                    _tagNames = names;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visibility',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allowedVisibilities
                        .map((value) {
                          final isSelected = _visibility.toUpperCase() == value;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: _isSaving
                                ? null
                                : (v) {
                                    if (!v) return;
                                    setState(() => _visibility = value);
                                  },
                            avatar: Icon(
                              _visibilityIcon(value),
                              size: 18,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : ThemeColors.getSecondaryTextColor(context),
                            ),
                            label: Text(
                              _visibilityLabel(value),
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : ThemeColors.getTextColor(context),
                              ),
                            ),
                            selectedColor: ThemeColors.primaryColor,
                            backgroundColor: ThemeColors.getBackgroundColor(
                              context,
                            ),
                            side: BorderSide(
                              color: ThemeColors.getBorderColor(context),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
