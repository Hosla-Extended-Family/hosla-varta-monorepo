import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/widgets/button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hosla Varta', style: TextThemes.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(child: Text('Welcome Back!', style: TextThemes.bodyLarge)),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Handle forgot password logic here
              },
              child: Text('Forgot Password?', style: TextThemes.bodySmall),
            ),
            SizedBox(height: 16),
            Button(
              text: 'Login',
              onPressed: () {
                // TODO: Handle login logic here
                Navigator.pushNamed(
                  context,
                  '/otp-verification',
                  arguments: '/home', // 👈 tell it where to go after OTP
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account?', style: TextThemes.bodySmall),
                TextButton(
                  onPressed: () {},
                  child: Text('Sign Up', style: TextThemes.bodySmall),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
