import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studentos/features/auth/data/auth_controller.dart';
import 'package:studentos/features/auth/presentation/auth_screen.dart';
import 'package:studentos/features/budget/budget_screen.dart';
import 'package:studentos/features/career/career_screen.dart';
import 'package:studentos/features/details/detail_screen.dart';
import 'package:studentos/features/food/food_screen.dart';
import 'package:studentos/features/home/home_screen.dart';
import 'package:studentos/features/more/more_screen.dart';
import 'package:studentos/features/profile/profile_screens.dart';
import 'package:studentos/features/search/search_screen.dart';
import 'package:studentos/features/services/catalog_service_screens.dart';
import 'package:studentos/features/services/productivity_screens.dart';
import 'package:studentos/features/services/settings_help_screens.dart';
import 'package:studentos/features/services/student_id_screen.dart';
import 'package:studentos/features/shell/student_os_shell.dart';
import 'package:studentos/features/shop/shop_screen.dart';
import 'package:studentos/features/tasks/tasks_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _careerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'career');
final _shopNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _foodNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'food');
final _moreNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'more');

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authenticated = ref.read(authProvider).isAuthenticated;
      final onAuthRoute = state.matchedLocation == '/auth';
      if (!authenticated && !onAuthRoute) return '/auth';
      if (authenticated && onAuthRoute) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => StudentOsShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _careerNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/career',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: CareerScreen(section: state.uri.queryParameters['section']),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shopNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/shop', pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const ShopScreen())),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/home', pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const HomeScreen())),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _foodNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/food', pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const FoodScreen())),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _moreNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/more', pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const MoreScreen())),
            ],
          ),
        ],
      ),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/budget', builder: (context, state) => const BudgetScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/tasks', builder: (context, state) => const TasksScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/student-id', builder: (context, state) => const StudentIdScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/tuition', builder: (context, state) => const TuitionScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/buy-sell', builder: (context, state) => const BuySellScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/marketplace', builder: (context, state) => const MarketplaceScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/events', builder: (context, state) => const EventsScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/notes', builder: (context, state) => const NotesScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/calculator', builder: (context, state) => const CalculatorScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/bookmarks', builder: (context, state) => const BookmarksScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/saved', builder: (context, state) => const SavedItemsScreen()),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => SettingsScreen(focus: state.uri.queryParameters['focus']),
      ),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/help', builder: (context, state) => const HelpCenterScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/privacy', builder: (context, state) => const PrivacyScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/logout', builder: (context, state) => const LogoutScreen()),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/details/:kind/:id',
        builder: (context, state) => DetailScreen(kind: state.pathParameters['kind']!, id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('StudentOS')),
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) => notifyListeners());
  }
}
