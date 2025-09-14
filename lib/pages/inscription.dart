import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/mes_classes.dart';
import '../services/rtdb_service.dart';

/// Page permettant à un nouvel utilisateur de créer un compte.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// État associé à [RegisterPage], gère le formulaire et la logique d'inscription.
class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  final RtdbService _rtdbService = RtdbService();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Création de l'utilisateur dans le service Firebase Authentication.
        // Cette fonction crée un nouvel utilisateur avec un email et un mot de passe.
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // Si la création réussit, Firebase Auth retourne un `UserCredential`
        // qui contient l'UID (identifiant unique) de l'utilisateur.

        // 2. Création de l’objet Utilisateur
        Utilisateur newUser = Utilisateur(
          id: userCredential.user!.uid,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          dateCreation: DateTime.now(),
          adresse: _adresseController.text.trim(),
          telephone: _telephoneController.text.trim(),
          empreinte: 0, // 0 par défaut, car c'est un int maintenant
          role: "parent", // valeur par défaut
          visage: [],
        );

        // 3. Enregistrement des informations de l'utilisateur dans Firebase Realtime Database.
        // On utilise l'UID obtenu de Firebase Auth comme clé pour stocker les données de l'utilisateur.
        await _rtdbService.setUserData(newUser.id, newUser.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inscription réussie ✅")),
          );
          // Redirection vers la page de connexion
          Navigator.pushReplacementNamed(context, "/login_page");
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : ${e.message}")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs !")),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  // Widget build(BuildContext context) {
  // Scaffold fournit la structure visuelle de base de la page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SingleChildScrollView permet de faire défiler le contenu si l'écran est trop petit.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Affiche le logo de l'application au centre.
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 40),
                // Formulaire pour regrouper et valider les champs de saisie.
                Form(
                  key:
                      _formKey, // Clé pour identifier et gérer l'état du formulaire.
                  child: Column(
                    children: [
                      // Champ de saisie pour le nom.
                      TextFormField(
                        controller: _nomController,
                        decoration: InputDecoration(
                          labelText: "Nom",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        // Valide que le champ n'est pas vide.
                        validator: (value) =>
                            value!.isEmpty ? "Veuillez entrer votre nom" : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour le prénom.
                      TextFormField(
                        controller: _prenomController,
                        decoration: InputDecoration(
                          labelText: "Prénom",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        // Valide que le champ n'est pas vide.
                        validator: (value) => value!.isEmpty
                            ? "Veuillez entrer votre prénom"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour l'email.
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        // Valide que le champ n'est pas vide.
                        validator: (value) =>
                            value!.isEmpty ? "Veuillez entrer un email" : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour l'adresse.
                      TextFormField(
                        controller: _adresseController,
                        decoration: InputDecoration(
                          labelText: "Adresse",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.home),
                        ),
                        // Valide que le champ n'est pas vide.
                        validator: (value) => value!.isEmpty
                            ? "Veuillez entrer votre adresse"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour le téléphone.
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Téléphone",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        // Valide que le champ n'est pas vide.
                        validator: (value) => value!.isEmpty
                            ? "Veuillez entrer votre numéro"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour le mot de passe.
                      TextFormField(
                        controller: _passwordController,
                        obscureText:
                            _obscureText, // Masque le texte si _obscureText est vrai.
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          // Icône pour afficher/masquer le mot de passe.
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            // Bouton pour afficher ou masquer le mot de passe.
                            onPressed: () {
                              // Met à jour l'état pour basculer la visibilité.
                              setState(() => _obscureText = !_obscureText);
                            },
                          ),
                        ),
                        // Valide que le mot de passe a au moins 6 caractères.
                        validator: (value) =>
                            value!.length < 6 ? "Au moins 6 caractères" : null,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie pour la confirmation du mot de passe.
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true, // Toujours masqué.
                        decoration: InputDecoration(
                          labelText: "Confirmer le mot de passe",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        // Valide que la confirmation correspond au mot de passe.
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Veuillez confirmer le mot de passe";
                          }
                          if (value != _passwordController.text) {
                            return "Les mots de passe ne correspondent pas";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Bouton d'inscription.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          // Désactive le bouton pendant le chargement.
                          // Bouton qui lance le processus d'inscription.
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A59D1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60),
                            ),
                          ),
                          // Affiche un indicateur de chargement ou le texte du bouton.
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Lien pour rediriger vers la page de connexion.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Déjà un compte ?"),
                          TextButton(
                            // Bouton pour naviguer vers la page de connexion si l'utilisateur a déjà un compte.
                            onPressed: () {
                              // Navigation vers la page de connexion.
                              Navigator.pushNamed(context, "/login_page");
                            },
                            child: const Text(
                              "Se connecter",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
