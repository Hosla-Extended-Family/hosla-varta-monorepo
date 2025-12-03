import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling OTP generation and verification
class OTPService {
  static final OTPService instance = OTPService._internal();

  OTPService._internal();

  /// Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Send OTP to email address
  /// In a real application, this would call a backend API to send the email
  Future<bool> sendOTP(String email) async {
    try {
      final otp = _generateOTP();

      // Save OTP and timestamp to SharedPreferences for verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_otp', otp);
      await prefs.setString('email_otp_email', email);
      await prefs.setString(
        'email_otp_timestamp',
        DateTime.now().toIso8601String(),
      );

      print('Generated OTP: $otp for email: $email');

      // TODO: In production, call your backend API to send email
      // Example:
      // final response = await http.post(
      //   Uri.parse('/api/auth/send-otp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'email': email, 'otp': otp}),
      // );
      // return response.statusCode == 200;

      // For now, return true to simulate successful sending
      // In development, you can check the console for the OTP
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOTP = prefs.getString('email_otp');
      final savedEmail = prefs.getString('email_otp_email');
      final timestampStr = prefs.getString('email_otp_timestamp');

      if (savedOTP == null || savedEmail == null || timestampStr == null) {
        print('No OTP found in storage');
        return false;
      }

      // Check if email matches
      if (savedEmail != email) {
        print('Email mismatch');
        return false;
      }

      // Check if OTP has expired (valid for 10 minutes)
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp).inMinutes;

      if (difference > 10) {
        print('OTP expired');
        // Clear expired OTP
        await clearOTP();
        return false;
      }

      // Verify OTP
      if (savedOTP == otp) {
        // Clear OTP after successful verification
        await clearOTP();
        return true;
      }

      print('OTP mismatch');
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  /// Clear OTP data from SharedPreferences
  Future<void> clearOTP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email_otp');
      await prefs.remove('email_otp_email');
      await prefs.remove('email_otp_timestamp');
    } catch (e) {
      print('Error clearing OTP: $e');
    }
  }

  /// Resend OTP
  Future<bool> resendOTP(String email) async {
    // Clear old OTP
    await clearOTP();

    // Send new OTP
    return await sendOTP(email);
  }
}
