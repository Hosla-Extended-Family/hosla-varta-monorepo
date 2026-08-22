import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/hosla_text_field.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
// http not needed here; API handled by AuthService
import 'package:hosla/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OtpVerificationPage extends StatefulWidget {
  OtpVerificationPage({
    super.key,
    required this.endRoute,
    required this.phoneNumber,
  });

  final String endRoute;
  final String phoneNumber;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with RouteAware {
  late final TextEditingController _otpController;
  Timer? _resendTimer;
  static const int _initialSeconds = 60;
  int _secondsRemaining = _initialSeconds;
  bool get _canResend => _secondsRemaining == 0;

  @override
  void initState() {
    _otpController = TextEditingController();
    super.initState();
    _startResendCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as ModalRoute<void>);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = _initialSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<String> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      return "Please enter the OTP.";
    }

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }

      final result = await AuthService.instance.verifyOtp(
        phone: widget.phoneNumber,
        otp: otp,
        // Optionally pass FCM token/model if available
        fcmToken: fcmToken,
        deviceModel: null,
      );

      final success = (result['success'] == true);
      if (success) {
        final data = result['data'] as Map<String, dynamic>?;
        final isNewUser = data?['isNewUser'] == true;
        final user = data?['user'] as Map<String, dynamic>?;
        final name = user?['name']?.toString().trim() ?? '';
        if (isNewUser || name.isEmpty) {
          return "NEEDS_PROFILE";
        }
        return "SUCCESS";
      }
      return "OTP verification failed.";
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg.isNotEmpty ? msg : "OTP verification failed. Please try again.";
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    // TODO: Integrate your resend OTP API call here.
    if (!mounted) return;
    SnackBarWidget.show(context, 'OTP resent');
    _startResendCountdown();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // RouteAware hooks
  @override
  void didPushNext() {
    // Another page has been pushed on top of this one; pause countdown.
    _resendTimer?.cancel();
  }

  @override
  void didPopNext() {
    // Returned to this page; restart countdown to full duration.
    _startResendCountdown();
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
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                'OTP Verification',
                style: TextThemes.getTitleStyle(context),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Enter the 6-digit OTP sent to your phone number',
                style: TextThemes.getBodyMediumStyle(context),
              ),
            ),
            SizedBox(height: 20),
            HoslaTextField(
              controller: _otpController,
              label: 'OTP',
              icon: Icons.lock_outline,
              hintText: 'Enter OTP',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _canResend
                      ? 'Did not receive OTP?'
                      : 'Resend code in ${_formatTime(_secondsRemaining)}',
                  style: TextThemes.getBodySmallStyle(context),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _canResend ? _handleResendOtp : null,
                  child: Text(_canResend ? 'Resend OTP' : 'Resend OTP'),
                ),
              ],
            ),
            SizedBox(height: 24),
            Button(
              text: 'Verify OTP',
              onPressed: () {
                _handleVerifyOtp().then((result) {
                  if (result == "NEEDS_PROFILE") {
                    SnackBarWidget.show(context, 'Please complete your profile to continue');
                    Navigator.pushReplacementNamed(
                      context,
                      '/create-profile',
                      arguments: widget.phoneNumber,
                    );
                  } else if (result == "SUCCESS") {
                    SnackBarWidget.show(context, 'Login successful!');
                    Navigator.pushReplacementNamed(
                      context,
                      widget.endRoute,
                      arguments: widget.phoneNumber,
                    );
                  } else {
                    SnackBarWidget.show(context, result);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
