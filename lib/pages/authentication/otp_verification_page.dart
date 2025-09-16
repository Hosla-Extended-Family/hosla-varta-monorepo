import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/widgets/button.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

class OtpVerificationPage extends StatefulWidget {
  OtpVerificationPage({super.key, required this.endRoute});

  final String endRoute;

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
        title: Text('OTP Verification', style: TextThemes.getTitleStyle(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text(
              'Enter the OTP sent to your phone:',
              style: TextThemes.getBodyMediumStyle(context),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                labelText: 'Enter OTP',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _canResend
                      ? "Didn't receive the code?"
                      : 'You can resend in ${_formatTime(_secondsRemaining)}',
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
                // TODO: Handle OTP verification logic here
                Navigator.pushReplacementNamed(context, widget.endRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
