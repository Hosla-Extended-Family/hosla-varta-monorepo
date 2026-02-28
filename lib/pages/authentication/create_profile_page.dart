import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/widgets/hosla_text_field.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:hosla/services/user_service.dart';
import 'package:http/http.dart' as http;
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

  String _getClientPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<String> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return "Please enter your name.";
    }
    // Enforce mandatory fields at API-call level
    if (_selectedDate == null) {
      return "Please select your date of birth.";
    }
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      return "Please select your gender.";
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Headers (don't set Content-Type manually; MultipartRequest handles boundary)
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-Client-Platform'] = _getClientPlatform();

      // Text fields
      request.fields['name'] = name;
      final email = _emailController.text.trim();
      final bio = _bioController.text.trim();
      if (email.isNotEmpty) request.fields['email'] = email;
      if (bio.isNotEmpty) request.fields['bio'] = bio;
      // Required fields
      request.fields['gender'] = _selectedGender!.toUpperCase();
      request.fields['dateOfBirth'] = _formatDobForServer(_selectedDate!);

      // File field (profile picture)
      if (_selectedImage != null) {
        final file = await http.MultipartFile.fromPath(
          'profilePicture',
          _selectedImage!.path,
          filename: _selectedImage!.name,
        );
        request.files.add(file);
      } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        // Fallback to sending URL if available
        request.fields['profilePictureUrl'] = _profileImageUrl!;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return "Profile created successfully!";
      } else {
        return "Failed to create profile: ${response.body}";
      }
    } catch (e) {
      return "Failed to create profile. Please try again.";
    }
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

  // Format DOB for server as DD-MM-YYYY
  String _formatDobForServer(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd-$mm-$yyyy';
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
          await _userService.updateUserProfile(
            user,
            gender: userGender,
            dateOfBirth: userDob,
            profileImagePath: _selectedImage?.path,
          );
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
            HoslaTextField(
              label: 'Name',
              icon: Icons.person,
              controller: _nameController,
              hintText: 'Enter your name',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // Date of Birth Field
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    size: 20,
                    color: ThemeColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date of Birth',
                    style: TextThemes.getBodyMediumStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Select date',
                      style: _selectedDate != null
                          ? TextThemes.getBodyMediumStyle(
                              context,
                            ).copyWith(fontSize: 15)
                          : TextThemes.getBodyMediumStyle(context).copyWith(
                              color: ThemeColors.getSecondaryTextColor(
                                context,
                              ).withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: ThemeColors.getSecondaryTextColor(context),
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
            HoslaTextField(
              label: 'Email (Optional)',
              icon: Icons.email_outlined,
              controller: _emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: ThemeColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gender',
                    style: TextThemes.getBodyMediumStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: ThemeColors.getCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.25),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                borderRadius: BorderRadius.circular(14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                hint: Text(
                  'Select gender',
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.4),
                    fontSize: 14,
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
            ),
            const SizedBox(height: 16),

            // Bio Field
            HoslaTextField(
              label: 'Bio',
              icon: Icons.info_outline,
              controller: _bioController,
              hintText: 'Tell us about yourself...',
              maxLength: 100,
              maxLines: 3,
              showCounter: true,
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
                if (_selectedDate == null) {
                  SnackBarWidget.show(
                    context,
                    'Please select your date of birth',
                  );
                  return;
                }
                if (_selectedGender == null || _selectedGender!.isEmpty) {
                  SnackBarWidget.show(context, 'Please select your gender');
                  return;
                }

                // Save profile data to backend or local storage
                try {
                  final result = await _createProfile();
                  if (result.startsWith('Profile created successfully')) {
                    await _saveProfileData(isSkip: false);
                    SnackBarWidget.show(
                      context,
                      'Profile created successfully!',
                    );
                    // Navigate to home page after successful profile creation
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    SnackBarWidget.show(context, result);
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
