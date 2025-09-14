import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/mes_classes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rtdb_service.dart';

/// Page de connexion qui authentifie l'utilisateur et redirige selon son rôle.
/// Utilise FirebaseAuth et Cloud Firestore ; stocke l'état en mémoire via SessionManager.
/// C'est le point d'entrée pour les utilisateurs existants.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// État associé à [LoginPage], gère les champs de saisie et la logique de connexion.
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RtdbService _rtdbService = RtdbService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Récupère les données de l'utilisateur (rôle, nom, prénom, statut) depuis Firestore.
  /// Se connecte à Firebase Realtime Database pour lire les données associées à un UID.
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    final snapshot = await _rtdbService.getUserData(uid);
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Redirige l'utilisateur selon son rôle.
  /// Affiche un message d'erreur si le rôle est inconnu ou manquant.
  Future<void> _navigateForRole(String? role) async {
    // Si le rôle est manquant, on ne redirige pas et on affiche une erreur.
    if (role == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rôle utilisateur introuvable.")),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (role == 'parent') {
      await prefs.setString('last_route', '/parent_home');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/parent_home');
    } else if (role == 'enfant') {
      await prefs.setString('last_route', '/enfant_home');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/enfant_home');
    } else if (role == 'admin') {
      await prefs.setString('last_route', '/admin_home');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin_home');
    } else {
      if (!mounted) return;
      // Rôle inconnu ou non défini: soit on bloque, soit on envoie vers une page par défaut
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rôle de l'utilisateur introuvable ou non autorisé."),
        ),
      );
    }
  }

  /// Authentifie l'utilisateur puis:
  ///  - récupère le rôle depuis Firestore,
  ///  - stocke les infos en session (in-memory),
  ///  - notifie et redirige selon le rôle.
  /// Les erreurs connues de FirebaseAuth sont converties en messages lisibles.
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Authentification avec le service Firebase Authentication.
      // Tente de connecter l'utilisateur avec l'email et le mot de passe fournis.
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user?.uid;
      final email = userCredential.user?.email;

      if (uid == null) {
        throw Exception("Impossible de récupérer l'ID utilisateur.");
      }

      // 2) Récupération des données utilisateur depuis Firebase Realtime Database.
      // On utilise l'UID de l'utilisateur connecté pour trouver ses informations.
      final userData = await _fetchUserData(uid);
      if (userData == null) {
        throw Exception("Données utilisateur introuvables.");
      }

      // 3) Vérification du statut de l'utilisateur
      final statut =
          userData['statut'] as String? ?? 'Activé'; // Par défaut 'Activé'
      if (statut == 'Désactivé') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Ce compte a été désactivé. Veuillez contacter le parent.",
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        await _auth.signOut(); // Déconnexion immédiate
        return; // Arrêt du processus de connexion
      }

      // 4) Stockage des informations en session (in-memory)
      final role = userData['role'] as String?;
      await SessionManager.instance.setSession(
        uid: uid,
        email: email,
        role: role,
        nom: userData['nom'] as String?,
        prenom: userData['prenom'] as String?,
      );

      debugPrint("ID utilisateur connecté : ${SessionManager.instance.userId}");
      debugPrint("Rôle utilisateur : ${SessionManager.instance.role}");

      // 6) Redirection selon le rôle
      if (!mounted) return;
      await _navigateForRole(role);
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur inconnue';
      if (e.code == 'user-not-found') {
        message = 'Utilisateur non trouvé';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      // Bouton pour afficher ou masquer le mot de passe.
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Bouton qui lance le processus de connexion.
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A59D1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pas encore de compte ?"),
                    TextButton(
                      // Bouton pour naviguer vers la page d'inscription.
                      onPressed: () {
                        Navigator.pushNamed(context, "/inscription");
                      },
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: Color(0xFF3A59D1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
