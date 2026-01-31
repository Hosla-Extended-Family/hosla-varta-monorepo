import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  File? _selectedImage;
  String? _currentAvatarUrl;

  final List<String> _genderOptions = ['MALE', 'FEMALE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final currentUser = ref.read(currentUserProfileProvider);
    final prefs = await SharedPreferences.getInstance();

    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _bioController.text = currentUser.bio ?? '';
      _emailController.text = currentUser.email ?? '';
      _currentAvatarUrl = currentUser.avatarUrl;
    }

    // Load gender from prefs
    final savedGender = prefs.getString('user_gender');
    if (savedGender != null &&
        _genderOptions.contains(savedGender.toUpperCase())) {
      _selectedGender = savedGender.toUpperCase();
    }

    // Load DOB from prefs
    final savedDob = prefs.getString('user_dob');
    if (savedDob != null && savedDob.isNotEmpty) {
      try {
        _selectedDateOfBirth = DateTime.parse(savedDob);
      } catch (_) {}
    }

    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient and profile picture
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient header
                    _buildHeader(topPadding, isDark),
                    // Profile picture positioned at bottom of header
                    Positioned(
                      bottom: -55,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildProfilePictureSection()),
                    ),
                  ],
                ),

                // Spacer for profile picture overflow
                const SizedBox(height: 70),

                // Form Content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personal Information Section
                          _buildSectionTitle('Personal Information'),
                          const SizedBox(height: 16),

                          // Name Field
                          _buildInputCard(
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            child: _buildTextField(
                              controller: _nameController,
                              hint: 'Enter your full name',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              onChanged: (_) => _markAsChanged(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Gender
                          _buildInputCard(
                            label: 'Gender',
                            icon: Icons.wc_rounded,
                            child: _buildGenderDropdown(),
                          ),

                          const SizedBox(height: 16),

                          // Date of Birth
                          _buildInputCard(
                            label: 'Date of Birth',
                            icon: Icons.cake_rounded,
                            child: _buildDatePicker(),
                          ),

                          const SizedBox(height: 32),

                          // Contact Information Section
                          _buildSectionTitle('Contact Information'),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildInputCard(
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            isOptional: true,
                            child: _buildTextField(
                              controller: _emailController,
                              hint: 'Enter your email',
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
                              onChanged: (_) => _markAsChanged(),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // About Section
                          _buildSectionTitle('About You'),
                          const SizedBox(height: 16),

                          // Bio Field
                          _buildInputCard(
                            label: 'Bio',
                            icon: Icons.edit_note_rounded,
                            isOptional: true,
                            child: _buildTextField(
                              controller: _bioController,
                              hint: 'Tell us about yourself...',
                              maxLines: 4,
                              maxLength: 150,
                              onChanged: (_) => _markAsChanged(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Bar
          _buildTopBar(topPadding, isDark),

          // Bottom Save Button
          _buildBottomSaveButton(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding, bool isDark) {
    return Container(
      height: 200 + topPadding,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.primaryColor,
            ThemeColors.primaryColor.withBlue(180),
            ThemeColors.secondaryColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          CustomPaint(
            size: Size(double.infinity, 200 + topPadding),
            painter: _PatternPainter(),
          ),
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double topPadding, bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding),
        child: Row(
          children: [
            // Back Button
            IconButton(
              onPressed: () {
                if (_hasChanges) {
                  _showDiscardDialog();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            const Expanded(
              child: Text(
                'Edit Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Placeholder for symmetry
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Stack(
        children: [
          // Profile Picture Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeColors.primaryColor,
                  ThemeColors.primaryColor.withBlue(200),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeColors.getSurfaceColor(context),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                      )
                    : (_currentAvatarUrl != null &&
                              _currentAvatarUrl!.isNotEmpty
                          ? Image.network(
                              _currentAvatarUrl!,
                              fit: BoxFit.cover,
                              width: 110,
                              height: 110,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar()),
              ),
            ),
          ),

          // Camera Icon
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(180),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeColors.getSurfaceColor(context),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 110,
      height: 110,
      color: ThemeColors.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: 50,
        color: ThemeColors.primaryColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ThemeColors.primaryColor, ThemeColors.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextThemes.getTitleStyle(
            context,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required Widget child,
    bool isOptional = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeColors.primaryColor.withOpacity(0.15),
                        ThemeColors.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: ThemeColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.getTextColor(context),
                  ),
                ),
                if (isOptional) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColors.getSecondaryTextColor(
                        context,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Optional',
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        fontSize: 10,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: TextThemes.getBodyMediumStyle(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextThemes.getBodyMediumStyle(context).copyWith(
          color: ThemeColors.getSecondaryTextColor(context).withOpacity(0.5),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterStyle: TextThemes.getBodySmallStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedGender,
        hint: Text(
          'Select gender',
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.getSecondaryTextColor(context).withOpacity(0.5),
          ),
        ),
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: ThemeColors.primaryColor,
        ),
        items: _genderOptions.map((gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Row(
              children: [
                Icon(
                  gender == 'MALE'
                      ? Icons.male_rounded
                      : gender == 'FEMALE'
                      ? Icons.female_rounded
                      : Icons.transgender_rounded,
                  size: 18,
                  color: ThemeColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _capitalizeFirst(gender),
                  style: TextThemes.getBodyMediumStyle(context),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
          _markAsChanged();
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDateOfBirth != null
                    ? _formatDate(_selectedDateOfBirth!)
                    : 'Select date',
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: _selectedDateOfBirth != null
                      ? ThemeColors.getTextColor(context)
                      : ThemeColors.getSecondaryTextColor(
                          context,
                        ).withOpacity(0.5),
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: ThemeColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSaveButton(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _isLoading ? null : _saveProfile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: _hasChanges && !_isLoading
                  ? LinearGradient(
                      colors: [
                        ThemeColors.primaryColor,
                        ThemeColors.primaryColor.withBlue(180),
                      ],
                    )
                  : null,
              color: _hasChanges && !_isLoading
                  ? null
                  : ThemeColors.getSecondaryTextColor(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _hasChanges && !_isLoading
                  ? [
                      BoxShadow(
                        color: ThemeColors.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: _hasChanges
                              ? Colors.white
                              : ThemeColors.getSecondaryTextColor(context),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasChanges
                                ? Colors.white
                                : ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
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
                style: TextThemes.getTitleStyle(
                  context,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // Options
              _buildImageOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take Photo',
                subtitle: 'Use camera to capture',
                color: ThemeColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              _buildImageOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                color: ThemeColors.secondaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              if (_selectedImage != null ||
                  (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty))
                _buildImageOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  subtitle: 'Use default avatar',
                  color: ThemeColors.errorColor,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _currentAvatarUrl = null;
                    });
                    _markAsChanged();
                  },
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _markAsChanged();
      }
    } catch (e) {
      SnackBarWidget.show(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeColors.primaryColor,
              onPrimary: Colors.white,
              surface: ThemeColors.getSurfaceColor(context),
              onSurface: ThemeColors.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
      _markAsChanged();
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: ThemeColors.warningColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Discard Changes?',
              style: TextThemes.getTitleStyle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextThemes.getBodyMediumStyle(
            context,
          ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Editing',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_selectedGender == null) {
      SnackBarWidget.show(context, 'Please select your gender');
      return;
    }

    if (_selectedDateOfBirth == null) {
      SnackBarWidget.show(context, 'Please select your date of birth');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final currentUser = ref.read(currentUserProfileProvider);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Create updated user object
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
      );

      // Call API with multipart form data through the provider
      await ref
          .read(currentUserProfileProvider.notifier)
          .updateProfileFull(
            user: updatedUser,
            dateOfBirth: _selectedDateOfBirth,
            gender: _selectedGender,
            profileImagePath: _selectedImage?.path,
          );

      // Save gender and DOB to prefs for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_gender', _selectedGender!);
      await prefs.setString(
        'user_dob',
        _selectedDateOfBirth!.toIso8601String(),
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        SnackBarWidget.show(context, 'Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarWidget.show(
          context,
          'Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

/// Custom painter for the pattern overlay
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 25.0;
    const radius = 3.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (
        double x = (y ~/ spacing).isEven ? 0 : spacing / 2;
        x < size.width;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
