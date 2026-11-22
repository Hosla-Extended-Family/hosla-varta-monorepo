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
    final phoneNumber = _phoneNumberController.text.trim();

    if (phoneNumber.isEmpty) {
      return "Please enter your phone number.";
    }

    try {
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
        return "OTP sent successfully!";
      } else if (response.statusCode == 404) {
        return "Invalid phone number";
      } else {
        try {
          final decoded = json.decode(responseBody);
          return decoded['error']?['message'] ?? decoded['message'] ?? "Failed to send OTP: $responseBody";
        } catch (_) {
          return "Failed to send OTP: $responseBody";
        }
      }
    } catch (e) {
      debugPrint('Login request failed: $e');
      return "Failed to send OTP: $e";
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
                    isExpanded: true,
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
                if (result == "OTP sent successfully!") {
                  SnackBarWidget.show(context, 'OTP sent successfully to your number');
                  Navigator.pushNamed(
                    context,
                    '/otp-verification',
                    arguments: {
                      'phoneNumber': _phoneNumberController.text.trim(),
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
