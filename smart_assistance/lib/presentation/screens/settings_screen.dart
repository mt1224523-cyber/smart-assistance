import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../core/locale/app_locale.dart';
import '../../core/theme/app_theme.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Synthèse vocale (TTS)'),
                        subtitle: const Text(
                          'L\'application lit les réponses à haute voix',
                        ),
                        value: provider.ttsEnabled,
                        onChanged: (value) {
                          provider.setTtsEnabled(value);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Reconnaissance vocale (STT)'),
                        subtitle: const Text(
                          'Permet de parler pour poser des questions',
                        ),
                        value: provider.sttEnabled,
                        onChanged: (value) {
                          provider.setSttEnabled(value);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apparence',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<ThemeMode>(
                        title: const Text('Suivre le système'),
                        value: ThemeMode.system,
                        groupValue: provider.themeMode,
                        onChanged: (v) {
                          if (v != null) provider.setThemeMode(v);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Clair'),
                        value: ThemeMode.light,
                        groupValue: provider.themeMode,
                        onChanged: (v) {
                          if (v != null) provider.setThemeMode(v);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Sombre'),
                        value: ThemeMode.dark,
                        groupValue: provider.themeMode,
                        onChanged: (v) {
                          if (v != null) provider.setThemeMode(v);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Langue de réponse',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                'La reconnaissance et la lecture vocale restent en français pour toutes les langues.',
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...AppLocale.values.map(
                        (locale) => RadioListTile<AppLocale>(
                          title: Row(
                            children: [
                              Text(locale.label),
                              if (locale.isExperimental) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'expérimental',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            locale.description,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: locale,
                          groupValue: provider.locale,
                          onChanged: (v) {
                            if (v != null) provider.setLocale(v);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À propos',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Assistant Intelligent Local'),
                        subtitle: const Text(
                          'Votre assistant IA adapté au contexte ivoirien',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Politique de confidentialité'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 48,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Développé avec ❤️ pour la Côte d\'Ivoire',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
