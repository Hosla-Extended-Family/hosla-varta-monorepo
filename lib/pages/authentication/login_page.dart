import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:http/http.dart' as http;
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _phoneNumberController;

  String _getClientPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<String> _handleLogin() async {
    final phoneNumber = _phoneNumberController.text;

    if (phoneNumber.isEmpty) {
      // Show error message
      return "Please enter your phone number.";
    }

    try {
      /* final request = http.Request('POST', Uri.parse('https://comm-involve-drive-sin.trycloudflare.com/api/auth/request-otp/'))
        ..headers['Content-Type'] = 'application/json'
        ..body = '{"phone": "$phoneNumber"}';
      print(request.body);
      final response = await http.Client().send(request);
      print(response.toString());
      final responseBody = await response.stream.bytesToString();
 */
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/request-otp'),
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Platform': _getClientPlatform(),
        },
        body: jsonEncode({'phone': phoneNumber}),
      );
      final responseBody = response.body;
      if (response.statusCode == 200) {
        // Parse response and extract user data
        final responseData = json.decode(responseBody);

        // Save user data to local database
        await _saveUserToDatabase(responseData);

        // Save authentication token and user ID to SharedPreferences
        await _saveAuthData(responseData);

        return "Login successful!";
      } else if (response.statusCode == 404) {
        return "Invalid phone number ";
      } else {
        return "Login failed: $responseBody";
      }
    } catch (e) {
      return "Login failed. Please try again.";
    }
  }

  /// Save user data to local SQLite database
  Future<void> _saveUserToDatabase(Map<String, dynamic> responseData) async {
    try {
      // Extract user data from response
      final userData = responseData['user'] ?? responseData;

      // Get phone number from controller as fallback
      final phoneNumber = _phoneNumberController.text;

      // Create User object from response
      final user = User(
        id:
            userData['id']?.toString() ??
            userData['userId']?.toString() ??
            'current_user',
        name:
            userData['name']?.toString() ??
            userData['username']?.toString() ??
            '',
        email: userData['email']?.toString(),
        phone: userData['phone']?.toString() ?? phoneNumber,
        avatarUrl:
            userData['avatarUrl']?.toString() ?? userData['avatar']?.toString(),
        bio: userData['bio']?.toString(),
        isOnline: true,
      );

      // Save to local database
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.upsertUser(user);

      print('User saved to local database: ${user.id}');
    } catch (e) {
      print('Error saving user to database: $e');
      rethrow;
    }
  }

  /// Save authentication data to SharedPreferences
  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save authentication token if available
      if (responseData.containsKey('token')) {
        await prefs.setString('auth_token', responseData['token'].toString());
      }

      // Save user ID
      final userData = responseData['user'] ?? responseData;
      final userId =
          userData['id']?.toString() ??
          userData['userId']?.toString() ??
          'current_user';
      await prefs.setString('user_id', userId);

      // Save phone number
      final phoneNumber = _phoneNumberController.text;
      final userPhone = userData['phone']?.toString() ?? phoneNumber;
      await prefs.setString('phone_number', userPhone);

      // Save login status
      await prefs.setBool('is_logged_in', true);

      // Save login timestamp
      await prefs.setString('login_time', DateTime.now().toIso8601String());

      print('Auth data saved to SharedPreferences');
    } catch (e) {
      print('Error saving auth data: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    _phoneNumberController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hosla Varta', style: TextThemes.getTitleStyle(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                'Welcome Back!',
                style: TextThemes.getBodyLargeStyle(context),
              ),
            ),
            SizedBox(height: 20),
            // ── Label row ──
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 20, color: ThemeColors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Phone Number',
                    style: TextThemes.getBodyMediumStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            // ── Input row ──
            Row(
              children: [
                Container(
                  width: 100,
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
                    borderRadius: BorderRadius.circular(16),
                    initialValue: '+91',
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                    ],
                    onChanged: (_) {},
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ThemeColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.25),
                      ),
                    ),
                    child: TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontSize: 15),
                      cursorColor: ThemeColors.primaryColor,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle: TextThemes.getBodyMediumStyle(context)
                            .copyWith(
                              color: ThemeColors.getSecondaryTextColor(
                                context,
                              ).withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            /* TextField(
              controller: _passwordController,
              obscureText: true,
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
              ),
            ), */
            /* TextButton(
              onPressed: () async {
                // TODO: Handle forgot password logic here
                Navigator.pushNamed(context, '/forget-password');
              },
              child: Text(
                'Forgot Password?',
                style: TextThemes.getBodySmallStyle(context),
              ),
            ), */
            SizedBox(height: 16),
            Button(
              text: 'Login',
              onPressed: () async {
                final result = await _handleLogin();
                if (result == "Login successful!") {
                  SnackBarWidget.show(context, result);
                  Navigator.pushNamed(
                    context,
                    '/otp-verification',
                    arguments: {
                      'phoneNumber': _phoneNumberController.text,
                      'endRoute': '/home',
                    },
                  );
                } else {
                  SnackBarWidget.show(context, result);
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: TextThemes.getBodySmallStyle(context),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text(
                    'Sign Up',
                    style: TextThemes.getBodySmallStyle(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
