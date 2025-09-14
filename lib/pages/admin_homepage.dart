import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/rtdb_service.dart';
import 'admin_profile_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final RtdbService _rtdbService = RtdbService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets/images/logo.png", height: 50),
                  const Text(
                    "Espace Administrateur",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                          builder: (context) => const AdminProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Statistiques utilisateurs
              StreamBuilder<DatabaseEvent>(
                stream: _rtdbService.ref('utilisateurs').onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot.value == null) {
                    return Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround, // 'const' retiré ici
                      children: [
                        _buildStatCard("Parents", 0),
                        _buildStatCard("Enfants", 0),
                      ],
                    );
                  }
                  final users = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  int parentCount = 0;
                  int enfantCount = 0;
                  users.forEach((key, value) {
                    if (value['role'] == 'parent') parentCount++;
                    if (value['role'] == 'enfant') enfantCount++;
                  });
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard("Parents", parentCount),
                      _buildStatCard("Enfants", enfantCount),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Tableau des utilisateurs
              const Text(
                "Utilisateurs du système",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                // Ce tableau affiche une liste consolidée des utilisateurs du système.
                // Il combine les informations des utilisateurs (nom, prénom, date) avec les informations
                // de l'espace sécurisé (lieu, quartier) pour donner une vue d'ensemble.
                // Il utilise deux StreamBuilders imbriqués pour écouter les deux sources de données.
                child: StreamBuilder<DatabaseEvent>(
                  stream: _rtdbService.ref('utilisateurs').onValue,
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!userSnapshot.hasData ||
                        userSnapshot.data?.snapshot.value == null) {
                      return const Center(child: Text("Aucun utilisateur."));
                    }
                    final users = Map<String, dynamic>.from(
                      userSnapshot.data!.snapshot.value as Map,
                    );

                    return StreamBuilder<DatabaseEvent>(
                      stream: _rtdbService.ref('espaces_securises').onValue,
                      builder: (context, espaceSnapshot) {
                        if (espaceSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final espaceData =
                            espaceSnapshot.hasData &&
                                espaceSnapshot.data?.snapshot.value != null
                            ? Map<String, dynamic>.from(
                                (espaceSnapshot.data!.snapshot.value as Map)
                                    .values
                                    .first,
                              )
                            : {};
                        final lieu = espaceData['lieu'] ?? 'N/A';
                        final quartier = espaceData['quartier'] ?? 'N/A';

                        return Card(
                          elevation: 2,
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.blue.shade100,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Nom')),
                                  DataColumn(label: Text('Prénom')),
                                  DataColumn(label: Text('Date Création')),
                                  DataColumn(label: Text('Lieu')),
                                  DataColumn(label: Text('Quartier')),
                                ],
                                rows: users.values.map((data) {
                                  final userData = Map<String, dynamic>.from(
                                    data as Map,
                                  );
                                  final dateCreation =
                                      userData['dateCreation'] != null
                                      ? DateFormat('dd/MM/yy HH:mm').format(
                                          DateTime.parse(
                                            userData['dateCreation'],
                                          ),
                                        )
                                      : 'N/A';
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(userData['nom'] ?? '')),
                                      DataCell(Text(userData['prenom'] ?? '')),
                                      DataCell(Text(dateCreation)),
                                      DataCell(Text(lieu)),
                                      DataCell(Text(quartier)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A59D1),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0, // Simple cercle pour le design
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      title == "Parents" ? Colors.blue : Colors.red,
                    ),
                  ),
                  Center(
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
