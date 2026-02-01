import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:hosla/services/otp_service.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Email verification page with OTP functionality
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;

  bool _isOTPSent = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _loadExistingEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Load existing email if available
  Future<void> _loadExistingEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email != null && email.isNotEmpty) {
        setState(() {
          _emailController.text = email;
        });
      }
    } catch (e) {
      print('Error loading email: $e');
    }
  }

  /// Send OTP to email
  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      SnackBarWidget.show(context, 'Please enter your email address');
      return;
    }

    // Basic email validation
    if (!_isValidEmail(email)) {
      SnackBarWidget.show(context, 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await OTPService.instance.sendOTP(email);

      if (success) {
        setState(() {
          _isOTPSent = true;
          _resendCountdown = 60;
        });

        SnackBarWidget.show(
          context,
          'OTP sent successfully! Check your email.',
        );

        // Start countdown timer
        _startResendTimer();
      } else {
        SnackBarWidget.show(context, 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      SnackBarWidget.show(context, 'An error occurred. Please try again.');
      print('Error sending OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verify OTP
  Future<void> _verifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      SnackBarWidget.show(context, 'Please enter the OTP');
      return;
    }

    if (otp.length != 6) {
      SnackBarWidget.show(context, 'OTP must be 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await OTPService.instance.verifyOTP(email, otp);

      if (success) {
        // Save verified email to SharedPreferences and database
        await _saveVerifiedEmail(email);

        SnackBarWidget.show(context, 'Email verified successfully!');

        // Navigate back to settings
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        SnackBarWidget.show(
          context,
          'Invalid or expired OTP. Please try again.',
        );
      }
    } catch (e) {
      SnackBarWidget.show(context, 'Verification failed. Please try again.');
      print('Error verifying OTP: $e');
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  /// Save verified email to database and SharedPreferences
  Future<void> _saveVerifiedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save to SharedPreferences
      await prefs.setString('user_email', email);
      await prefs.setBool('email_verified', true);

      // Update user in database
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final dbHelper = DatabaseHelper.instance;
        final user = await dbHelper.getUserById(userId);

        if (user != null) {
          final updatedUser = user.copyWith(email: email);
          await dbHelper.upsertUser(updatedUser);
        }
      }

      print('Email verified and saved: $email');
    } catch (e) {
      print('Error saving verified email: $e');
      rethrow;
    }
  }

  /// Resend OTP
  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final success = await OTPService.instance.resendOTP(email);

      if (success) {
        setState(() {
          _resendCountdown = 60;
        });

        SnackBarWidget.show(context, 'OTP resent successfully!');
        _startResendTimer();
      } else {
        SnackBarWidget.show(context, 'Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      SnackBarWidget.show(context, 'An error occurred. Please try again.');
      print('Error resending OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Start countdown timer for resend
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendTimer();
      }
    });
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
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
            'Verify Email',
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
                      ThemeColors.primaryColor.withValues(alpha: 0.15),
                      ThemeColors.primaryColor.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isOTPSent ? Icons.mark_email_read : Icons.email_outlined,
                  size: 80,
                  color: ThemeColors.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                _isOTPSent ? 'Enter Verification Code' : 'Add Email Address',
                style: TextThemes.getBodyLargeStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                _isOTPSent
                    ? 'We sent a 6-digit code to ${_emailController.text}'
                    : 'Enter your email address to verify and secure your account',
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Email Input Field
            if (!_isOTPSent) ...[
              Container(
                decoration: BoxDecoration(
                  color: ThemeColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : ThemeColors.getOverlayColor(context, opacity: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
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
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Send OTP Button
              Button(
                text: _isLoading ? 'Sending...' : 'Send Verification Code',
                onPressed: _isLoading ? null : _sendOTP,
              ),
            ],

            // OTP Input Field
            if (_isOTPSent) ...[
              Container(
                decoration: BoxDecoration(
                  color: ThemeColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : ThemeColors.getOverlayColor(context, opacity: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: TextThemes.getBodyLargeStyle(context).copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter 6-Digit Code',
                    hintText: '000000',
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
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Verify Button
              Button(
                text: _isVerifying ? 'Verifying...' : 'Verify Email',
                onPressed: _isVerifying ? null : _verifyOTP,
              ),

              const SizedBox(height: 16),

              // Resend OTP Section
              Center(
                child: TextButton(
                  onPressed: _resendCountdown > 0 ? null : _resendOTP,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend code in ${_resendCountdown}s'
                        : 'Resend Code',
                    style: TextStyle(
                      color: _resendCountdown > 0
                          ? ThemeColors.getSecondaryTextColor(context)
                          : ThemeColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Change Email Button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isOTPSent = false;
                      _otpController.clear();
                      _resendCountdown = 0;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Change Email Address'),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ThemeColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A 6-digit verification code will be sent to your email. The code is valid for 10 minutes.',
                      style: TextThemes.getBodySmallStyle(
                        context,
                      ).copyWith(color: ThemeColors.primaryColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
