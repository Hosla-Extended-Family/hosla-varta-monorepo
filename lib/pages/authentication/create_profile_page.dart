import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;

  String? _selectedGender;
  DateTime? _selectedDate;
  String? _profileImageUrl;

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

  void _selectProfileImage() {
    // TODO: Implement image picker functionality
    setState(() {
      _profileImageUrl =
          'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg';
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            ProfilePic(
              imageUrl:
                  _profileImageUrl ??
                  'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
            ),
            const SizedBox(height: 16),

            // Upload Picture Button
            TextButton.icon(
              onPressed: () {
                // TODO: Implement image picker functionality
                _selectProfileImage();
              },
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
              onPressed: () {
                // TODO: Handle profile creation logic
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
                if (_selectedGender == null) {
                  SnackBarWidget.show(context, 'Please select your gender');
                  return;
                }

                // TODO: Save profile data to backend or local storage

                // Navigate to home page after successful profile creation
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
