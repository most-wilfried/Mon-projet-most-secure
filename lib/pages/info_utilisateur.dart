import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/rtdb_service.dart';

/// Feuille (BottomSheet) d'édition et de visualisation des informations
/// de l'utilisateur connecté.
///
/// Affiche les champs issus de la collection `utilisateurs/{uid}` et permet
/// d'éditer certains champs (nom, prénom, téléphone, adresse, email, mot de passe).
/// Chaque action est commentée pour faciliter la maintenance.
class UserInfoEditorSheet extends StatelessWidget {
   UserInfoEditorSheet({super.key});

  // Couleur primaire utilisée par les boutons "Modifier".
  static const Color primaryBlue = Color(0xFF3A59D1);
  final RtdbService _rtdbService = RtdbService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Si l'utilisateur n'est pas connecté, on affiche un message simple.
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Utilisateur non connecté'),
      );
    }

    // Écoute en temps réel du document utilisateur pour refléter
    // immédiatement les changements.
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: _rtdbService.ref('utilisateurs/${user.uid}').onValue,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Données utilisateur récupérées depuis Firestore.
            final data = snap.data?.snapshot.value != null
                ? Map<String, dynamic>.from(snap.data!.snapshot.value as Map)
                : {};
            final nom = data['nom'] as String? ?? '';
            final prenom = data['prenom'] as String? ?? '';
            final email = user.email ?? (data['email'] as String? ?? '');
            final telephone = data['telephone'] as String? ?? '';
            final adresse = data['adresse'] as String? ?? '';
            final role = data['role'] as String? ?? '';
            final dateCreation = data['dateCreation'] as String?;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Informations du compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ éditable: nom
                  _editableTile(
                    context,
                    'Nom',
                    nom,
                    (v) => _updateField('nom', v),
                  ),
                  // Champ éditable: prénom
                  _editableTile(
                    context,
                    'Prénom',
                    prenom,
                    (v) => _updateField('prenom', v),
                  ),
                  // Champ éditable: téléphone
                  _editableTile(
                    context,
                    'Téléphone',
                    telephone,
                    (v) => _updateField('telephone', v),
                  ),
                  // Champ éditable: adresse
                  _editableTile(
                    context,
                    'Adresse',
                    adresse,
                    (v) => _updateField('adresse', v),
                  ),

                  // Champ non éditable: rôle (affichage seulement)
                  ListTile(title: const Text('Rôle'), subtitle: Text(role)),

                  // Champ éditable spécial: email (met aussi à jour FirebaseAuth)
                  _editableTile(
                    context,
                    'Email',
                    email,
                    (v) => _updateEmail(user, v),
                  ),

                  // Champ éditable spécial: mot de passe (demande confirmation)
                  _editableTile(
                    context,
                    'Mot de passe',
                    '******',
                    (v) => _updatePassword(user, v),
                    isPassword: true,
                  ),

                  // Champ non éditable: date de création (affichage)
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

  /// Construit une tuile avec un bouton "Modifier".
  /// - [label] Nom du champ.
  /// - [value] Valeur actuelle affichée.
  /// - [onSave] Fonction asynchrone appelée avec la nouvelle valeur.
  /// - [isPassword] True si la valeur doit être saisie en mode mot de passe.
  Widget _editableTile(
    BuildContext context,
    String label,
    String value,
    Future<void> Function(String) onSave, {
    bool isPassword = false,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: TextButton(
        // Bouton permettant d'ouvrir une boîte de dialogue pour saisir la nouvelle valeur.
        onPressed: () async {
          final newValue = await _promptValue(
            context,
            label,
            isPassword: isPassword,
          );
          if (newValue == null) return;
          try {
            await onSave(newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Modifié.')));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
        child: const Text('Modifier', style: TextStyle(color: primaryBlue)),
      ),
    );
  }

  /// Affiche une boîte de dialogue demandant une valeur (et confirmation si mot de passe).
  Future<String?> _promptValue(
    BuildContext context,
    String label, {
    bool isPassword = false,
  }) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $label'),
        content: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
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
              final v1 = ctrl1.text.trim();
              if (isPassword) {
                final v2 = ctrl2.text.trim();
                // Mot de passe: au moins 6 caractères et confirmation identique.
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

  /// Met à jour un champ simple du document utilisateur dans Firestore.
  Future<void> _updateField(String field, String value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _rtdbService.updateUserField(uid, field, value);
  }

  /// Met à jour l'email via le flux recommandé par FirebaseAuth :
  /// envoie un mail de vérification avant la mise à jour effective.
  Future<void> _updateEmail(User user, String newEmail) async {
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  /// Met à jour le mot de passe côté FirebaseAuth.
  Future<void> _updatePassword(User user, String newPassword) async {
    await user.updatePassword(newPassword);
  }
}
