import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:test2/pages/add_system_page.dart';
import '../services/rtdb_service.dart';

class DonneesPage extends StatefulWidget {
  const DonneesPage({super.key});

  @override
  State<DonneesPage> createState() => _DonneesPageState();
}

class _DonneesPageState extends State<DonneesPage> {
  final RtdbService _rtdbService = RtdbService();

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
            "Informations sur le système",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A59D1),
            ),
          ),
          const SizedBox(height: 20),

          // Bouton Ajouter un système
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSystemPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Ajouter un système"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A59D1),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tableau connecté à Firebase
          // Ce tableau affiche la liste des systèmes de sécurité enregistrés.
          // Il est connecté à la branche "espaces_securises" de la base de données
          // et se met à jour automatiquement, en triant les systèmes par date d'installation
          // la plus récente.
          Expanded(
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder<DatabaseEvent>(
                stream: _rtdbService
                    .ref("espaces_securises")
                    .orderByChild("dateInstallation")
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("Aucun système ajouté"));
                  }

                  final dataMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final systemes =
                      dataMap.entries.map((e) {
                        return Map<String, dynamic>.from(e.value as Map)
                          ..['id'] = e.key;
                      }).toList()..sort(
                        (a, b) => (b['dateInstallation'] as int).compareTo(
                          a['dateInstallation'] as int,
                        ),
                      );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // scroll horizontal
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical, // scroll vertical
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blue.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text("Nom du système")),
                          DataColumn(label: Text("Position des capteurs")),
                          DataColumn(label: Text("Lieu")),
                          DataColumn(label: Text("Quartier")),
                          DataColumn(label: Text("Date d'installation")),
                        ],
                        rows: systemes.map((doc) {
                          final data = doc;
                          final timestamp = data['dateInstallation'] as int?;
                          // Formate la date pour un affichage lisible
                          final dateFormatted = timestamp != null
                              ? DateFormat('dd/MM/yyyy').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    timestamp,
                                  ),
                                )
                              : 'N/A';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(data["nomSysteme"] as String? ?? "N/A"),
                              ),
                              DataCell(
                                Text(
                                  data["positionCapteurs"] as String? ?? "N/A",
                                ),
                              ),
                              DataCell(Text(data["lieu"] as String? ?? "N/A")),
                              DataCell(
                                Text(data["quartier"] as String? ?? "N/A"),
                              ),
                              DataCell(Text(dateFormatted)),
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
