/// Langue de réponse de l'assistant.
///
/// ⚠️ La reconnaissance vocale (STT) et la synthèse vocale (TTS) restent en
/// français — les moteurs natifs Android/iOS ne supportent pas le Dioula,
/// Nouchi ou Baoulé. Seul le texte de la réponse change de langue.
enum AppLocale {
  french('fr', 'Français', 'Langue principale, STT/TTS supportés.'),
  dioula(
    'dioula',
    'Dioula',
    "Expérimental — réponse écrite en Dioula. Audio en français.",
  ),
  nouchi(
    'nouchi',
    'Nouchi',
    "Expérimental — argot ivoirien. Audio en français.",
  ),
  baoule(
    'baoule',
    'Baoulé',
    "Expérimental — réponse écrite en Baoulé. Audio en français.",
  );

  final String code;
  final String label;
  final String description;

  const AppLocale(this.code, this.label, this.description);

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.french,
    );
  }

  bool get isExperimental => this != AppLocale.french;
}
