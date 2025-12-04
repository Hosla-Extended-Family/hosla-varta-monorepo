import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  XFile? _selectedImage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          // Open image editor
          await _openImageEditor(image);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick image: $e',
              style: const TextStyle(fontFamily: 'Quicksand'),
            ),
            backgroundColor: ThemeColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openImageEditor(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      if (!mounted) return;

      final BuildContext currentContext = context;

      final editedImage = await Navigator.push<Uint8List>(
        currentContext,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                Navigator.pop(context, bytes);
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
          _selectedImage = XFile(tempFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to edit image: $e',
              style: const TextStyle(fontFamily: 'Quicksand'),
            ),
            backgroundColor: ThemeColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _createPost() {
    if (_selectedImage == null && _captionController.text.trim().isEmpty) {
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

    // TODO: Implement post creation logic
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Post created successfully!',
            style: TextStyle(fontFamily: 'Quicksand'),
          ),
          backgroundColor: ThemeColors.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ThemeColors.getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ThemeColors.getTextColor(context),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isLoading ? null : _createPost,
              style: TextButton.styleFrom(
                backgroundColor: ThemeColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                disabledBackgroundColor: ThemeColors.primaryColor.withOpacity(
                  0.5,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Selection Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 400,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(context),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_selectedImage!.path),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _openImageEditor(_selectedImage!),
                                    tooltip: 'Edit Image',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    tooltip: 'Remove Image',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: ThemeColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ThemeColors.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select from camera or gallery',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 14,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Caption Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Caption',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.getTextColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.getBorderColor(context)),
              ),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                maxLength: 500,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 15,
                  color: ThemeColors.getTextColor(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: TextStyle(
                    fontFamily: 'Quicksand',
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    fontFamily: 'Quicksand',
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Add to your post',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.getTextColor(context),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildOptionTile(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Add Location',
              color: Colors.red,
              onTap: () {
                // TODO: Add location
              },
            ),
            _buildOptionTile(
              context: context,
              icon: Icons.person_add_outlined,
              title: 'Tag People',
              color: Colors.blue,
              onTap: () {
                // TODO: Tag people
              },
            ),
            _buildOptionTile(
              context: context,
              icon: Icons.mood_outlined,
              title: 'Feeling/Activity',
              color: Colors.orange,
              onTap: () {
                // TODO: Add feeling
              },
            ),
            _buildOptionTile(
              context: context,
              icon: Icons.music_note_outlined,
              title: 'Add Music',
              color: Colors.purple,
              onTap: () {
                // TODO: Add music
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
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
            color: color.withOpacity(0.1),
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
}
