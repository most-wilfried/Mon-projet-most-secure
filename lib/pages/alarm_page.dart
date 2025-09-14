import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/rtdb_service.dart';
import 'camera_stream_page.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final RtdbService _rtdbService = RtdbService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _alarmeActive = false; // État local pour détecter le changement
  // Ajout d'un cache pour gérer les assets audio
  final AudioCache _audioCache = AudioCache();

  @override
  void initState() {
    super.initState();
    // On pré-charge le son dans le cache pour une lecture plus rapide et fiable.
    _audioCache.load('sounds/sirene.mp3');
  }

  @override
  void dispose() {
    // On s'assure que le son est arrêté avant de quitter la page.
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
    _audioCache.clearAll(); // Vider le cache à la destruction de la page
  }

  // Joue le son de la sirène
  Future<void> _playSirene() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Jouer en boucle
    // On joue le son depuis le cache, c'est plus fiable.
    // Le chemin est relatif au dossier 'assets'.
    await _audioPlayer.play(AssetSource('sounds/sirene.mp3'), volume: 1.0);
  }

  // Arrête le son de la sirène
  Future<void> _stopSirene() async {
    await _audioPlayer.stop();
  }

  // Fonction pour basculer l'état de l'alarme
  Future<void> _toggleAlarme(bool value) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // Vérification que l'utilisateur est bien connecté
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non connecté pour cette action.'),
          ),
        );
      }
      return;
    }
    try {
      // 1. Écriture dans Realtime Database (nouvelle logique)
      await _rtdbService.setAlarmeState(value, userId);

      // 2. Écriture dans Firestore (supprimé)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    }
  }

  // Fonction pour naviguer vers la page du flux vidéo
  void _navigateToStreamPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraStreamPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On écoute Realtime Database pour l'état de l'alarme, comme pour la porte
    return StreamBuilder<DatabaseEvent>(
      stream: _rtdbService.ref('alarme/etat').onValue,
      builder: (context, snapshot) {
        // Gestion des états du Stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}"));
        }

        // Lecture de l'état de l'alarme depuis Realtime Database.
        // Si la valeur est null (n'existe pas encore), on la considère comme 'false'
        // pour éviter le message "Aucune donnée".
        final alarmeActive = (snapshot.data?.snapshot.value as bool?) ?? false;

        // Déclencher ou arrêter la sirène en fonction du changement d'état
        if (alarmeActive && !_alarmeActive) {
          _playSirene();
          // On peut aussi logger l'événement ici
          _rtdbService.logAlarmeEvent({
            "timestamp": ServerValue.timestamp,
            "raison": "Alarme activée",
            "niveau": "Élevé",
          });
        } else if (!alarmeActive && _alarmeActive) {
          _stopSirene();
        }

        // Mettre à jour l'état local pour la prochaine comparaison
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _alarmeActive = alarmeActive;
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                "Événements Sécurisés",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A59D1),
                ),
              ),
              const SizedBox(height: 20),
              // Ce tableau affiche l'historique des événements liés à l'alarme (activation, etc.).
              // Il écoute la branche "historique_alarme" de la base de données en temps réel
              // et trie les événements pour afficher les plus récents en premier.
              // Tableau des événements avec scroll vertical et horizontal
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _rtdbService
                      .ref("historique_alarme")
                      .orderByChild("timestamp")
                      .limitToLast(50)
                      .onValue,
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!eventSnapshot.hasData ||
                        eventSnapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text("Aucun événement d'alarme."),
                      );
                    }
                    final dataMap = Map<String, dynamic>.from(
                      Map<String, dynamic>.from(
                        eventSnapshot.data!.snapshot.value as Map,
                      ),
                    );
                    final events = dataMap.values.toList()
                      ..sort(
                        (a, b) => (b['timestamp'] as int).compareTo(
                          a['timestamp'] as int,
                        ),
                      );

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
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Heure')),
                              DataColumn(label: Text('Raison')),
                              DataColumn(label: Text('Niveau')),
                            ],
                            rows: events.map((doc) {
                              final data = Map<String, dynamic>.from(
                                doc as Map,
                              );
                              final timestamp = data['timestamp'] as int?;
                              if (timestamp == null)
                                return const DataRow(cells: []);
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                timestamp,
                              );
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      "${date.day}/${date.month}/${date.year}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(data['raison'] as String? ?? 'N/A'),
                                  ),
                                  DataCell(
                                    Text(data['niveau'] as String? ?? 'N/A'),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Section alarme
              const Text("Alarme", textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: alarmeActive ? Colors.grey : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: alarmeActive,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: _toggleAlarme,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.volume_up_outlined,
                    color: alarmeActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToStreamPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D90D7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text("Visualiser l'environnement en temps réel"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
