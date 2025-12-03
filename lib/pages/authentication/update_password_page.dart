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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('New Password', style: TextThemes.getTitleStyle(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            // New Password Field
            TextField(
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: 'New Password',
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Password Requirements
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: TextThemes.getBodySmallStyle(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• At least 6 characters long',
                    style: TextThemes.getBodySmallStyle(context),
                  ),
                  Text(
                    '• Must be different from previous password',
                    style: TextThemes.getBodySmallStyle(context),
                  ),
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
}
