class AppConstants {
  static const String appName = 'Assistant Intelligent';
  static const String appVersion = '1.0.0';

  // Backend proxy. The OpenAI key lives on the server, never in the app.
  static const String proxyBaseUrl = String.fromEnvironment('PROXY_BASE_URL');
  static const String appApiKey = String.fromEnvironment('APP_API_KEY');

  // Crash reporting (optionnel). Vide -> Sentry désactivé.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String sentryEnvironment =
      String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'production');
}
