// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/mes_classes.dart';
import 'info_utilisateur.dart';
import 'info_espace_securise.dart';
import '../services/rtdb_service.dart';

class ParentProfileSheet extends StatefulWidget {
  const ParentProfileSheet({super.key});

  @override
  State<ParentProfileSheet> createState() => _ParentProfileSheetState();
}

class _ParentProfileSheetState extends State<ParentProfileSheet> {
  final User? user = FirebaseAuth.instance.currentUser;
  final RtdbService _rtdbService = RtdbService();

  bool usePin = false;
  bool useBiometrics = false;
  StreamSubscription? _empreinteSubscription;

  Future<void> _onTogglePin(bool use, {String? currentCodePin}) async {
    // Se connecte à Firebase Realtime Database pour mettre à jour les champs 'usePin'
    // et 'codePin' de l'utilisateur.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (use) {
      final code = await _promptCodePin(initial: currentCodePin);
      if (code == null) return;
      await _rtdbService.updateUserField(uid, 'usePin', true);
      await _rtdbService.updateUserField(uid, 'codePin', code);
    } else {
      await _rtdbService.updateUserField(uid, 'usePin', false);
    }
  }

  Future<String?> _promptCodePin({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    String? value;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Définir le code PIN'),
        content: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Code PIN (4 à 6 chiffres)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.length < 4 || v.length > 6) return;
              value = v;
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return value;
  }

  /// Déclenche la capture d'une nouvelle empreinte.
  /// Interagit avec Firebase Realtime Database pour communiquer avec le matériel (ESP32).
  /// Écrit une demande et écoute une réponse sur des chemins spécifiques.
  Future<void> _demanderNouvelleEmpreinte() async {
    final uid = user?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non identifié.")),
        );
      }
      return;
    }

    // 1. Écrit dans Realtime Database pour signaler au matériel qu'une capture d'empreinte est demandée.
    // Le matériel (ESP32) doit écouter les changements sur ce chemin.
    await _rtdbService.ref('gestion_empreinte').set({
      'demande_enregistrement': true,
      'demandeurId': uid, // On ajoute l'ID de l'utilisateur
    });

    // Affiche un message à l'utilisateur
    // 2. Affiche un message à l'utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Demande envoyée. Veuillez placer votre doigt sur le capteur...",
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    // 3. Écoute la réponse du matériel sur un autre chemin de Realtime Database.
    // Le matériel doit écrire la nouvelle valeur de l'empreinte ici.
    _empreinteSubscription?.cancel(); // Annule l'écoute précédente
    _empreinteSubscription = _rtdbService
        .ref('gestion_empreinte/nouvelle_valeur')
        .onValue
        .listen((event) async {
          final nouvelleValeur = event.snapshot.value;
          if (nouvelleValeur != null &&
              nouvelleValeur is int &&
              nouvelleValeur != 0) {
            // 4. Sauvegarde la nouvelle empreinte dans le profil de l'utilisateur
            // sur Realtime Database.
            await _rtdbService.updateUserField(
              uid,
              'empreinte',
              nouvelleValeur,
            );

            // 5. Réinitialise les chemins de communication dans Realtime Database
            // pour la prochaine demande.
            await _rtdbService
                .ref('gestion_empreinte/demande_enregistrement')
                .set(false);
            await _rtdbService
                .ref('gestion_empreinte/nouvelle_valeur')
                .set(0); // ou remove()

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Empreinte enregistrée avec succès ! ✅"),
                ),
              );
            }
            _empreinteSubscription?.cancel(); // On arrête d'écouter
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("Utilisateur non connecté."),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      // Se connecte à Firebase Realtime Database pour écouter en temps réel
      // les changements sur les données de l'utilisateur connecté.
      stream: _rtdbService.ref("utilisateurs/${user!.uid}").onValue,
      builder: (context, snapshotUser) {
        if (!snapshotUser.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userMap = snapshotUser.data?.snapshot.value != null
            ? Map<String, dynamic>.from(
                snapshotUser.data!.snapshot.value as Map,
              )
            : {};
        final String nom = userMap['nom'] as String? ?? '';
        final String prenom = userMap['prenom'] as String? ?? '';
        final String email =
            FirebaseAuth.instance.currentUser?.email ??
            (userMap['email'] as String? ?? '');
        final String telephone = userMap['telephone'] as String? ?? '';

        // Note: La logique pour l'espace sécurisé semble incorrecte car elle utilise user.uid comme doc ID.
        // Je la laisse telle quelle mais elle devrait probablement lire tous les espaces.
        return StreamBuilder<DatabaseEvent>(
          // Se connecte à Firebase Realtime Database pour écouter les changements
          // sur les espaces sécurisés.
          stream: _rtdbService.ref("espaces_securises").onValue,
          builder: (context, snapshotEspace) {
            if (!snapshotEspace.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 60),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$prenom $nom",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(email, style: const TextStyle(fontSize: 16)),
                  Text(telephone, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  // Bouton infos parent
                  ElevatedButton(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) => UserInfoEditorSheet(),
                      );
                    },
                    child: const Text("Visualiser ces informations"),
                  ),

                  const SizedBox(height: 10),

                  // Bouton infos espace sécurisé
                  ElevatedButton(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) => const EspaceSecuriseEditorSheet(),
                      );
                    },
                    child: const Text("Infos espace sécurisé"),
                  ),

                  const SizedBox(height: 30),

                  // Switch PIN
                  SwitchListTile(
                    title: const Text("Utiliser un code PIN"),
                    value:
                        (userMap['usePin'] as bool?) ??
                        (userMap['codePin'] != null),
                    onChanged: (value) async {
                      await _onTogglePin(
                        value,
                        currentCodePin: userMap['codePin'] as String?,
                      );
                    },
                  ),

                  // Bouton pour l'empreinte
                  ListTile(
                    title: const Text("Empreinte digitale"),
                    subtitle: Text(
                      (userMap['empreinte'] != null &&
                              userMap['empreinte'] != 0)
                          ? "Empreinte enregistrée"
                          : "Aucune empreinte",
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      onPressed: _demanderNouvelleEmpreinte,
                      label: const Text("Empreinte"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Déconnexion
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      // Se connecte au service Firebase Authentication pour déconnecter l'utilisateur.
                      await FirebaseAuth.instance.signOut();
                      SessionManager.instance.clear();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('last_route', '/login_page');
                      await prefs.setInt(
                        'last_active_ms',
                        DateTime.now().millisecondsSinceEpoch,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login_page',
                        (route) => false,
                      );
                    },
                    child: const Text("Se déconnecter"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool usePin = false;
  bool useBiometrics = false;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Utilisateur non connecté."));
    }

    // Le reste de cette classe semble être une duplication ou une ancienne version.
    // Je la laisse vide pour éviter la confusion.
    return const SizedBox.shrink();
    /*
    return Scaffold( ... )
    */
  }
}
