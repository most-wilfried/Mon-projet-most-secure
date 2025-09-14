import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rtdb_service.dart';
import '../utils/mes_classes.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final RtdbService rtdbService = RtdbService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil")),
        body: const Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil Administrateur"),
        backgroundColor: const Color(0xFF3D90D7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Section Informations Utilisateur ---
            StreamBuilder<DatabaseEvent>(
              stream: rtdbService.ref("utilisateurs/${user.uid}").onValue,
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
