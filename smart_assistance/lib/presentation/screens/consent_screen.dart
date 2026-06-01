import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'privacy_policy_screen.dart';

class ConsentScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const ConsentScreen({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.smart_toy,
                size: 72,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Bienvenue',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Avant de démarrer, voici comment nous traitons vos données.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bullet(
                        icon: Icons.cloud_outlined,
                        title: 'Vos questions sont envoyées à OpenAI',
                        body:
                            'Pour générer une réponse, vos questions et images sont transmises de manière chiffrée à notre serveur puis à OpenAI (États-Unis).',
                      ),
                      _Bullet(
                        icon: Icons.lock_outline,
                        title: 'Historique chiffré sur votre téléphone',
                        body:
                            "L'historique reste sur votre appareil dans un espace sécurisé. Vous pouvez l'effacer à tout moment.",
                      ),
                      _Bullet(
                        icon: Icons.medical_services_outlined,
                        title: 'Pas un avis médical',
                        body:
                            "Les réponses de l'assistant ne remplacent pas l'avis d'un médecin.",
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: const Text('Lire la politique de confidentialité'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onAccept,
                  child: const Text(
                    "J'ai compris et j'accepte",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Bullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
