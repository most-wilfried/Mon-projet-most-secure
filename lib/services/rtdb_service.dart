import 'package:firebase_database/firebase_database.dart';

/// Un service pour centraliser les interactions avec Firebase Realtime Database.
/// Chaque méthode correspond à une opération spécifique sur la base de données.
class RtdbService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Retourne une référence à un chemin spécifique dans la base de données.
  /// C'est la fonction de base pour accéder à n'importe quelle donnée dans Firebase Realtime Database.
  DatabaseReference ref(String path) {
    return _db.ref(path);
  }

  /// Met à jour l'état de la porte.
  /// Se connecte à Firebase Realtime Database pour écrire l'état, l'ID de l'utilisateur et le timestamp.
  Future<void> setPorteState(bool isOpen, String userId) async {
    await ref('porte/etat').set(isOpen);
    await ref('porte/last_user_id').set(userId);
    await ref('porte/timestamp').set(ServerValue.timestamp);
  }

  /// Met à jour l'état de l'alarme.
  /// Se connecte à Firebase Realtime Database pour écrire l'état de l'alarme et l'ID de l'utilisateur.
  Future<void> setAlarmeState(bool isActive, String userId) async {
    await ref('alarme/etat').set(isActive);
    await ref('alarme/last_user_id').set(userId);
  }

  /// Crée ou met à jour un utilisateur.
  /// Se connecte à Firebase Realtime Database pour enregistrer toutes les données d'un utilisateur sous son UID.
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    await ref('utilisateurs/$uid').set(data);
  }

  /// Récupère les données d'un utilisateur.
  /// Se connecte à Firebase Realtime Database pour lire les informations d'un utilisateur via son UID.
  Future<DataSnapshot> getUserData(String uid) async {
    return await ref('utilisateurs/$uid').get();
  }

  /// Met à jour un champ spécifique pour un utilisateur.
  /// Se connecte à Firebase Realtime Database pour modifier une seule valeur dans le profil d'un utilisateur.
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await ref('utilisateurs/$uid/$field').set(value);
  }

  /// Ajoute une entrée à l'historique général.
  /// Se connecte à Firebase Realtime Database pour ajouter un nouvel événement dans la liste 'historique'.
  Future<void> logAction(Map<String, dynamic> data) async {
    await ref('historique').push().set(data);
  }

  /// Ajoute une entrée à l'historique de l'alarme.
  /// Se connecte à Firebase Realtime Database pour ajouter un nouvel événement dans la liste 'historique_alarme'.
  Future<void> logAlarmeEvent(Map<String, dynamic> data) async {
    await ref('historique_alarme').push().set(data);
  }

  /// Ajoute un nouveau système.
  /// Se connecte à Firebase Realtime Database pour ajouter un nouvel 'espace sécurisé'.
  Future<void> addSystem(Map<String, dynamic> data) async {
    await ref('espaces_securises').push().set(data);
  }

  /// Met à jour un champ d'un espace sécurisé.
  /// Se connecte à Firebase Realtime Database pour modifier une seule valeur d'un 'espace sécurisé'.
  Future<void> updateEspaceField(String id, String field, dynamic value) async {
    await ref('espaces_securises/$id/$field').set(value);
  }

  /// Demande d'enregistrement d'empreinte.
  /// Se connecte à Firebase Realtime Database pour créer une demande d'enregistrement d'empreinte.
  Future<void> requestEmpreinte(String userId, String adminId) async {
    await ref('demandes/empreintes/$userId').set({
      "etat": true,
      "demandeurId": adminId,
      "timestamp": ServerValue.timestamp,
    });
  }
}
