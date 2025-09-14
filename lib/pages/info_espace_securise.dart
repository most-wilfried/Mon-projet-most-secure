import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Feuille (BottomSheet) d'information et d'édition de l'espace sécurisé
/// associé à l'utilisateur connecté.
///
/// Les données proviennent du document `espaces_securises/{uid}` et peuvent
/// être mises à jour via les boutons "Modifier".
class EspaceSecuriseEditorSheet extends StatelessWidget {
  const EspaceSecuriseEditorSheet({super.key});

  // Couleur primaire utilisée par les boutons "Modifier".
  static const Color primaryBlue = Color(0xFF3A59D1);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Si l'utilisateur n'est pas connecté, on affiche un message simple.
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Utilisateur non connect��'),
      );
    }

    // Écoute en temps réel de l'espace sécurisé lié à l'utilisateur.
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

            // Données de l'espace sécurisé récupérées depuis Firestore.
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
                      'Espace s��curisé',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ éditable: adresse
                  _editableTile(context, 'Adresse', adresse, (v) => _updateField(user.uid, 'adresse', v)),
                  // Champ éditable: état
                  _editableTile(context, 'État', etat, (v) => _updateField(user.uid, 'etat', v)),
                  // Champ éditable: nombre de capteurs (conversion en int)
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

  /// Construit une tuile avec un bouton "Modifier".
  /// - [label] Nom du champ.
  /// - [value] Valeur actuelle affichée.
  /// - [onSave] Fonction asynchrone appelée avec la nouvelle valeur.
  Widget _editableTile(
    BuildContext context,
    String label,
    String value,
    Future<void> Function(String) onSave,
  ) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: TextButton(
        // Bouton permettant d'ouvrir une boîte de dialogue pour saisir la nouvelle valeur.
        onPressed: () async {
          final newValue = await _promptValue(context, label);
          if (newValue == null) return;
          try {
            await onSave(newValue);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modifié.')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
        child: const Text('Modifier', style: TextStyle(color: primaryBlue)),
      ),
    );
  }

  /// Affiche une boîte de dialogue demandant une valeur.
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

  /// Met à jour un champ simple du document `espaces_securises/{uid}` dans Firestore.
  Future<void> _updateField(String uid, String field, Object value) async {
    await FirebaseFirestore.instance.collection('espaces_securises').doc(uid).update({field: value});
  }
}
