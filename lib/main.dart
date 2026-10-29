import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_service.dart';
import 'api_auth_service.dart';
import 'firebase_auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiBaseUrl = const String.fromEnvironment('API_BASE_URL');
  late final AuthService auth;

  if (apiBaseUrl.isNotEmpty) {
    auth = await RestAuthService.create(apiBaseUrl);
  } else {
    try {
      await Firebase.initializeApp();
      auth = await FirebaseAuthService.create();
    } catch (_) {
      auth = await LocalAuthService.create();
    }
  }
  runApp(LigtasLinkApp(auth: auth));
}

class LigtasLinkApp extends StatelessWidget {
  final AuthService auth;

  const LigtasLinkApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    const emergencyRed = Color(0xFFC62828);
    const trustBlue = Color(0xFF0D47A1);

    return MaterialApp(
      title: 'LigtasLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: emergencyRed,
          primary: emergencyRed,
          secondary: trustBlue,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Color(0xFF18202B),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD0D4DA)),
          ),
        ),
      ),
      home: auth.currentUser == null
          ? LoginPage(auth: auth)
          : HomePage(auth: auth, user: auth.currentUser!),
    );
  }
}
