import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

    import '../services/session_manager.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  /// Page de connexion qui authentifie l'utilisateur et redirige selon son rôle.
  /// Utilise FirebaseAuth et Cloud Firestore ; stocke l'état en mémoire via SessionManager.
  class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPageState();
  }

  class _LoginPageState extends State<LoginPage> {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    bool _obscurePassword = true;
    bool _isLoading = false;

    @override
    void dispose() {
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

    /// Récupère le rôle de l'utilisateur depuis Firestore (collection 'utilisateurs').
    /// Retourne une chaîne ('parent', 'admin', 'teacher') ou null si absent.
    Future<String?> _fetchUserRole(String uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs') // Assurez-vous que c'est bien votre collection
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final role = data['role'];
      if (role is String) {
        return role;
      }
      return null;
    }

    /// Récupère nom et prénom depuis Firestore (collection 'utilisateurs').
    Future<Map<String, String?>> _fetchUserIdentity(String uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(uid)
          .get();
      final data = doc.data();
      return {
        'nom': (data != null && data['nom'] is String) ? data['nom'] as String : null,
        'prenom': (data != null && data['prenom'] is String) ? data['prenom'] as String : null,
      };
    }

    /// Redirige l'utilisateur selon son rôle.
    /// Affiche un message d'erreur si le rôle est inconnu ou manquant.
    Future<void> _navigateForRole(String? role) async {
      final prefs = await SharedPreferences.getInstance();
      if (role == 'parent') {
        await prefs.setString('last_route', '/parent_home');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/parent_home');
      } else if (role == 'admin') {
        await prefs.setString('last_route', '/admin');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'teacher') {
        await prefs.setString('last_route', '/teacher');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/teacher');
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
        // 1) Authentification
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final uid = userCredential.user?.uid;
        final email = userCredential.user?.email;

        if (uid == null) {
          throw Exception("Impossible de récupérer l'ID utilisateur.");
        }

        // 2) Récupération du rôle depuis Firestore
        final role = await _fetchUserRole(uid);

        // 3) Récupération identité (nom, prénom) puis stockage en session (in-memory)
        final identity = await _fetchUserIdentity(uid);
        await SessionManager.instance.setSession(
          uid: uid,
          email: email,
          role: role,
          nom: identity['nom'],
          prenom: identity['prenom'],
        );

        // Debug
        // Déjà utilisable sur cette page via SessionManager.instance.userId
        // et SessionManager.instance.role
        debugPrint("ID utilisateur connecté : ${SessionManager.instance.userId}");
        debugPrint("Rôle utilisateur : ${SessionManager.instance.role}");

        // 4) Notification utilisateur
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté en tant que ${email ?? uid}'),
          ),
        );

        // 5) Redirection selon le rôle
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
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
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
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