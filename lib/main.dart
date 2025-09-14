import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'pages/login_page.dart';
import 'pages/inscription.dart';
import 'pages/ParentHomePage.dart';
import 'pages/enfant_homepage.dart'; // Importer la page enfant
import 'pages/admin_homepage.dart'; // Importer la page admin
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Most Secure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Syne',
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login_page': (context) => const LoginPage(),
        '/inscription': (context) => const RegisterPage(),
        '/parent_home': (context) => const ParentHomePage(),
        '/enfant_home': (context) => const EnfantHomePage(), // Ajouter la route enfant
        '/admin_home': (context) => const AdminHomePage(), // Ajouter la route admin
      },
    );
  }
}