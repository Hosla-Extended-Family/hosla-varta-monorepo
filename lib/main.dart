import 'package:flutter/material.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/pages/authentication/create_profile_page.dart';
import 'package:hosla/pages/authentication/login_page.dart';
import 'package:hosla/pages/authentication/otp_verification_page.dart';
import 'package:hosla/pages/authentication/signup_page.dart';
import 'package:hosla/pages/homePage.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      routes: {
        //'/': (context) => const _CheckUser(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/otp-verification': (context) => const OtpVerificationPage(),
        '/create-profile': (context) => const CreateProfilePage(),
        '/home': (context) => const Homepage(),
      },
      home: const Homepage(),
    );
  }
}

class _CheckUser extends StatefulWidget {
  const _CheckUser({super.key});

  @override
  State<_CheckUser> createState() => __CheckUserState();
}

class __CheckUserState extends State<_CheckUser> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

//sdbvisbviusbviusfbviusb