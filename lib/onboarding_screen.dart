import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      'image': 'assets/images/page1.png',
      'title': 'Contrôle à distance',
      'description': 'Activez ou désactivez les alarmes, ouvrez la porte ou consultez l’état du système à tout moment via votre smartphone.',
    },
    {
      'image': 'assets/images/page2.png',
      'title': 'Surveillance intelligente',
      'description': 'Des caméras et capteurs détectent toute activité suspecte. Recevez des alertes en temps réel, où que vous soyez.',
    },
    {
      'image': 'assets/images/page3.png',
      'title': ' Accès biométrique sécurisé',
      'description': 'Accédez à votre domicile avec reconnaissance faciale, empreinte digitale ou code PIN personnalisé.',
    },
    {
      'image': 'assets/images/page4.png',
      'title': 'Détection d’intrusion avancée',
      'description': ' Un laser de détection, des capteurs infrarouges et des alarmes protègent chaque recoin de votre maison.',
    },
    {
      'image': 'assets/images/page5.png',
      'title': ' Soyez toujours informé',
      'description': 'Recevez des notifications instantanées sur votre mobile en cas d’anomalie ou d’intrusion.',
    },
  ];

  void _nextPage() {
    if (_currentPage < pages.length) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('last_route', '/login_page');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login_page');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageContent(Map<String, String> page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page['image']!,
            width: 220,
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            page['title']!,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page['description']!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 160, height: 160),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async { await _skip(); },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
              ),
            ),
            child: const Text(
              "Commencer l'expérience",
              style: TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = pages.length + 1; // 5 pages + 1 page finale

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tutoriel'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async { await _skip(); },
            child: const Text('Skip', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                if (index == pages.length) {
                  return _buildLastPage();
                } else {
                  return _buildPageContent(pages[index]);
                }
              },
            ),
          ),

          // Barre de progression
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular (100),
              value: (_currentPage + 1) / totalPages,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blue.shade700,
              minHeight: 7,
            ),
          ),

          // Boutons navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage == 0 ? null : _previousPage,
                  child: const Text('Précédent'),
                ),
                ElevatedButton(
                  onPressed: _currentPage == pages.length ? null : _nextPage,
                  child: const Text('Suivant'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
