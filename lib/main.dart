import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'pages/login_page.dart';
import 'pages/inscription.dart';
import 'pages/ParentHomePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
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
      },
    );
  }
}
