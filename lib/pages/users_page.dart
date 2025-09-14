import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:test2/pages/aduser.dart';
import 'package:test2/pages/modifuser.dart';
import '../services/rtdb_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final RtdbService _rtdbService = RtdbService();

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    final newStatus = currentStatus ? "Désactivé" : "Activé";
    await _rtdbService.updateUserField(uid, 'statut', newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Titre
          Text(
            "Liste des utilisateurs",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A59D1),
            ),
          ),
          const SizedBox(height: 20),

          // Bouton d’ajout
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddUserPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Ajouter un utilisateur"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A59D1),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tableau avec Firebase
          // Ce tableau liste tous les utilisateurs enregistrés dans la base de données.
          // Il se met à jour en temps réel grâce au StreamBuilder qui écoute la branche "utilisateurs".
          // La dernière colonne "Options" utilise un `PopupMenuButton` pour proposer des actions
          // contextuelles comme "Modifier", "Activer" ou "Désactiver".
          Expanded(
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder<DatabaseEvent>(
                stream: _rtdbService.ref("utilisateurs").onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Erreur de chargement"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text("Aucun utilisateur trouvé"),
                    );
                  }

                  final usersMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final users = usersMap.entries.map((e) {
                    return Map<String, dynamic>.from(e.value as Map)
                      ..['id'] = e.key;
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical, // ✅ scroll vertical
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // ✅ scroll horizontal
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blue.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text("Nom")),
                          DataColumn(label: Text("Prénom")),
                          DataColumn(label: Text("Rôle")),
                          DataColumn(label: Text("Statut")),
                          DataColumn(label: Text("Options")),
                        ],
                        rows: users.map((doc) {
                          final data = doc;
                          final nom = data["nom"] ?? "";
                          final prenom = data["prenom"] ?? "";
                          final role = data["role"] ?? "";
                          final statut =
                              data["statut"] as String? ?? "Désactivé";

                          return DataRow(
                            cells: [
                              DataCell(Text(nom)),
                              DataCell(Text(prenom)),
                              DataCell(Text(role)),
                              DataCell(
                                Text(
                                  statut,
                                  style: TextStyle(
                                    color: statut == "Activé"
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == "modifier") {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ModifUserPage(
                                            userId: data['id'],
                                            userData: data,
                                          ),
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Modifier $prenom ($nom)",
                                          ),
                                        ),
                                      );
                                    } else if (value == "toggle_status") {
                                      await _toggleUserStatus(
                                        data['id'],
                                        statut == "Activé",
                                      );
                                    }
                                  },
                                  itemBuilder: (context) {
                                    // Construit la liste des options dynamiquement
                                    // en fonction du statut de l'utilisateur.
                                    return [
                                      const PopupMenuItem(
                                        value: "modifier",
                                        child: Text("Modifier"),
                                      ),
                                      if (statut == "Activé")
                                        const PopupMenuItem(
                                          value: "toggle_status",
                                          child: Text("Désactiver"),
                                        )
                                      else
                                        const PopupMenuItem(
                                          value: "toggle_status",
                                          child: Text("Activer"),
                                        ),
                                    ];
                                  },
                                  child: ElevatedButton(
                                    onPressed: null,
                                    child: const Text("Options"),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
