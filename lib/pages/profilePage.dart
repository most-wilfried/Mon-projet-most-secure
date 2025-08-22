import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_manager.dart';

class ParentProfileSheet extends StatefulWidget {
  const ParentProfileSheet({super.key});

  @override
  State<ParentProfileSheet> createState() => _ParentProfileSheetState();
}

class _ParentProfileSheetState extends State<ParentProfileSheet> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool usePin = false;
  bool useBiometrics = false;

  Future<void> _onTogglePin(bool use, {String? currentCodePin}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (use) {
      final code = await _promptCodePin(initial: currentCodePin);
      if (code == null) return;
      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).update({
        'usePin': true,
        'codePin': code,
      });
    } else {
      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).update({
        'usePin': false,
      });
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Code PIN (4 à 6 chiffres)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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

  Future<void> _onToggleBiometrics(bool use) 
async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).update({
      'useBiometrics': use,
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("utilisateurs")
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshotUser) {
        if (!snapshotUser.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userSnap = snapshotUser.data!;
        final userMap = (userSnap.data() as Map<String, dynamic>?) ?? {};
        final String nom = userMap['nom'] as String? ?? '';
        final String prenom = userMap['prenom'] as String? ?? '';
        final String email = FirebaseAuth.instance.currentUser?.email ?? (userMap['email'] as String? ?? '');
        final String telephone = userMap['telephone'] as String? ?? '';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("espaces_securises")
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshotEspace) {
            if (!snapshotEspace.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final espaceSnap = snapshotEspace.data!;
            final espaceMap = (espaceSnap.data() as Map<String, dynamic>?) ?? {};
            final String adresse = espaceMap['adresse'] as String? ?? 'Non définie';
            final String etat = espaceMap['etat'] as String? ?? 'Inconnu';
            final int nbCapteurs = (espaceMap['nb_capteurs'] as num?)?.toInt() ?? 0;

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
                  Text("$prenom $nom",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => const UserInfoEditorSheet(),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    value: (userMap['usePin'] as bool?) ?? (userMap['codePin'] != null),
                    onChanged: (value) async {
                      await _onTogglePin(value, currentCodePin: userMap['codePin'] as String?);
                    },
                  ),

                  // Switch biométrie
                  SwitchListTile(
                    title: const Text("Utiliser la biométrie"),
                    value: (userMap['useBiometrics'] as bool?) ?? false,
                    onChanged: (value) async {
                      await _onToggleBiometrics(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Déconnexion
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      SessionManager.instance.clear();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('last_route', '/login_page');
                      await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil('/login_page', (route) => false);
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

// Feuille d'édition des infos utilisateur
class UserInfoEditorSheet extends StatelessWidget {
  const UserInfoEditorSheet({super.key});

  static const Color primaryBlue = Color(0xFF3A59D1);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Utilisateur non connecté'),
      );
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};
            final nom = data['nom'] as String? ?? '';
            final prenom = data['prenom'] as String? ?? '';
            final email = user.email ?? (data['email'] as String? ?? '');
            final telephone = data['telephone'] as String? ?? '';
            final adresse = data['adresse'] as String? ?? '';
            final role = data['role'] as String? ?? '';
            final dateCreation = data['dateCreation'] as String?;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Center(
                  child: Text(
                    'Informations du compte',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _editableTile(context, 'Nom', nom, (v) => _updateField('nom', v)),
                _editableTile(context, 'Prénom', prenom, (v) => _updateField('prenom', v)),
                _editableTile(context, 'Téléphone', telephone, (v) => _updateField('telephone', v)),
                _editableTile(context, 'Adresse', adresse, (v) => _updateField('adresse', v)),
                ListTile(
                  title: const Text('Rôle'),
                  subtitle: Text(role),
                ),
                _editableTile(context, 'Email', email, (v) => _updateEmail(user, v)),
                _editableTile(context, 'Mot de passe', '******', (v) => _updatePassword(user, v), isPassword: true),
                ListTile(
                  title: const Text('Date de création'),
                  subtitle: Text(dateCreation ?? ''),
                ),
                const SizedBox(height: 8),
              ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _editableTile(BuildContext context, String label, String value, Future<void> Function(String) onSave, {bool isPassword = false}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: TextButton(
        onPressed: () async {
          final newValue = await _promptValue(context, label, isPassword: isPassword);
          if (newValue == null) return;
          try {
            await onSave(newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modifié.')));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
        child: const Text('Modifier', style: TextStyle(color: primaryBlue)),
      ),
    );
  }

  Future<String?> _promptValue(BuildContext context, String label, {bool isPassword = false}) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $label'),
        content: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl1,
                  obscureText: isPassword,
                  decoration: InputDecoration(labelText: label),
                ),
                if (isPassword)
                  TextField(
                    controller: ctrl2,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final v1 = ctrl1.text.trim();
              if (isPassword) {
                final v2 = ctrl2.text.trim();
                if (v1.length < 6 || v1 != v2) return;
              }
              result = v1;
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _updateField(String field, String value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).update({field: value});
  }

  Future<void> _updateEmail(User user, String newEmail) async {
    await user.updateEmail(newEmail);
    final uid = user.uid;
    await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).update({'email': newEmail});
  }

  Future<void> _updatePassword(User user, String newPassword) async {
    await user.updatePassword(newPassword);
  }
}

// Feuille d'édition de l'espace sécurisé
class EspaceSecuriseEditorSheet extends StatelessWidget {
  const EspaceSecuriseEditorSheet({super.key});

  static const Color primaryBlue = Color(0xFF3A59D1);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Utilisateur non connecté'),
      );
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('espaces_securises')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};
            final adresse = data['adresse'] as String? ?? '';
            final etat = data['etat'] as String? ?? '';
            final nbCapteurs = (data['nb_capteurs'] as num?)?.toString() ?? '0';

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                const Center(
                  child: Text(
                    'Espace sécurisé',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _editableTile(context, 'Adresse', adresse, (v) => _updateField(user.uid, 'adresse', v)),
                _editableTile(context, 'État', etat, (v) => _updateField(user.uid, 'etat', v)),
                _editableTile(context, 'Nombre de capteurs', nbCapteurs, (v) => _updateField(user.uid, 'nb_capteurs', int.tryParse(v) ?? 0)),
                const SizedBox(height: 8),
              ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _editableTile(BuildContext context, String label, String value, Future<void> Function(String) onSave) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: TextButton(
        onPressed: () async {
          final newValue = await _promptValue(context, label);
          if (newValue == null) return;
          try {
            await onSave(newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modifié.')));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
        child: const Text('Modifier', style: TextStyle(color: primaryBlue)),
      ),
    );
  }

  Future<String?> _promptValue(BuildContext context, String label) async {
    final ctrl = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $label'),
        content: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(labelText: label),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              result = ctrl.text.trim();
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _updateField(String uid, String field, Object value) async {
    await FirebaseFirestore.instance.collection('espaces_securises').doc(uid).update({field: value});
  }
}

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  _ParentProfilePageState createState() => _ParentProfilePageState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Parent"),
        backgroundColor: const Color(0xFF3D90D7),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("utilisateurs")
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshotUser) {
          if (!snapshotUser.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userSnap = snapshotUser.data!;
          final userMap = (userSnap.data() as Map<String, dynamic>?) ?? {};
          final String nom = userMap['nom'] as String? ?? '';
          final String prenom = userMap['prenom'] as String? ?? '';
          final String email = FirebaseAuth.instance.currentUser?.email ?? (userMap['email'] as String? ?? '');
          final String telephone = userMap['telephone'] as String? ?? '';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("espaces_securises")
                .doc(user!.uid) // si tu utilises le même UID
                .snapshots(),
            builder: (context, snapshotEspace) {
              if (!snapshotEspace.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final espaceSnap = snapshotEspace.data!;
              final espaceMap = (espaceSnap.data() as Map<String, dynamic>?) ?? {};
              final String adresse = espaceMap['adresse'] as String? ?? 'Non définie';
              final String etat = espaceMap['etat'] as String? ?? 'Inconnu';
              final int nbCapteurs = (espaceMap['nb_capteurs'] as num?)?.toInt() ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 60),
                    ),
                    const SizedBox(height: 20),
                    Text("$prenom $nom",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(email, style: const TextStyle(fontSize: 16)),
                    Text(telephone, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),

                    // Bouton infos parent
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Informations Parent"),
                            content: Text(
                                "Nom: $nom\nPrénom: $prenom\nEmail: $email\nTéléphone: $telephone"),
                          ),
                        );
                      },
                      child: const Text("Visualiser les infos du parent"),
                    ),

                    const SizedBox(height: 10),

                    // Bouton infos espace sécurisé
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Espace Sécurisé"),
                            content: Text(
                                "Adresse: $adresse\nÉtat: $etat\nNombre de capteurs: $nbCapteurs"),
                          ),
                        );
                      },
                      child: const Text("Infos espace sécurisé"),
                    ),

                    const SizedBox(height: 30),

                    // Switch PIN
                    SwitchListTile(
                      title: const Text("Utiliser un code PIN"),
                      value: usePin,
                      onChanged: (value) {
                        setState(() => usePin = value);
                      },
                    ),

                    // Switch biométrie
                    SwitchListTile(
                      title: const Text("Utiliser la biométrie"),
                      value: useBiometrics,
                      onChanged: (value) {
                        setState(() => useBiometrics = value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Déconnexion
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        SessionManager.instance.clear();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('last_route', '/login_page');
                        await prefs.setInt('last_active_ms', DateTime.now().millisecondsSinceEpoch);
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil('/login_page', (route) => false);
                      },
                      child: const Text("Se déconnecter"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
