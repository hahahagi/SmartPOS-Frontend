class AppEnv {
  const AppEnv._();

  static const String appName = 'SmartPOS';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const bool enableVerboseLogging = bool.fromEnvironment(
    'ENABLE_VERBOSE_LOGGING',
    defaultValue: true,
  );
}
