import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rtdb_service.dart';
import '../utils/mes_classes.dart';

class EnfantProfilePage extends StatefulWidget {
  const EnfantProfilePage({super.key});

  @override
  State<EnfantProfilePage> createState() => _EnfantProfilePageState();
}

class _EnfantProfilePageState extends State<EnfantProfilePage> {
  final RtdbService _rtdbService = RtdbService();
  StreamSubscription? _empreinteSubscription;

  @override
  void dispose() {
    _empreinteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil")),
        body: const Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: const Color(0xFF3D90D7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Section Informations Utilisateur ---
            StreamBuilder<DatabaseEvent>(
              stream: _rtdbService.ref("utilisateurs/${user.uid}").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final data = snapshot.data?.snapshot.value != null
                    ? Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map,
                      )
                    : {};
                return _buildInfoCard(
                  title: "Mes Informations",
                  icon: Icons.person,
                  data: {
                    "Nom": data['nom'] ?? 'N/A',
                    "Prénom": data['prenom'] ?? 'N/A',
                    "Email": user.email ?? 'N/A',
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // --- Bouton pour l'empreinte ---
            StreamBuilder<DatabaseEvent>(
              stream: _rtdbService
                  .ref("utilisateurs/${user.uid}/empreinte")
                  .onValue,
              builder: (context, snapshot) {
                final hasEmpreinte =
                    snapshot.hasData &&
                    snapshot.data?.snapshot.value != null &&
                    snapshot.data?.snapshot.value != 0;
                return ListTile(
                  title: const Text("Empreinte digitale"),
                  subtitle: Text(
                    hasEmpreinte ? "Empreinte enregistrée" : "Aucune empreinte",
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    onPressed: () => _demanderNouvelleEmpreinte(user.uid),
                    label: const Text("Empreinte"),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- Section Informations Espace Sécurisé ---
            StreamBuilder<DatabaseEvent>(
              stream: _rtdbService.ref("espaces_securises").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final data = snapshot.data?.snapshot.value != null
                    ? Map<String, dynamic>.from(
                        (snapshot.data!.snapshot.value as Map).values.first,
                      )
                    : {};
                return _buildInfoCard(
                  title: "Espace Sécurisé",
                  icon: Icons.security,
                  data: {
                    "Nom de l'espace": data['nom'] ?? 'N/A',
                    "Adresse": data['adresse'] ?? 'N/A',
                  },
                );
              },
            ),
            const SizedBox(height: 40),

            // --- Bouton de déconnexion ---
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Se déconnecter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                SessionManager.instance.clear();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('last_route', '/login_page');
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login_page', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demanderNouvelleEmpreinte(String uid) async {
    // 1. On met à jour le noeud 'gestion_empreinte' dans RTDB
    await _rtdbService.ref('gestion_empreinte').set({
      'demande_enregistrement': true,
      'demandeurId': uid,
    });

    // 2. Affiche un message à l'utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Demande envoyée. Veuillez placer votre doigt sur le capteur...",
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    // 3. On écoute la réponse du matériel
    _empreinteSubscription?.cancel();
    _empreinteSubscription = _rtdbService
        .ref('gestion_empreinte/nouvelle_valeur')
        .onValue
        .listen((event) async {
          final nouvelleValeur = event.snapshot.value;
          if (nouvelleValeur != null &&
              nouvelleValeur is int &&
              nouvelleValeur != 0) {
            // 4. On sauvegarde la nouvelle empreinte pour l'utilisateur
            await _rtdbService.updateUserField(
              uid,
              'empreinte',
              nouvelleValeur,
            );

            // 5. On réinitialise les valeurs dans 'gestion_empreinte'
            await _rtdbService
                .ref('gestion_empreinte/demande_enregistrement')
                .set(false);
            await _rtdbService.ref('gestion_empreinte/nouvelle_valeur').set(0);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Empreinte enregistrée avec succès ! ✅"),
                ),
              );
            }
            _empreinteSubscription?.cancel();
          }
        });
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Map<String, String> data,
  }) {
    return Card(
      elevation: 4,
      child: ListTileTheme(
        textColor: Colors.black87,
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF3A59D1)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          children: data.entries
              .map(
                (entry) => ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(entry.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
