import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:http/http.dart' as http;

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

      if (response.statusCode == 201) {
        // Parse response if needed
        return "Login successful!";
      } else {
        return "Login failed: $responseBody";
      }
    } catch (e) {
      return "Login failed. Please try again.";
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
                    value: '+91',
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
              onPressed: () {
                // TODO: Handle forgot password logic here
                Navigator.pushNamed(context, '/forget-password');
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
