import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    _phoneController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
        title: Text(
          'Forgot Password',
          style: TextThemes.getTitleStyle(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Reset Your Password',
                style: TextThemes.getBodyLargeStyle(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your phone number and we\'ll send you a code to reset your password.',
              style: TextThemes.getBodySmallStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                    controller: _phoneController,
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
            const SizedBox(height: 32),
            Button(
              text: 'Send Reset Code',
              onPressed: () {
                // TODO: Handle forgot password logic here
                if (_phoneController.text.isEmpty) {
                  SnackBarWidget.show(
                    context,
                    'Please enter your phone number',
                  );
                  return;
                }

                // Navigate to OTP verification page
                Navigator.pushNamed(
                  context,
                  '/otp-verification',
                  arguments:
                      '/new-password', // 👈 tell it where to go after OTP
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember your password?',
                  style: TextThemes.getBodySmallStyle(context),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Sign In',
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
