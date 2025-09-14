import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BotpressChatPage extends StatefulWidget {
  const BotpressChatPage({super.key});

  @override
  State<BotpressChatPage> createState() => _BotpressChatPageState();
}

class _BotpressChatPageState extends State<BotpressChatPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    const botpressChatUrl =
        'https://cdn.botpress.cloud/webchat/v3.2/shareable.html?configUrl=https://files.bpcontent.cloud/2025/08/22/06/20250822063328-SFWL643R.json';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Mettre à jour la barre de chargement.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(botpressChatUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Virtuel'),
        backgroundColor: const Color(0xFF3D90D7),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
