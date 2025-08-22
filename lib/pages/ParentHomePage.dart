import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePage.dart';

class ParentHomePage extends StatefulWidget {
  final String? uid; // Ajout du paramètre uid

  const ParentHomePage({super.key, this.uid});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  bool porteOuverte = false;
  String? userId;
  String? userName;
  String? userPrenom;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _porteSub;

  @override
  void initState() {
    super.initState();
    _initFromSession();
    _persistLastRoute();
    _listenPorte();
  }

  // Initialiser depuis la session ; si vide, retomber sur FirebaseAuth + Firestore
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
        final doc = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(uid)
            .get();
        final data = doc.data();
        final nom = (data != null && data['nom'] is String) ? data['nom'] as String : null;
        final prenom = (data != null && data['prenom'] is String) ? data['prenom'] as String : null;
        final role = (data != null && data['role'] is String) ? data['role'] as String : null;
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

  // Persister la dernière route pour reprise d'état
  Future<void> _persistLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', '/parent_home');
    await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
  }

  // Écouter l'état de la porte en temps réel
  void _listenPorte() {
    _porteSub = FirebaseFirestore.instance
        .collection("etat_porte")
        .doc("porte1")
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        setState(() {
          porteOuverte = (doc.data()?['etat'] as bool?) ?? false;
        });
      }
    });
  }

  // Changer l'état de la porte
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
      await FirebaseFirestore.instance
          .collection("etat_porte")
          .doc("porte1")
          .set({"etat": value});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
      // N'insérer dans l'historique que lors de l'ouverture
      if (value == true) {
        await FirebaseFirestore.instance.collection("historique").add({
          "userId": userId,
          "nom": userName ?? "",
          "prenom": userPrenom ?? "",
          "action": "Ouverture",
          "timestamp": Timestamp.now(),
        });
      }
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D90D7),
        title: const Text(
          "Accueil",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/logo.png"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Color(0xFF3A59D1)),
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
          )
        ],
      ),
      body: Column(
        children: [
          // Titre Historique
          Container(
            color: const Color(0xFF7AC6D2),
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            child: const Center(
              child: Text(
                "Historique",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Tableau Historique
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("historique")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Table(
                    border: TableBorder.all(color: Colors.black26),
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FlexColumnWidth(),
                      2: FlexColumnWidth(),
                      3: FlexColumnWidth(),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFE1F5FE)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Nom", textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Prénom", textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Date", textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Heure", textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                      ...docs.map((doc) {
                        final ts = doc['timestamp'] as Timestamp;
                        final date = ts.toDate();
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(doc['nom'], textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(doc['prenom'], textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("${date.day}/${date.month}/${date.year}", textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("${date.hour}:${date.minute}", textAlign: TextAlign.center),
                            ),
                          ],
                        );
                      }),
                    ],
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
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
                  const Icon(Icons.door_front_door_outlined, color: Colors.grey),
                ],
              ),
            ],
          ),

          const Spacer(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF3A59D1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: "Alarme",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Utilisateurs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: "Données",
          ),
        ],
        onTap: (index) {
          // Navigation selon index
        },
      ),
    );
  }
}
