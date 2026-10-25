import 'package:campusfix/core/config/app_config.dart';
import 'package:campusfix/core/config/app_environment.dart';
import 'package:campusfix/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDioClient', () {
    test('configures Dio BaseOptions from AppConfig correctly', () {
      const config = AppConfig(
        environment: AppEnvironment.staging,
        apiBaseUrl: 'https://staging.campusfixed.netlify.app/api/v1',
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        enableLogging: false,
      );

      final dio = createDioClient(config);

      expect(
        dio.options.baseUrl,
        'https://staging.campusfixed.netlify.app/api/v1',
      );
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
      expect(dio.options.sendTimeout, const Duration(seconds: 10));
      expect(dio.options.headers['Accept'], 'application/json');
      expect(dio.options.headers['Content-Type'], 'application/json');
      expect(dio.interceptors.length, greaterThanOrEqualTo(2));
    });
  });
}
