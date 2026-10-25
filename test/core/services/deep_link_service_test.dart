import 'package:campusfix/core/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkService URI parsing & resolution', () {
    const service = DeepLinkService();

    test(
      'extracts issue id from custom scheme uri campusfix://issue/iss_12345',
      () {
        final uri = Uri.parse('campusfix://issue/iss_12345');
        final issueId = service.extractIssueId(uri);
        expect(issueId, 'iss_12345');
      },
    );

    test('extracts issue id from custom scheme uri with path segments campusfix://issue/detail/iss_999', () {
      final uri = Uri.parse('campusfix://issue/detail/iss_999');
      final issueId = service.extractIssueId(uri);
      expect(issueId, 'iss_999');
    });

    test('extracts issue id from web domain https://campusfixed.netlify.app/issues/iss_abc', () {
      final uri = Uri.parse('https://campusfixed.netlify.app/issues/iss_abc');
      final issueId = service.extractIssueId(uri);
      expect(issueId, 'iss_abc');
    });

    test('returns null for unrelated domains or paths', () {
      final uri1 = Uri.parse('https://example.com/issues/iss_123');
      expect(service.extractIssueId(uri1), isNull);

      final uri2 = Uri.parse('https://campusfixed.netlify.app/about');
      expect(service.extractIssueId(uri2), isNull);

      final uri3 = Uri.parse('campusfix://settings');
      expect(service.extractIssueId(uri3), isNull);
    });

    test('resolves target route for valid issue id', () {
      final uri = Uri.parse('campusfix://issue/iss_test456');
      final route = service.resolveRoute(uri);
      expect(route, '/issues/iss_test456');
    });

    test('resolves fallback route /issues for unknown links', () {
      final uri = Uri.parse('campusfix://unknown');
      final route = service.resolveRoute(uri);
      expect(route, '/issues');
    });

    test('extracts token from campusfix://oauth-callback?token=xyz', () {
      final token = service.parseOAuthCallback(
        'campusfix://oauth-callback?token=my_secret_token',
      );
      expect(token, 'my_secret_token');
    });

    test('extracts session_token parameter from web callback', () {
      final token = service.parseOAuthCallback(
        'https://campusfixed.netlify.app/oauth-callback?session_token=session_123',
      );
      expect(token, 'session_123');
    });

    test('returns null when oauth callback has no token or is empty', () {
      expect(service.parseOAuthCallback('campusfix://oauth-callback'), isNull);
      expect(service.parseOAuthCallback(''), isNull);
      expect(service.parseOAuthCallback(null), isNull);
    });
  });
}
