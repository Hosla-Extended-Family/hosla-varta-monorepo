import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/app_theme.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/pages/authentication/create_profile_page.dart';
import 'package:hosla/pages/authentication/forget_password_page.dart';
import 'package:hosla/pages/authentication/login_page.dart';
import 'package:hosla/pages/authentication/reset_password.dart';
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
          final args = ModalRoute.of(context)!.settings.arguments;
          String phoneNumber = '';
          String endRoute = '/home';

          if (args is Map) {
            phoneNumber = args['phoneNumber']?.toString() ?? '';
            endRoute = args['endRoute']?.toString() ?? '/home';
          } else if (args is String) {
            // Backward compatibility: treat as phone number
            phoneNumber = args;
          }

          return OtpVerificationPage(
            endRoute: endRoute,
            phoneNumber: phoneNumber,
          );
        },
        '/forget-password': (context) => const ForgetPasswordPage(),
        '/create-profile': (context) => const CreateProfilePage(),
        '/home': (context) => Homepage(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return ResetPassword(phoneNumber: args);
        },
        '/update-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return UpdatePasswordPage(phoneNumber: args);
        },
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
