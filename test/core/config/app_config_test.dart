import 'package:campusfix/core/config/app_config.dart';
import 'package:campusfix/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('correctly parses environment strings', () {
      expect(
        AppEnvironment.fromString('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironment.fromString('dev'), AppEnvironment.development);
      expect(AppEnvironment.fromString('DEV'), AppEnvironment.development);
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('stage'), AppEnvironment.staging);
      expect(
        AppEnvironment.fromString('production'),
        AppEnvironment.production,
      );
      expect(AppEnvironment.fromString('prod'), AppEnvironment.production);
      expect(AppEnvironment.fromString('unknown'), AppEnvironment.production);
      expect(AppEnvironment.fromString(null), AppEnvironment.production);
    });

    test('helper flags and labels behave correctly', () {
      expect(AppEnvironment.development.isDevelopment, isTrue);
      expect(AppEnvironment.development.isProduction, isFalse);
      expect(AppEnvironment.development.label, 'DEV');

      expect(AppEnvironment.staging.isStaging, isTrue);
      expect(AppEnvironment.staging.label, 'STAGING');

      expect(AppEnvironment.production.isProduction, isTrue);
      expect(AppEnvironment.production.label, 'PROD');
    });
  });

  group('AppConfig', () {
    test('initializes with expected production defaults', () {
      const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: AppConfig.defaultProductionApiBaseUrl,
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.apiBaseUrl, 'https://campusfixed.netlify.app/api/v1');
      expect(config.appName, 'CampusFix');
      expect(config.appId, 'com.campusfix.app');
      expect(config.connectTimeout, const Duration(seconds: 15));
      expect(config.receiveTimeout, const Duration(seconds: 15));
      expect(
        config.googleServerClientId,
        AppConfig.defaultGoogleServerClientId,
      );
      expect(config.googleClientId, isNull);
    });

    test('copyWith updates specified fields only', () {
      const original = AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: AppConfig.defaultDevelopmentApiBaseUrl,
      );

      final updated = original.copyWith(
        apiBaseUrl: 'http://192.168.1.100:5000/api/v1',
      );

      expect(updated.apiBaseUrl, 'http://192.168.1.100:5000/api/v1');
      expect(updated.environment, AppEnvironment.development);
      expect(updated.appName, original.appName);
    });

    test('value equality works as expected', () {
      const config1 = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://campusfixed.netlify.app/api/v1',
      );
      const config2 = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://campusfixed.netlify.app/api/v1',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });
  });
}
