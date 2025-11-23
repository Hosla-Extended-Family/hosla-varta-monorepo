import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProfileProvider);
      if (currentUser != null) {
        _nameController.text = currentUser.name;
        _bioController.text = currentUser.bio ?? '';
        _emailController.text = currentUser.email ?? '';
        // Phone can be added to user model if needed
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: ThemeColors.getNavBarIconColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              ThemeColors.primaryColor,
              ThemeColors.primaryColor.withBlue(200),
            ],
          ).createShader(bounds),
          child: Text(
            'Edit Profile',
            style: TextThemes.getTitleStyle(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isLoading
                    ? ThemeColors.getSecondaryTextColor(context)
                    : ThemeColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Profile Picture Section
            _buildProfilePictureSection(currentUser),

            const SizedBox(height: 32),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildSectionLabel('Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    _buildSectionLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Phone Field
                    _buildSectionLabel('Phone'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    // Bio Field
                    _buildSectionLabel('Bio'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _bioController,
                      hint: 'Tell us about yourself',
                      icon: Icons.info_outline,
                      maxLines: 4,
                      maxLength: 150,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(currentUser) {
    return Column(
      children: [
        Stack(
          children: [
            // Profile Picture
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(200),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.getCardColor(context),
                  border: Border.all(
                    color: ThemeColors.getCardColor(context),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child:
                      currentUser?.avatarUrl != null &&
                          currentUser!.avatarUrl!.isNotEmpty
                      ? Image.network(
                          currentUser.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),

            // Edit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeColors.primaryColor,
                        ThemeColors.primaryColor.withBlue(200),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ThemeColors.getBackgroundColor(context),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeColors.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Change Profile Picture',
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColors.getSurfaceColor(context),
      child: Icon(
        Icons.person,
        size: 50,
        color: ThemeColors.getSecondaryTextColor(context),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextThemes.getBodyMediumStyle(context).copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: ThemeColors.primaryColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : ThemeColors.getOverlayColor(context, opacity: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextThemes.getBodyMediumStyle(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextThemes.getBodyMediumStyle(
            context,
          ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withOpacity(0.15),
                  ThemeColors.primaryColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ThemeColors.primaryColor, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterStyle: TextThemes.getBodySmallStyle(
            context,
          ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Picture',
              style: TextThemes.getBodyLargeStyle(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
                SnackBarWidget.show(context, 'Camera feature coming soon!');
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery picker
                SnackBarWidget.show(context, 'Gallery feature coming soon!');
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Remove Photo',
              color: ThemeColors.errorColor,
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement remove photo
                SnackBarWidget.show(context, 'Photo removed');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? ThemeColors.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? ThemeColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextThemes.getBodyMediumStyle(context).copyWith(
                fontWeight: FontWeight.w500,
                color: color ?? ThemeColors.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(currentUserProfileProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            bio: _bioController.text.trim(),
          );

      if (mounted) {
        SnackBarWidget.show(context, 'Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarWidget.show(
          context,
          'Failed to update profile. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
