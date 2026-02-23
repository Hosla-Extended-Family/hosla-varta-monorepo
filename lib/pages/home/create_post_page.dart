import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:hosla/services/post_service.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:hosla/models/post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosla/widgets/tag_selection_widget.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();
  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  int _activeImageIndex = 0;
  List<String> _tagIds = []; // Tag UUIDs for API submission
  List<String> _tagNames = []; // Tag names for display
  String _visibility = 'PUBLIC';

  static const _allowedVisibilities = <String>['PUBLIC', 'FRIENDS', 'ONLY_ME'];

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

  @override
  void dispose() {
    _captionController.dispose();
    _postService.dispose();
    super.dispose();
  }

  Future<({bool success, String message})> _handleCreatePost() async {
    final caption = _captionController.text.trim();
    if (_selectedImages.isEmpty && caption.isEmpty) {
      return (success: false, message: 'Please add an image or caption.');
    }

    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final userName = prefs.getString('user_name') ?? 'Anonymous';
      final userAvatarUrl = prefs.getString('user_avatar');

      if (userId.isEmpty) {
        return (
          success: false,
          message: 'User not authenticated. Please login again.',
        );
      }

      // Debug log: user attempted to create a post.
      // Intentionally avoids logging tokens; caption is truncated.
      final truncatedCaption = caption.length <= 80
          ? caption
          : '${caption.substring(0, 80)}…';
      debugPrint(
        '[CreatePost] attempt userId=$userId '
        'captionLen=${caption.length} caption="$truncatedCaption" '
        'images=${_selectedImages.length} tagIds=${_tagIds.length} '
        'visibility=${_visibility.toUpperCase()}',
      );

      Map<String, dynamic> result;

      // If an image is selected, prefer using the default create-post API
      // to upload the picture along with the post (multipart).
      if (_selectedImages.isNotEmpty) {
        result = await _postService.createPostWithMediaFiles(
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          content: caption,
          mediaPaths: _selectedImages
              .map((e) => e.path)
              .toList(growable: false),
          tagIds: _tagIds,
          visibility: _visibility,
        );
      } else {
        // No image: normal JSON create post.
        result = await _postService.createPost(
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          content: caption,
          tagIds: _tagIds,
          visibility: _visibility,
        );
      }

      if (result['success'] == true) {
        // Save post to local database
        final postData = result['data'] as Map<String, dynamic>?;
        if (postData != null) {
          final post = Post.fromJson(postData);
          await DatabaseHelper.instance.upsertPost(post);
        } else {
          // Create a local post object if server doesn't return full data
          final localPost = Post(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            userName: userName,
            userAvatarUrl: userAvatarUrl,
            content: caption,
            tags: _tagNames,
            visibility: _visibility,
            createdAt: DateTime.now(),
          );
          await DatabaseHelper.instance.upsertPost(localPost);
        }
        return (
          success: true,
          message: (result['message']?.toString().trim().isNotEmpty == true)
              ? result['message'].toString()
              : 'Post created successfully!',
        );
      } else {
        return (
          success: false,
          message: (result['message']?.toString().trim().isNotEmpty == true)
              ? result['message'].toString()
              : 'Failed to create post.',
        );
      }
    } catch (e) {
      return (
        success: false,
        message: 'Failed to create post: ${e.toString()}',
      );
    }
  }

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Show option to pick from gallery or camera
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ThemeColors.getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Choose Image Source',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.bold,
              color: ThemeColors.getTextColor(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: ThemeColors.primaryColor,
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    color: ThemeColors.getTextColor(context),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: ThemeColors.primaryColor,
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    color: ThemeColors.getTextColor(context),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        if (source == ImageSource.camera) {
          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );

          if (image != null) {
            // Open image editor for a single capture.
            await _openImageEditor(image);
          }
        } else {
          final List<XFile> images = await _picker.pickMultiImage(
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );

          if (images.isNotEmpty) {
            if (images.length == 1) {
              await _openImageEditor(images.first);
            } else if (mounted) {
              setState(() {
                _selectedImages = images;
                _activeImageIndex = 0;
              });
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: $e',
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _openImageEditor(XFile imageFile, {int? replaceIndex}) async {
    final BuildContext currentContext = context;
    final messenger = ScaffoldMessenger.of(currentContext);
    try {
      final bytes = await imageFile.readAsBytes();

      if (!currentContext.mounted) return;

      final editedImage = await Navigator.push<Uint8List>(
        currentContext,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) {
                Navigator.pop(currentContext, bytes);
                return Future.value();
              },
            ),
          ),
        ),
      );

      if (editedImage != null && mounted) {
        // Save the edited image to a temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(editedImage);

        setState(() {
          final edited = XFile(tempFile.path);
          if (replaceIndex != null &&
              replaceIndex >= 0 &&
              replaceIndex < _selectedImages.length) {
            _selectedImages[replaceIndex] = edited;
            _activeImageIndex = replaceIndex;
          } else {
            _selectedImages = [edited];
            _activeImageIndex = 0;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to edit image: $e',
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _createPost() async {
    if (_selectedImages.isEmpty && _captionController.text.trim().isEmpty) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _handleCreatePost();
      final message = result.message;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final isSuccess = result.success;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: isSuccess
              ? ThemeColors.successColor
              : ThemeColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      if (isSuccess) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
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
    final canSubmit =
        !_isLoading &&
        (_selectedImages.isNotEmpty ||
            _captionController.text.trim().isNotEmpty);

    final hasMedia = _selectedImages.isNotEmpty;
    final activeIndex = (!hasMedia)
        ? 0
        : (_activeImageIndex < _selectedImages.length ? _activeImageIndex : 0);
    final activeImage = hasMedia ? _selectedImages[activeIndex] : null;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton(
              onPressed: canSubmit ? _createPost : null,
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
              child: _isLoading
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
                      'Post',
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
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Media card
                _sectionCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Media',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w700,
                              color: ThemeColors.getTextColor(context),
                            ),
                          ),
                          const Spacer(),
                          if (hasMedia)
                            IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _openImageEditor(
                                      activeImage!,
                                      replaceIndex: activeIndex,
                                    ),
                              tooltip: 'Edit',
                              icon: Icon(
                                Icons.tune,
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                            ),
                          if (hasMedia)
                            IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedImages.removeAt(activeIndex);
                                        if (_selectedImages.isEmpty) {
                                          _activeImageIndex = 0;
                                        } else if (_activeImageIndex >=
                                            _selectedImages.length) {
                                          _activeImageIndex =
                                              _selectedImages.length - 1;
                                        }
                                      });
                                    },
                              tooltip: 'Remove',
                              icon: Icon(
                                Icons.delete_outline,
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ThemeColors.getCardColor(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: ThemeColors.getBorderColor(context),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: !hasMedia
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: ThemeColors.primaryColor
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              size: 28,
                                              color: ThemeColors.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Add photos',
                                            style: TextStyle(
                                              fontFamily: 'Quicksand',
                                              fontWeight: FontWeight.w700,
                                              color: ThemeColors.getTextColor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Camera or gallery',
                                            style: TextStyle(
                                              fontFamily: 'Quicksand',
                                              color:
                                                  ThemeColors.getSecondaryTextColor(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                      File(activeImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedImages.length > 1) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final img = _selectedImages[index];
                              final isActive = index == activeIndex;
                              return GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _activeImageIndex = index;
                                        });
                                      },
                                child: Container(
                                  width: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isActive
                                          ? ThemeColors.primaryColor
                                          : ThemeColors.getBorderColor(context),
                                      width: isActive ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.file(
                                      File(img.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                hasMedia ? 'Change' : 'Add photos',
                                style: const TextStyle(fontFamily: 'Quicksand'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ThemeColors.getTextColor(
                                  context,
                                ),
                                side: BorderSide(
                                  color: ThemeColors.getBorderColor(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Caption card
                _sectionCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Caption',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w700,
                              color: ThemeColors.getTextColor(context),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.short_text,
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _captionController,
                        maxLines: 6,
                        maxLength: 500,
                        enabled: !_isLoading,
                        style: const TextStyle(fontFamily: 'Quicksand'),
                        onChanged: (_) {
                          // Update submit button enabled state
                          if (mounted) setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Write something…',
                          hintStyle: TextStyle(
                            fontFamily: 'Quicksand',
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                          filled: true,
                          fillColor: ThemeColors.getCardColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: ThemeColors.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: ThemeColors.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ThemeColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          counterStyle: TextStyle(
                            fontFamily: 'Quicksand',
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Visibility card
                _sectionCard(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Visibility',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w700,
                              color: ThemeColors.getTextColor(context),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                _visibilityIcon(_visibility),
                                size: 18,
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _visibilityLabel(_visibility),
                                style: TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontWeight: FontWeight.w600,
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allowedVisibilities
                            .map((v) {
                              final selected = _visibility == v;
                              return ChoiceChip(
                                selected: selected,
                                label: Text(
                                  _visibilityLabel(v),
                                  style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? colorScheme.onPrimary
                                        : ThemeColors.getTextColor(context),
                                  ),
                                ),
                                avatar: Icon(
                                  _visibilityIcon(v),
                                  size: 18,
                                  color: selected
                                      ? colorScheme.onPrimary
                                      : ThemeColors.getSecondaryTextColor(
                                          context,
                                        ),
                                ),
                                selectedColor: ThemeColors.primaryColor,
                                backgroundColor: ThemeColors.getCardColor(
                                  context,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  side: BorderSide(
                                    color: selected
                                        ? ThemeColors.primaryColor
                                        : ThemeColors.getBorderColor(context),
                                  ),
                                ),
                                onSelected: _isLoading
                                    ? null
                                    : (_) {
                                        setState(() {
                                          _visibility = v;
                                        });
                                      },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Tags card
                _sectionCard(
                  context: context,
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: Constants.defaultPadding,
                    child: TagSelectionWidget(
                      onTagsChanged: (selectedTagIds, selectedTagNames) {
                        setState(() {
                          _tagIds = selectedTagIds;
                          _tagNames = selectedTagNames;
                        });
                      },
                      initialSelectedTags: _tagNames,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/*   Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: ThemeColors.getTextColor(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: ThemeColors.getSecondaryTextColor(context),
        ),
        onTap: onTap,
      ),
    );
  }

 */