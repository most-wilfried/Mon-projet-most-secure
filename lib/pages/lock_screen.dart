import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _loading = true;

  // Préférences utilisateur (Firestore)
  bool _useBiometrics = false;
  bool _usePin = false;
  String? _codePin; // en clair pour démo
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
      final data = snap.data() ?? {};
      _useBiometrics = (data['useBiometrics'] as bool?) ?? false;
      _usePin = (data['usePin'] as bool?) ?? false;
      _codePin = data['codePin'] as String?;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de lecture des préférences: $e')),
      );
      _goToLogin();
      return;
    }
    setState(() => _loading = false);
    if (_useBiometrics) {
      await _tryBiometrics();
    }
  }

  Future<void> _tryBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) return;
      final success = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour déverrouiller',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (success) {
        await _unlockSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biométrie indisponible: $e')),
      );
    }
  }

  Future<void> _validatePin() async {
    final input = _pinController.text.trim();
    if (input.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le code PIN')),
      );
      return;
    }
    if (_codePin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun code PIN configuré')),
      );
      return;
    }
    if (input == _codePin) {
      await _unlockSuccess();
    } else {
      _attempts += 1;
      if (!mounted) return;
      if (_attempts >= _maxAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trop de tentatives. Redirection vers la connexion.')),
        );
        await FirebaseAuth.instance.signOut();
        _goToLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code incorrect ($_attempts/$_maxAttempts)')),
        );
      }
    }
  }

  Future<void> _unlockSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRoute = prefs.getString('last_route') ?? '/parent_home';
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, lastRoute);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Déverrouillage'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    if (_useBiometrics)
                      ElevatedButton(
                        onPressed: _tryBiometrics,
                        child: const Text('Déverrouiller avec biométrie'),
                      ),
                    if (_useBiometrics && _usePin) const SizedBox(height: 24),
                    if (_usePin)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePin,
                            decoration: InputDecoration(
                              labelText: 'Code PIN',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _validatePin();
                            },
                            child: const Text('Valider PIN'),
                          ),
                        ],
                      ),
                    if (!_useBiometrics && !_usePin)
                      const Text(
                        'Aucune méthode de verrouillage activée. Redirection vers la connexion...',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
