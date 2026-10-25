import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

/// Immutable typed application configuration.
///
/// Supports build-time overrides via `--dart-define` without embedding credentials:
/// - `--dart-define=ENVIRONMENT=development`
/// - `--dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1`
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.appName = 'CampusFix',
    this.appId = 'com.campusfix.app',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.enableLogging = kDebugMode,
    this.googleServerClientId = defaultGoogleServerClientId,
    this.googleClientId,
  });

  /// Default production Google Web Client ID for ID token audience validation.
  static const String defaultGoogleServerClientId =
      '440612845967-ggac7dh53iktbpo8t38qaj392kp5kk5v.apps.googleusercontent.com';

  /// Default production base URL derived from the existing production deployment.
  static const String defaultProductionApiBaseUrl =
      'https://campusfixed.netlify.app/api/v1';

  /// Default development base URL targeting local development servers.
  static const String defaultDevelopmentApiBaseUrl =
      'http://10.0.2.2:5000/api/v1';

  /// Default staging base URL.
  static const String defaultStagingApiBaseUrl =
      'https://staging.campusfixed.netlify.app/api/v1';

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;
  final String appId;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
  final String googleServerClientId;
  final String? googleClientId;

  /// Returns origin (scheme://host:port) parsed safely from [apiBaseUrl].
  String get origin {
    try {
      final uri = Uri.parse(apiBaseUrl);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        return uri.origin;
      }
    } catch (_) {}
    return apiBaseUrl;
  }

  /// Better Auth endpoint base URL (e.g. `https://campusfixed.netlify.app/api/auth`).
  String get authBaseUrl {
    const customAuthUrl = String.fromEnvironment('AUTH_BASE_URL');
    if (customAuthUrl.isNotEmpty) return customAuthUrl;
    return '$origin/api/auth';
  }

  /// Versioned API endpoints base URL (e.g. `https://campusfixed.netlify.app/api/v1`).
  String get v1BaseUrl {
    if (apiBaseUrl.endsWith('/api/v1')) return apiBaseUrl;
    return '$origin/api/v1';
  }

  /// Creates configuration by reading build-time Dart defines with fallback defaults.
  factory AppConfig.fromEnvironment() {
    const envString = String.fromEnvironment('ENVIRONMENT');
    final AppEnvironment env;
    if (envString.isNotEmpty) {
      env = AppEnvironment.fromString(envString);
    } else {
      // Default to production so mobile connects directly to the live backend out of the box,
      // while still allowing local development when ENVIRONMENT=development or API_BASE_URL is set.
      env = AppEnvironment.production;
    }

    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    final String baseUrl;
    if (customBaseUrl.isNotEmpty) {
      baseUrl = customBaseUrl;
    } else {
      switch (env) {
        case AppEnvironment.development:
          baseUrl = defaultDevelopmentApiBaseUrl;
        case AppEnvironment.staging:
          baseUrl = defaultStagingApiBaseUrl;
        case AppEnvironment.production:
          baseUrl = defaultProductionApiBaseUrl;
      }
    }

    const customServerClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );
    final String serverClientId = customServerClientId.isNotEmpty
        ? customServerClientId
        : defaultGoogleServerClientId;

    const customClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    final String? clientId = customClientId.isNotEmpty ? customClientId : null;

    return AppConfig(
      environment: env,
      apiBaseUrl: baseUrl,
      enableLogging: kDebugMode || env != AppEnvironment.production,
      googleServerClientId: serverClientId,
      googleClientId: clientId,
    );
  }

  AppConfig copyWith({
    AppEnvironment? environment,
    String? apiBaseUrl,
    String? appName,
    String? appId,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? enableLogging,
    String? googleServerClientId,
    String? googleClientId,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      appName: appName ?? this.appName,
      appId: appId ?? this.appId,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      googleServerClientId: googleServerClientId ?? this.googleServerClientId,
      googleClientId: googleClientId ?? this.googleClientId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          environment == other.environment &&
          apiBaseUrl == other.apiBaseUrl &&
          appName == other.appName &&
          appId == other.appId &&
          connectTimeout == other.connectTimeout &&
          receiveTimeout == other.receiveTimeout &&
          enableLogging == other.enableLogging &&
          googleServerClientId == other.googleServerClientId &&
          googleClientId == other.googleClientId;

  @override
  int get hashCode => Object.hash(
    environment,
    apiBaseUrl,
    appName,
    appId,
    connectTimeout,
    receiveTimeout,
    enableLogging,
    googleServerClientId,
    googleClientId,
  );

  @override
  String toString() {
    return 'AppConfig(env: ${environment.name}, baseUrl: $apiBaseUrl, googleClientId: $googleClientId)';
  }
}

/// Global provider for application configuration.
///
/// Can be overridden in tests or initialization via `ProviderScope(overrides: [...])`.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
