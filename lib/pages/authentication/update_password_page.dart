import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:http/http.dart' as http;

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isPasswordValid(String password) {
    // Basic password validation: at least 6 characters
    return password.length >= 6;
  }

  bool _doPasswordsMatch() {
    return _newPasswordController.text == _confirmPasswordController.text;
  }

  Future<String> _handleResetPassword() async {
    // TODO: check the api endpoint
    final newPassword = _newPasswordController.text;
    try {
      final request = http.Request('POST', Uri.parse('/auth/reset-password'))
        ..headers['Content-Type'] = 'application/json'
        ..body =
            '{"phoneNumber": "${widget.phoneNumber}", "newPassword": "$newPassword"}';
      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        return "Password reset successfully";
      } else {
        return "Failed to reset password";
      }
    } catch (e) {
      return "Failed to reset password. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            'New Password',
            style: TextThemes.getTitleStyle(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Header Section
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeColors.primaryColor.withOpacity(0.15),
                      ThemeColors.primaryColor.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: ThemeColors.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Create New Password',
                style: TextThemes.getBodyLargeStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'Your new password must be different from your previous password',
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // New Password Field
            Container(
              decoration: BoxDecoration(
                color: ThemeColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors.getBorderColor(context).withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : ThemeColors.getOverlayColor(context, opacity: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: ThemeColors.primaryColor,
                  ),
                  filled: false,
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            Container(
              decoration: BoxDecoration(
                color: ThemeColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors.getBorderColor(context).withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : ThemeColors.getOverlayColor(context, opacity: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter your new password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: ThemeColors.primaryColor,
                  ),
                  filled: false,
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor.withOpacity(0.08),
                    ThemeColors.primaryColor.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeColors.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: ThemeColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Password Requirements',
                        style: TextThemes.getBodyMediumStyle(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRequirement('At least 6 characters long'),
                  const SizedBox(height: 6),
                  _buildRequirement('Must be different from previous password'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reset Password Button
            Button(
              text: 'Reset Password',
              onPressed: () {
                if (_newPasswordController.text.isEmpty) {
                  SnackBarWidget.show(context, 'Please enter a new password!');
                  return;
                }

                if (!_isPasswordValid(_newPasswordController.text)) {
                  SnackBarWidget.show(
                    context,
                    'Password must be at least 6 characters long',
                  );
                  return;
                }

                if (_confirmPasswordController.text.isEmpty) {
                  SnackBarWidget.show(
                    context,
                    'Please confirm your new password!',
                  );
                  return;
                }

                if (!_doPasswordsMatch()) {
                  SnackBarWidget.show(context, 'Passwords do not match!');
                  return;
                }
                _handleResetPassword().then((result) {
                  if (result == "Password reset successfully") {
                    SnackBarWidget.show(context, result);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  } else {
                    SnackBarWidget.show(context, result);
                  }
                  // Navigate to login page after successful password reset
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: ThemeColors.primaryColor.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ),
      ],
    );
  }
}
