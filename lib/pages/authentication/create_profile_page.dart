import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:hosla/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  String? _selectedGender;
  DateTime? _selectedDate;
  String? _profileImageUrl;
  XFile? _selectedImage;

  @override
  void initState() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectProfileImage() async {
    try {
      // Show options to select from gallery or camera
      final XFile? image = await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Profile Picture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(
                      context,
                      await _picker.pickImage(source: ImageSource.gallery),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(
                      context,
                      await _picker.pickImage(source: ImageSource.camera),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _profileImageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarWidget.show(context, 'Failed to select image: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Save profile data to local database and SharedPreferences
  Future<void> _saveProfileData({bool isSkip = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get user ID from SharedPreferences
      final userId =
          prefs.getString('user_id') ??
          'user_${DateTime.now().millisecondsSinceEpoch}';
      final phoneNumber = prefs.getString('phone_number') ?? '';

      // Handle default values when skipping
      final userName = isSkip ? 'User' : _nameController.text;
      final userEmail = isSkip
          ? null
          : (_emailController.text.isNotEmpty ? _emailController.text : null);
      final userBio = isSkip
          ? null
          : (_bioController.text.isNotEmpty ? _bioController.text : null);
      final userGender = isSkip ? null : _selectedGender;
      final userDob = isSkip ? null : _selectedDate;
      String? avatarUrl = _profileImageUrl;

      // Upload image if selected and not skipping
      if (!isSkip && _selectedImage != null) {
        try {
          avatarUrl = await _userService.updateUserAvatar(_selectedImage!.path);
        } catch (e) {
          print('Error uploading avatar: $e');
          // Use local path as fallback
          avatarUrl = _selectedImage!.path;
        }
      }

      // Create User object with all profile data
      final user = User(
        id: userId,
        name: userName,
        email: userEmail,
        phone: phoneNumber,
        avatarUrl: avatarUrl,
        bio: userBio,
        isOnline: true,
      );

      // Make API call to create/update profile
      if (!isSkip) {
        try {
          await _userService.updateUserProfile(user);
          print('Profile synced with server successfully');
        } catch (e) {
          print('Error syncing profile with server: $e');
          // Continue with local save even if API fails
        }
      }

      // Save to local database
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.upsertUser(user);

      // Save profile data to SharedPreferences
      await prefs.setString('user_name', userName);
      if (userEmail != null) {
        await prefs.setString('user_email', userEmail);
      }
      if (userBio != null) {
        await prefs.setString('user_bio', userBio);
      }
      if (avatarUrl != null) {
        await prefs.setString('user_avatar', avatarUrl);
      }
      if (userGender != null) {
        await prefs.setString('user_gender', userGender);
      }
      if (userDob != null) {
        await prefs.setString('user_dob', userDob.toIso8601String());
      }

      // Mark profile as completed
      await prefs.setBool('profile_completed', true);

      print('Profile saved successfully - User ID: $userId, Name: $userName');
    } catch (e) {
      print('Error saving profile data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Create Profile', style: TextThemes.getTitleStyle(context)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              // Skip profile creation with default values
              try {
                await _saveProfileData(isSkip: true);
                if (mounted) {
                  SnackBarWidget.show(
                    context,
                    'Profile skipped. You can complete it later!',
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarWidget.show(
                    context,
                    'Failed to skip profile. Please try again.',
                  );
                }
                print('Error skipping profile: $e');
              }
            },
            child: Text(
              'Skip',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(context),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Complete Your Profile',
                style: TextThemes.getBodyLargeStyle(context),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Picture Section
            _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : ProfilePic(
                    imageUrl:
                        _profileImageUrl ??
                        'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
                  ),
            const SizedBox(height: 16),

            // Upload Picture Button
            TextButton.icon(
              onPressed: _selectProfileImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload Picture'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: ThemeColors.getSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.primaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date of Birth Field
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Date of Birth',
                      style: _selectedDate != null
                          ? TextThemes.getBodyMediumStyle(context)
                          : TextThemes.getBodyMediumStyle(context).copyWith(
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: ThemeColors.getBorderColor(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedDate == null
                  ? const SizedBox.shrink()
                  : Row(
                      key: const ValueKey('age_row'),
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 20,
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Age',
                          style: TextThemes.getBodyMediumStyle(context),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text('${_calculateAge(_selectedDate!)} years'),
                          backgroundColor: ThemeColors.getSuccessSurface(
                            context,
                          ),
                          side: BorderSide(
                            color: ThemeColors.getBorderColor(context),
                          ),
                          labelStyle: TextThemes.getBodySmallStyle(
                            context,
                          ).copyWith(color: ThemeColors.getTextColor(context)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            // Email Field (Optional)
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email (Optional)',
                filled: true,
                fillColor: ThemeColors.getSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.primaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                filled: true,
                fillColor: ThemeColors.getSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.primaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Bio Field
            TextField(
              controller: _bioController,
              maxLength: 100,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                filled: true,
                fillColor: ThemeColors.getSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.primaryColor,
                    width: 2.0,
                  ),
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create Profile Button
            Button(
              text: 'Create Profile',
              onPressed: () async {
                // Validate required fields
                if (_nameController.text.isEmpty) {
                  SnackBarWidget.show(context, 'Please enter your name');
                  return;
                }

                // Save profile data to backend or local storage
                try {
                  await _saveProfileData(isSkip: false);
                  if (mounted) {
                    SnackBarWidget.show(
                      context,
                      'Profile created successfully!',
                    );

                    // Navigate to home page after successful profile creation
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarWidget.show(
                      context,
                      'Failed to create profile. Please try again.',
                    );
                  }
                  print('Error creating profile: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
