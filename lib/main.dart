import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/app_theme.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/pages/authentication/create_profile_page.dart';
import 'package:hosla/pages/authentication/forget_password_page.dart';
import 'package:hosla/pages/authentication/login_page.dart';
import 'package:hosla/pages/authentication/new_password.dart';
import 'package:hosla/pages/authentication/otp_verification_page.dart';
import 'package:hosla/pages/authentication/signup_page.dart';
import 'package:hosla/pages/authentication/update_password_page.dart';
import 'package:hosla/pages/homePage.dart';
import 'package:hosla/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {
        //'/': (context) => const _CheckUser(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return OtpVerificationPage(endRoute: args);
        },
        '/forget-password': (context) => const ForgetPasswordPage(),
        '/create-profile': (context) => const CreateProfilePage(),
        '/home': (context) => Homepage(),
        '/new-password': (context) => NewPasswordPage(),
        '/update-password': (context) => UpdatePasswordPage(),
      },
      home: LoginPage(),
    );
  }
}

class _CheckUser extends StatefulWidget {
  const _CheckUser();

  @override
  State<_CheckUser> createState() => __CheckUserState();
}

class __CheckUserState extends State<_CheckUser> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
