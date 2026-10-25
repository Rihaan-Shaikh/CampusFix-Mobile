import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/startup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/issues/presentation/component_gallery_screen.dart';
import '../../features/issues/presentation/issue_detail_screen.dart';
import '../../features/issues/presentation/issues_screen.dart';
import '../../features/issues/presentation/report_issue_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      notifyListeners();
    });
  }
}

/// Provider exposing the configured GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRouterListenable(ref);
  ref.onDispose(() => authListenable.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;
      final isGoingToAuth = location == '/sign-in' || location == '/sign-up';
      final isReportIssue = location == '/report-issue';

      // If user is authenticated and attempts to visit sign-in / sign-up, redirect home
      if (authState is AuthAuthenticated && isGoingToAuth) {
        return '/';
      }

      // If user is unauthenticated and attempts to submit a report, redirect to sign-in
      if (authState is AuthUnauthenticated && isReportIssue) {
        return '/sign-in';
      }

      return null;
    },
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/startup',
        name: 'startup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'signUp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/report-issue',
        name: 'reportIssue',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportIssueScreen(),
      ),
      GoRoute(
        path: '/issues/:id',
        name: 'issueDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return IssueDetailScreen(issueId: id);
        },
      ),
      if (kDebugMode)
        GoRoute(
          path: '/gallery',
          name: 'gallery',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ComponentGalleryScreen(),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/issues',
                name: 'issues',
                builder: (context, state) => const IssuesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
