import 'package:flutter/material.dart';
import '../services/rtdb_service.dart';

class AddSystemPage extends StatefulWidget {
  const AddSystemPage({super.key});

  @override
  State<AddSystemPage> createState() => _AddSystemPageState();
}

class _AddSystemPageState extends State<AddSystemPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomSystemeController = TextEditingController();
  final _quartierController = TextEditingController();

  String? _selectedPosition;
  String? _selectedLieu;
  bool _isLoading = false;
  final RtdbService _rtdbService = RtdbService();

  final List<String> _positions = [
    "Salon",
    "Garage",
    "Cuisine",
    "Chambre",
    "Bureau",
  ];
  final List<String> _lieux = ["Maison", "Bureau", "Commerce", "Autre"];

  Future<void> _saveSystem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _rtdbService.addSystem({
        "nomSysteme": _nomSystemeController.text.trim(),
        "positionCapteurs": _selectedPosition,
        "lieu": _selectedLieu,
        "quartier": _quartierController.text.trim(),
        "dateInstallation": DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Système ajouté avec succès ✅")),
        );
        Navigator.pop(context); // Retour à la page précédente (donnéespage)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
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
  void dispose() {
    _nomSystemeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un système"),
        backgroundColor: const Color(0xFF3A59D1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ Nom du système
                TextFormField(
                  controller: _nomSystemeController,
                  decoration: InputDecoration(
                    labelText: "Nom du système",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? "Veuillez entrer un nom de système"
                      : null,
                ),
                const SizedBox(height: 20),

                // Menu déroulant Position Capteurs
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Position des capteurs",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedPosition,
                  items: _positions
                      .map(
                        (pos) => DropdownMenuItem(value: pos, child: Text(pos)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPosition = val),
                  validator: (value) => value == null
                      ? "Veuillez sélectionner une position"
                      : null,
                ),
                const SizedBox(height: 20),

                // Menu déroulant Lieu
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Lieu",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedLieu,
                  items: _lieux
                      .map(
                        (lieu) =>
                            DropdownMenuItem(value: lieu, child: Text(lieu)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLieu = val),
                  validator: (value) =>
                      value == null ? "Veuillez sélectionner un lieu" : null,
                ),
                const SizedBox(height: 20),

                // Champ Quartier
                TextFormField(
                  controller: _quartierController,
                  decoration: InputDecoration(
                    labelText: "Quartier",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Veuillez entrer un quartier" : null,
                ),
                const SizedBox(height: 30),

                // Bouton Valider
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSystem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A59D1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Valider",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
