import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _isNewPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String> _handleSignup() async {
    final phoneNumber = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (phoneNumber.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      // Show error message
      return "Please enter all fields.";
    }

    if (password != confirmPassword) {
      return "Passwords do not match.";
    }

    try {
      final request = http.Request('POST', Uri.parse('/api/auth/register'))
        ..headers['Content-Type'] = 'application/json'
        ..body = '{"phone": "$phoneNumber", "password": "$password"}';

      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        // Parse response and save only phone number and user ID
        final responseData = json.decode(responseBody);

        // Save minimal authentication data to SharedPreferences
        await _saveAuthData(responseData);

        return "Signup successful!";
      } else if (response.statusCode == 400) {
        return "User already exists.";
      } else {
        return "Signup failed: $responseBody";
      }
    } catch (e) {
      return "Signup failed. Please try again.";
    }
  }

  /// Save authentication data to SharedPreferences (only phone and user ID)
  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save authentication token if available
      if (responseData.containsKey('token')) {
        await prefs.setString('auth_token', responseData['token'].toString());
      }

      // Generate or extract user ID
      final userData = responseData['user'] ?? responseData;
      final userId =
          userData['id']?.toString() ??
          userData['userId']?.toString() ??
          'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);

      // Save phone number
      final phoneNumber = _emailController.text;
      final userPhone = userData['phone']?.toString() ?? phoneNumber;
      await prefs.setString('phone_number', userPhone);

      // Save login status
      await prefs.setBool('is_logged_in', true);

      // Save signup timestamp
      await prefs.setString('signup_time', DateTime.now().toIso8601String());

      print(
        'Auth data saved to SharedPreferences - User ID: $userId, Phone: $userPhone',
      );
    } catch (e) {
      print('Error saving auth data: $e');
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
        title: Text('Sign Up', style: TextThemes.getTitleStyle(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Welcome to Hosla Varta!',
              style: TextThemes.getBodyLargeStyle(context),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    borderRadius: BorderRadius.circular(16),
                    initialValue: '+91',
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                    ],
                    onChanged: (_) {},
                    decoration: InputDecoration(
                      labelText: 'Code',
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
                        horizontal: 12.0,
                        vertical: 16.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
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
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
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
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _isConfirmPasswordVisible,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.errorColor,
                    width: 2.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: ThemeColors.errorColor,
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
                errorText: _confirmPasswordController.text.isEmpty
                    ? null
                    : (_confirmPasswordController.text ==
                              _passwordController.text
                          ? null
                          : 'Passwords do not match'),
              ),
            ),
            SizedBox(height: 24),
            Button(
              text: 'Next',
              onPressed:
                  _confirmPasswordController.text == _passwordController.text &&
                      _confirmPasswordController.text.isNotEmpty
                  ? () {
                      _handleSignup().then((result) {
                        if (result == "Signup successful!") {
                          SnackBarWidget.show(context, result);
                          Navigator.pushNamed(context, '/create-profile');
                        } else {
                          SnackBarWidget.show(context, result);
                        }
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
