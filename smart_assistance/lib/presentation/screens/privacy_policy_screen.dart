import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Quelles données nous utilisons',
            body:
                "L'application Assistant Intelligent traite les éléments suivants pour répondre à vos questions :\n\n"
                "• Le texte de vos questions, tapé ou dicté.\n"
                "• Les images que vous choisissez d'envoyer.\n"
                "• Vos paramètres (synthèse vocale, reconnaissance vocale).\n\n"
                "L'application n'enregistre ni votre nom, ni votre numéro, ni votre position géographique.",
          ),
          _Section(
            title: 'Où vos données sont traitées',
            body:
                "Vos questions et images sont transmises de manière chiffrée (HTTPS) à notre serveur, qui les relaie à OpenAI (États-Unis) pour générer une réponse. OpenAI peut conserver ces échanges pendant une durée limitée à des fins de sécurité, conformément à sa propre politique (https://openai.com/policies/privacy-policy).\n\n"
                "Notre serveur ne conserve pas vos questions au-delà du temps nécessaire à la réponse.",
          ),
          _Section(
            title: 'Stockage local',
            body:
                "L'historique de vos conversations et vos préférences sont stockés uniquement sur votre téléphone, dans un espace chiffré (Keystore Android / Keychain iOS). Personne d'autre, y compris nous, ne peut y accéder.\n\n"
                "Vous pouvez effacer cet historique à tout moment depuis l'onglet Historique.",
          ),
          _Section(
            title: 'Vos droits',
            body:
                "Vous pouvez :\n"
                "• Effacer votre historique depuis l'application.\n"
                "• Désinstaller l'application : toutes vos données locales sont alors supprimées.\n"
                "• Demander la suppression de toute donnée résiduelle en nous contactant.",
          ),
          _Section(
            title: 'Avertissement médical',
            body:
                "Les réponses fournies par l'assistant ne remplacent pas l'avis d'un professionnel. Pour toute question de santé, consultez un médecin ou un personnel soignant qualifié.",
          ),
          _Section(
            title: 'Contact',
            body:
                "Pour toute question relative à vos données, contactez : contact@exemple.ci",
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
