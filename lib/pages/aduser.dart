import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/mes_classes.dart';
import '../services/rtdb_service.dart';
import 'dart:async';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _codePinController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;

  // Référence au service Realtime Database
  final RtdbService _rtdbService = RtdbService();

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Création Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final uid = userCredential.user!.uid;

        // Création objet utilisateur
        Utilisateur newUser = Utilisateur(
          id: uid,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          dateCreation: DateTime.now(),
          adresse: _adresseController.text.trim(),
          telephone: _telephoneController.text.trim(),
          empreinte: 0, // L'empreinte sera ajoutée depuis le profil
          role: _selectedRole ?? "enfant",
          visage: [],
        );

        // Sauvegarde Realtime Database
        final userData = newUser.toMap();
        userData['codePin'] = _codePinController.text.trim();
        await _rtdbService.setUserData(uid, userData);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Utilisateur ajouté ✅")));
          Navigator.pop(context); // retour vers UsersPage
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : ${e.message}")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Active/désactive visage

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _codePinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un utilisateur"),
        backgroundColor: const Color(0xFF3A59D1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 5),
                // Affiche le logo de l'application au centre.
                Center(
                  child: Image.asset(
                    'assets/images/pp.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: "Nom",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer le nom" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: "Prénom",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer le prénom" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer l'email" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? "Mot de passe trop court" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: "Adresse",
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer l'adresse" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Téléphone",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer le téléphone" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _codePinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Code PIN",
                    prefixIcon: Icon(Icons.pin),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer le code PIN" : null,
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: "parent", child: Text("Parent")),
                    DropdownMenuItem(value: "enfant", child: Text("Enfant")),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                  },
                  decoration: const InputDecoration(
                    labelText: "Rôle",
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  validator: (v) =>
                      v == null ? "Veuillez sélectionner un rôle" : null,
                ),
                const SizedBox(height: 20),

                // Boutons visage & empreinte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.face),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Fonctionnalité non implémentée."),
                          ),
                        );
                      },
                      label: const Text("Visage"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A59D1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Enregistrer"),
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
