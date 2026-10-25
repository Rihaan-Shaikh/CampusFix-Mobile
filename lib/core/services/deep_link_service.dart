/// Service for parsing and validating deep links for CampusFix issues.
class DeepLinkService {
  const DeepLinkService();

  /// Parses an incoming deep link URI string and returns the target app route,
  /// or null if the link is not recognized or invalid.
  ///
  /// Supported formats:
  /// - `campusfix://issue/{issueId}`
  /// - `https://campusfixed.netlify.app/issues/{issueId}`
  /// - `/issues/{issueId}`
  String? parseIssueDeepLink(String? rawUri) {
    if (rawUri == null || rawUri.trim().isEmpty) return null;

    try {
      final uri = Uri.parse(rawUri.trim());

      // 1. Custom scheme: campusfix://issue/<id>
      if (uri.scheme == 'campusfix') {
        if (uri.host == 'issue' || uri.pathSegments.contains('issue')) {
          final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
          if (_isValidIssueId(id)) {
            return '/issues/$id';
          }
        }
      }

      // 2. HTTP/HTTPS Web URL: https://campusfixed.netlify.app/issues/<id>
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        if (uri.host.contains('campusfixed.netlify.app') ||
            uri.host == 'localhost') {
          final index = uri.pathSegments.indexOf('issues');
          if (index != -1 && index + 1 < uri.pathSegments.length) {
            final id = uri.pathSegments[index + 1];
            if (_isValidIssueId(id)) {
              return '/issues/$id';
            }
          }
        }
      }

      // 3. Relative route: /issues/<id>
      if (rawUri.startsWith('/issues/')) {
        final id = rawUri.replaceFirst('/issues/', '').split('?').first;
        if (_isValidIssueId(id)) {
          return '/issues/$id';
        }
      }
    } catch (_) {
      // Malformed URI handled gracefully without crashes
    }

    return null;
  }

  /// Extracts issue ID from a given URI, or returns null if not an issue link.
  String? extractIssueId(Uri uri) {
    final route = parseIssueDeepLink(uri.toString());
    if (route != null && route.startsWith('/issues/')) {
      return route.replaceFirst('/issues/', '');
    }
    return null;
  }

  /// Parses an incoming OAuth callback deep link URI string and extracts the session token,
  /// or null if the link does not contain a valid token.
  ///
  /// Supported formats:
  /// - `campusfix://oauth-callback?token={token}`
  /// - `https://campusfixed.netlify.app/oauth-callback?token={token}`
  String? parseOAuthCallback(String? rawUri) {
    if (rawUri == null || rawUri.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(rawUri.trim());
      if ((uri.scheme == 'campusfix' && uri.host == 'oauth-callback') ||
          (uri.pathSegments.contains('oauth-callback'))) {
        return uri.queryParameters['token'] ??
            uri.queryParameters['session_token'];
      }
    } catch (_) {}
    return null;
  }

  /// Resolves target route from URI, falling back to '/issues' if unrecognized.
  String resolveRoute(Uri uri) {
    return parseIssueDeepLink(uri.toString()) ?? '/issues';
  }

  bool _isValidIssueId(String? id) {
    if (id == null || id.trim().isEmpty) return false;
    final cleanId = id.trim();
    // Valid IDs: alphanumeric with optional hyphens/underscores, 3 to 100 chars
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-]{3,100}$');
    return validPattern.hasMatch(cleanId);
  }
}
