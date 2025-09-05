import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/widgets/button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Sign Up', style: TextThemes.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text('Welcome to Hosla Varta!', style: TextThemes.bodyLarge),
            const SizedBox(height: 24),
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
              obscureText: _isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
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
                      // TODO: Handle sign up logic
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}


// TextField(
//               controller: _confirmPasswordController,
//               obscureText: !_isConfirmPasswordVisible,
//               decoration: InputDecoration(
//                 labelText: 'Confirm New Password',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _isConfirmPasswordVisible
//                         ? Icons.visibility
//                         : Icons.visibility_off,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
//                     });
//                   },
//                 ),
//               ),
//             ),