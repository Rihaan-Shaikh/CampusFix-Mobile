/// Supported runtime environments for CampusFix Mobile.
enum AppEnvironment {
  development,
  staging,
  production;

  /// Parse environment from string name, defaulting to production for safety.
  static AppEnvironment fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
      default:
        return AppEnvironment.production;
    }
  }

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;

  String get label {
    switch (this) {
      case AppEnvironment.development:
        return 'DEV';
      case AppEnvironment.staging:
        return 'STAGING';
      case AppEnvironment.production:
        return 'PROD';
    }
  }
}
