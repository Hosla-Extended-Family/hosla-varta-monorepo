import 'package:flutter/material.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/pages/authentication/create_profile_page.dart';
import 'package:hosla/pages/authentication/forget_password_page.dart';
import 'package:hosla/pages/authentication/login_page.dart';
import 'package:hosla/pages/authentication/new_password.dart';
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
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return OtpVerificationPage(endRoute: args);
        },

        '/create-profile': (context) => const CreateProfilePage(),
        '/home': (context) =>  Homepage(),
        '/new-password': (context) => NewPasswordPage(),
      },
      home: Homepage(),
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

















// muskan mast thi




//sdbvisbviusbviusfbviusb
