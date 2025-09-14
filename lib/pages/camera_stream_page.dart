import 'package:flutter/material.dart';
import '../services/rtdb_service.dart'; // Import du service RTDB
import 'package:webview_flutter/webview_flutter.dart'; // Import pour la WebView

/// Une page dédiée à l'affichage du flux vidéo en temps réel d'une caméra ESP32-CAM.
///
/// Cette page récupère l'URL du flux depuis Firestore (collection 'config', document 'esp32cam')
/// et utilise le widget `VlcPlayer` pour afficher la vidéo.
class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({super.key});

  @override
  State<CameraStreamPage> createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  final RtdbService _rtdbService = RtdbService(); // Utilisation du service RTDB
  WebViewController? _webViewController;
  String? _streamUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCameraInterface();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Récupère l'URL de l'interface de la caméra et l'affiche dans une WebView.
  Future<void> _loadCameraInterface() async {
    try {
      // Lecture depuis Realtime Database via le service
      final snapshot = await _rtdbService.ref('camera/ipAddress').get();

      if (snapshot.exists && snapshot.value != null) {
        final ipAddress = snapshot.value as String;
        // L'URL du flux de l'ESP32-CAM est exactement celle fournie par l'appareil.
        final cameraUrl = 'http://$ipAddress';

        setState(() {
          _streamUrl = cameraUrl;
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onWebResourceError: (error) {
                  _errorMessage = "Erreur de chargement: ${error.description}";
                },
              ),
            )
            ..loadRequest(Uri.parse(_streamUrl!));
        });
      } else {
        setState(() {
          _errorMessage = "L'URL du flux de la caméra n'est pas configurée.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de chargement de l'interface : $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Interface Caméra"),
        backgroundColor: const Color(0xFF3D90D7),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Text(_errorMessage!, textAlign: TextAlign.center)
            : _webViewController != null
            ? WebViewWidget(controller: _webViewController!)
            : const Text("Contrôleur web non initialisé."),
      ),
    );
  }
}
