import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../utils/mes_classes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePage.dart';
import '../services/rtdb_service.dart';
import 'alarm_page.dart';
import 'users_page.dart';
import 'donnees_page.dart';
import 'botpress_chat_page.dart'; // Importer la page du chatbot

/// Page d'accueil principale pour les utilisateurs avec le rôle "parent".
/// Affiche un tableau de bord avec l'historique, le contrôle de la porte et la navigation vers d'autres sections.
class ParentHomePage extends StatefulWidget {
  final String? uid; // Ajout du paramètre uid

  const ParentHomePage({super.key, this.uid});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

/// État associé à [ParentHomePage], gère la navigation, l'état de la porte et les données utilisateur.
class _ParentHomePageState extends State<ParentHomePage> {
  bool porteOuverte = false;
  String? userId;
  String? userName;
  String? userPrenom;
  StreamSubscription<DatabaseEvent>? _porteSub;
  int _currentIndex = 0; // 0 = Accueil, 1 = Alarme, etc.

  final RtdbService _rtdbService = RtdbService();

  @override
  void initState() {
    super.initState();
    _initFromSession();
    _persistLastRoute();
    _listenPorte();
  }

  Future<void> _initFromSession() async {
    final sm = SessionManager.instance;
    if (sm.userId != null) {
      setState(() {
        userId = widget.uid ?? sm.userId;
        userName = sm.nom;
        userPrenom = sm.prenom;
      });
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = widget.uid ?? currentUser.uid;
      try {
        final snapshot = await _rtdbService.getUserData(uid);
        final data = snapshot.exists
            ? Map<String, dynamic>.from(snapshot.value as Map)
            : null;
        final nom = (data != null && data['nom'] is String)
            ? data['nom'] as String
            : null;
        final prenom = (data != null && data['prenom'] is String)
            ? data['prenom'] as String
            : null;
        final role = (data != null && data['role'] is String)
            ? data['role'] as String
            : null;
        setState(() {
          userId = uid;
          userName = nom ?? '';
          userPrenom = prenom ?? '';
        });
        await SessionManager.instance.setSession(
          uid: uid,
          email: currentUser.email,
          role: role,
          nom: nom,
          prenom: prenom,
        );
      } catch (_) {
        setState(() {
          userId = uid;
        });
      }
    }
  }

  Future<void> _persistLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', '/parent_home');
    await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
  }

  void _listenPorte() {
    // Écoute des changements depuis Realtime Database
    _porteSub = _rtdbService.ref('porte/etat').onValue.listen((event) {
      final bool isPorteOuverte = (event.snapshot.value as bool?) ?? false;
      if (mounted && isPorteOuverte != porteOuverte) {
        setState(() {
          porteOuverte = isPorteOuverte;
        });

        // Si le changement vient de l'extérieur (pas de l'app), on met à jour Firestore
        // Pour éviter une boucle, on ne le fait que si l'état a réellement changé.
        // Cette partie n'est plus nécessaire car tout est sur RTDB.
        // _rtdbService.ref('porte/etat').set(isPorteOuverte);

        // Si la porte s'ouvre, on enregistre l'historique.
        if (isPorteOuverte) {
          _rtdbService.ref('porte/last_user_id').get().then((snapshot) {
            final openerId = snapshot.value as String?;
            _logAction("Ouverture", openerId);
          });
        }
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
      // 1. Écriture dans Realtime Database
      await _rtdbService.setPorteState(value, userId!);

      // 2. Écriture dans Firestore (supprimé)
      // ...

      // 3. Mise à jour du timestamp d'activité
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_active_ms',
        DateTime.now().millisecondsSinceEpoch,
      );

      // 4. Enregistrement de l'historique si la porte est ouverte
      if (value == true) {
        await _logAction("Ouverture", userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    }
  }

  Future<void> _logAction(String action, String? actorId) async {
    try {
      // Pour l'historique, on peut se baser sur l'ID pour récupérer les infos à jour
      // ou utiliser celles de la session si on les juge fiables.
      // Ici, on utilise celles de la session pour la simplicité.
      await _rtdbService.logAction({
        "userId": actorId ?? "inconnu",
        "nom":
            userName ?? "", // On pourrait aller chercher le nom via l'actorId
        "prenom": userPrenom ?? "", // Idem
        "action": action,
        "timestamp": ServerValue.timestamp,
      });
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

  // Méthode pour construire le body selon l'onglet sélectionné
  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const AlarmPage();
      case 2:
        return const UsersPage();
      case 3: // Onglet Données
        return const DonneesPage();
      default:
        return _buildAccueil();
    }
  }

  // Body actuel de l'accueil
  Widget _buildAccueil() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Titre Historique
          Text(
            "Historique",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A59D1),
            ),
          ),
          const SizedBox(height: 20),

          // Tableau Historique
          // Ce tableau affiche l'historique des actions (ex: ouverture de porte).
          // Il est connecté en temps réel à la branche "historique" de la base de données
          // et se met à jour automatiquement.
          Expanded(
            flex: 2,
            child: StreamBuilder<DatabaseEvent>(
              stream: _rtdbService
                  .ref("historique")
                  .orderByChild("timestamp")
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text("Aucun historique."));
                }
                final dataMap = Map<String, dynamic>.from(
                  Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  ),
                );
                final docs = dataMap.values.toList()
                  ..sort(
                    (a, b) => (b['timestamp'] as int).compareTo(
                      a['timestamp'] as int,
                    ),
                  );

                return Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    // Scroll vertical
                    child: SingleChildScrollView(
                      // Scroll horizontal
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blue.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text("Nom")),
                          DataColumn(label: Text("Prénom")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Heure")),
                        ],
                        rows: docs.map((doc) {
                          final data = Map<String, dynamic>.from(doc as Map);
                          final timestamp = data['timestamp'] as int?;
                          if (timestamp == null)
                            return const DataRow(cells: []);
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            timestamp,
                          );
                          return DataRow(
                            cells: [
                              DataCell(Text(data['nom'] as String? ?? "")),
                              DataCell(Text(data['prenom'] as String? ?? "")),
                              DataCell(
                                Text("${date.day}/${date.month}/${date.year}"),
                              ),
                              DataCell(
                                Text(
                                  "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                ),
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

          // Bouton ouverture porte
          Column(
            children: [
              Text(
                porteOuverte
                    ? "Porte ouverte — basculez pour fermer"
                    : "Porte fermée — basculez pour ouvrir",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.door_front_door, color: Colors.grey),
                  Switch(
                    value: porteOuverte,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (val) => _togglePorte(val),
                  ),
                  const Icon(
                    Icons.door_front_door_outlined,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Accueil",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/logo.png"),
        ),
        actions: [
          // Bouton pour l'assistant virtuel (chatbot)
          // Bouton qui ouvre la page de l'assistant virtuel (chatbot).
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              size: 30,
              color: Color(0xFF3D90D7),
            ),
            tooltip: "Besoin d'aide ?",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BotpressChatPage(),
                ),
              );
            },
          ),
          // Ce bouton, lorsqu'il est pressé, déclenche la fonction `showModalBottomSheet`.
          // Cette fonction est intégrée à Flutter et permet d'afficher un widget (ici, `ParentProfileSheet`)
          // depuis le bas de l'écran, créant cet effet de "déroulement".
          // `isScrollControlled: true` permet à la feuille de prendre plus de la moitié de l'écran si nécessaire,
          // et `shape` lui donne des coins arrondis pour un meilleur design.
          // Bouton qui ouvre une feuille modale (bottom sheet) avec le profil de l'utilisateur.
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 30,
              color: Color(0xFF3A59D1),
            ),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => const ParentProfileSheet(),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF3A59D1),
        unselectedItemColor: Colors.grey,
        // Chaque item est un bouton de navigation.
        items: const [
          // Bouton pour afficher la page "Accueil".
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          // Bouton pour afficher la page "Alarme".
          BottomNavigationBarItem(icon: Icon(Icons.security), label: "Alarme"),
          // Bouton pour afficher la page "Utilisateurs".
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Utilisateurs",
          ),
          // Bouton pour afficher la page "Données".
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: "Données",
          ),
        ],
        // Gère le changement d'onglet.
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
