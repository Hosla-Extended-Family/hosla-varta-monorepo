import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/app_theme.dart';
import 'package:hosla/core/navigation/route_observer.dart';
import 'package:hosla/pages/authentication/create_profile_page.dart';
import 'package:hosla/pages/authentication/login_page.dart';
import 'package:hosla/pages/authentication/otp_verification_page.dart';
import 'package:hosla/pages/authentication/signup_page.dart';
import 'package:hosla/pages/home_page.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hosla/services/firebase_messaging_service.dart';
import 'package:hosla/services/chat_socket_service.dart';
import 'package:hosla/widgets/in_app_notification_host.dart';
import 'firebase_options.dart'; // This file will be generated when you run flutterfire configure
void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve the native splash screen until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseMessagingService().init();
  } catch (e) {
    print('Firebase init failed: $e');
  }

  // Eagerly refresh tokens if access is near expiry
  await AuthService.instance.refreshIfExpiringSoon();
  
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  // Connect realtime chat when the user has a session
  if (isLoggedIn) {
    ChatSocketService.instance.connect();
  }

  // Remove splash screen now that initialization is done
  FlutterNativeSplash.remove();
  runApp(ProviderScope(child: MainApp(isLoggedIn: isLoggedIn)));
}

class MainApp extends ConsumerWidget {
  final bool isLoggedIn;
  const MainApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) =>
          InAppNotificationHost(child: child ?? const SizedBox.shrink()),
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
        /* '/forget-password': (context) => const ForgetPasswordPage(), */
        '/create-profile': (context) => const CreateProfilePage(),
        '/home': (context) => Homepage(),
        /* '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return ResetPassword(phoneNumber: args);
        },
        '/update-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return UpdatePasswordPage(phoneNumber: args);
        }, */
      },
      home: isLoggedIn ? Homepage() : const LoginPage(),
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
