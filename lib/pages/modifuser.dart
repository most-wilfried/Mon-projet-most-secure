import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rtdb_service.dart';

class ModifUserPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ModifUserPage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ModifUserPage> createState() => _ModifUserPageState();
}

class _ModifUserPageState extends State<ModifUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  late TextEditingController _telephoneController;
  late TextEditingController _codePinController;

  String? _selectedRole;
  bool _isLoading = false;
  final RtdbService _rtdbService = RtdbService();

  @override
  void initState() {
    super.initState();
    final data = widget.userData;
    _nomController = TextEditingController(text: data["nom"]);
    _prenomController = TextEditingController(text: data["prenom"]);
    // L'email n'est pas dans les données RTDB, on le prend de l'objet utilisateur si possible
    // Pour l'instant, on le laisse vide s'il n'est pas dans userData.
    _emailController = TextEditingController(text: data["email"] ?? '');
    _adresseController = TextEditingController(text: data["adresse"]);
    _telephoneController = TextEditingController(text: data["telephone"]);
    _codePinController = TextEditingController(text: data["codePin"]);
    _selectedRole = data["role"];
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedData = {
          "nom": _nomController.text.trim(),
          "prenom": _prenomController.text.trim(),
          "email": _emailController.text.trim(),
          "adresse": _adresseController.text.trim(),
          "telephone": _telephoneController.text.trim(),
          "codePin": _codePinController.text.trim(),
          "role": _selectedRole,
          "dateModification": DateTime.now().toIso8601String(),
        };

        await _rtdbService
            .ref('utilisateurs/${widget.userId}')
            .update(updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Utilisateur modifié ✅")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Déclenche une demande de mise à jour de l'empreinte pour l'utilisateur.
  Future<void> _requestEmpreinteUpdate() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) return;

    await _rtdbService.requestEmpreinte(widget.userId, adminId);
  }

  /// Déclenche une demande de mise à jour du visage pour l'utilisateur.
  Future<void> _requestVisageUpdate() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) return;
    // Logique à implémenter dans RtdbService si nécessaire
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _codePinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier un utilisateur"),
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
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Veuillez entrer l'email" : null,
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

                // Section pour la biométrie
                const Text(
                  "Authentification biométrique",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      onPressed: () async {
                        await _requestEmpreinteUpdate();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Demande de modification d'empreinte envoyée.",
                              ),
                            ),
                          );
                        }
                      },
                      label: const Text("l'empreinte"),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.face),
                      onPressed: () async {
                        await _requestVisageUpdate();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Demande de modification de visage envoyée.",
                              ),
                            ),
                          );
                        }
                      },
                      label: const Text("le visage"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A59D1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Enregistrer les modifications"),
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
