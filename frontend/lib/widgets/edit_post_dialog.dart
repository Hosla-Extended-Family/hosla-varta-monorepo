import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/widgets/hosla_text_field.dart';

/// Dialog for editing a post
class EditPostDialog extends ConsumerStatefulWidget {
  final Post post;

  const EditPostDialog({super.key, required this.post});

  @override
  ConsumerState<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends ConsumerState<EditPostDialog> {
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late TextEditingController _imageUrlController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _tagsController = TextEditingController(text: widget.post.tags.join(', '));
    _imageUrlController = TextEditingController(
      text: widget.post.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final content = _contentController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final postActions = ref.read(postActionsProvider);
    final result = await postActions.editPost(
      post: widget.post,
      content: content,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      tagNames: tags,
    );

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
    } else if (result['conflict'] == true) {
      // Show conflict dialog
      _showConflictDialog(result['message']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update post')),
      );
    }
  }

  void _showConflictDialog(String? message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Detected'),
        content: Text(message ?? 'The post has been modified elsewhere.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePost(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Post',
                      style: TextThemes.getTitleStyle(
                        context,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content Field
                HoslaTextField(
                  label: 'Content',
                  icon: Icons.edit,
                  controller: _contentController,
                  hintText: 'What\'s on your mind?',
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Content cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image URL Field
                HoslaTextField(
                  label: 'Image URL (optional)',
                  icon: Icons.image,
                  controller: _imageUrlController,
                  hintText: 'https://example.com/image.jpg',
                ),
                const SizedBox(height: 16),

                // Tags Field
                HoslaTextField(
                  label: 'Tags (optional)',
                  icon: Icons.tag,
                  controller: _tagsController,
                  hintText: 'tag1, tag2, tag3',
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _savePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
