import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/mes_classes.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthode pour enregistrer un nouvel utilisateur
  Future<String?> registerUser({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String adresse,
    String? telephone,
    String role = "parent",
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Création de l'utilisateur pour Firestore
      Utilisateur newUser = Utilisateur(
        id: userCredential.user!.uid,
        nom: nom.trim(),
        prenom: prenom.trim(),
        dateCreation: DateTime.now(),
        adresse: adresse.trim(),
        telephone: telephone?.trim(),
        empreinte: 0, // Doit être un int, comme dans la classe Utilisateur.
        role: role,
        visage: [],
      );

      // Enregistrement du document dans la collection "utilisateurs"
      await _firestore
          .collection("utilisateurs")
          .doc(newUser.id)
          .set(newUser.toMap());

      return null; // null signifie succès
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
