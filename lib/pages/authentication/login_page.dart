import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
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
  late final TextEditingController _passwordController;

  Future<String> _handleLogin() async {
    final phoneNumber = _phoneNumberController.text;
    final password = _passwordController.text;

    if (phoneNumber.isEmpty || password.isEmpty) {
      // Show error message
      return "Please enter both phone number and password.";
    }

    try {
      final request = http.Request('POST', Uri.parse('/api/auth/register'))
        ..headers['Content-Type'] = 'application/json'
        ..body = '{"phone": "$phoneNumber", "password": "$password"}';

      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse response and extract user data
        final responseData = json.decode(responseBody);

        // Save user data to local database
        await _saveUserToDatabase(responseData);

        // Save authentication token and user ID to SharedPreferences
        await _saveAuthData(responseData);

        return "Login successful!";
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
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
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
                    controller: _phoneNumberController,
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
            ),
            TextButton(
              onPressed: () async {
                // TODO: Handle forgot password logic here
                //Navigator.pushNamed(context, '/forget-password');
              },
              child: Text(
                'Forgot Password?',
                style: TextThemes.getBodySmallStyle(context),
              ),
            ),
            SizedBox(height: 16),
            Button(
              text: 'Login',
              onPressed: () async {
                final result = await _handleLogin();
                if (result == "Login successful!") {
                  Navigator.pushNamed(
                    context,
                    '/otp-verification',
                    arguments: '/home',
                  );
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result)));
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
