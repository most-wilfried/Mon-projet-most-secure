import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rtdb_service.dart';
import 'enfant_profile_page.dart';

class EnfantHomePage extends StatefulWidget {
  const EnfantHomePage({super.key});

  @override
  State<EnfantHomePage> createState() => _EnfantHomePageState();
}

class _EnfantHomePageState extends State<EnfantHomePage> {
  bool porteOuverte = false;
  String? userId;
  String? userName;
  String? userPrenom;
  StreamSubscription<DatabaseEvent>? _porteSub;

  final RtdbService _rtdbService = RtdbService();

  @override
  void initState() {
    super.initState();
    _initUser();
    _persistLastRoute();
    _listenPorte();
  }

  Future<void> _initUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final snapshot = await _rtdbService.getUserData(uid);
      final data = snapshot.exists
          ? Map<String, dynamic>.from(snapshot.value as Map)
          : null;
      final nom = (data != null && data['nom'] is String)
          ? data['nom'] as String
          : '';
      final prenom = (data != null && data['prenom'] is String)
          ? data['prenom'] as String
          : '';

      if (mounted) {
        setState(() {
          userId = uid;
          userName = nom;
          userPrenom = prenom;
        });
      }
    }
  }

  Future<void> _persistLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', '/enfant_home');
    await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
  }

  void _listenPorte() {
    _porteSub = _rtdbService.ref('porte/etat').onValue.listen((event) {
      final bool isPorteOuverte = (event.snapshot.value as bool?) ?? false;
      if (mounted && isPorteOuverte != porteOuverte) {
        setState(() {
          porteOuverte = isPorteOuverte;
        });
      }
    });
  }

  Future<void> _togglePorte(bool value) async {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non authentifié.")),
        );
      }
      return;
    }

    try {
      await _rtdbService.setPorteState(value, userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_active_ms',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _porteSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header avec logo et profil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets/images/logo.png", height: 50),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      size: 40,
                      color: Color(0xFF3A59D1),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnfantProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                "Bienvenue !",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Bouton central pour la porte
              Text(
                porteOuverte ? "La porte est ouverte" : "La porte est fermée",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                  value: porteOuverte,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (val) => _togglePorte(val),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
