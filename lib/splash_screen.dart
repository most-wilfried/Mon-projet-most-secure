import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écran d'accueil animé qui détermine la route initiale selon l'état persistant:
/// - onboarding complété (onboarding_completed)
/// - dernière route et activité récente (last_route, last_active_ms)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State gérant l'animation du logo et la redirection différée.
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0;
  double _scale = 0.8;

  /// Initialise l'animation d'entrée et programme la redirection.
  /// Le Timer applique une fenêtre de reprise (1h) pour restaurer la dernière route récente,
  /// sinon redirige vers la page de connexion après l'onboarding.
  @override
  void initState() {
    super.initState();

    // Animation entrée logo
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1;
        _scale = 1;
      });
    });

    // Transition automatique après 1.2 seconde selon l'état persistant
    Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      final lastRoute = prefs.getString('last_route');
      final lastActiveMs = prefs.getInt('last_active_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      const resumeWindowMs = 60 * 60 * 1000; // 1 heure
      final isRecent = (nowMs - lastActiveMs) <= resumeWindowMs;

      if (!onboardingDone) {
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      if (isRecent && lastRoute != null) {
        Navigator.pushReplacementNamed(context, lastRoute);
      } else {
        Navigator.pushReplacementNamed(context, '/login_page');
      }
    });
  }

  /// Construit l'UI du splash: logo animé (opacity/scale) sur fond blanc.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1000),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            child: Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
            ),
          ),
        ),
      ),
    );
  }
}
